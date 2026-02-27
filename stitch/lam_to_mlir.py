#!/usr/bin/env python3
"""Convert stitch lambda calculus (.lam) back to MLIR.

Usage:
    python lam_to_mlir.py file.lam [file2.lam ...]
    python lam_to_mlir.py file.lam -o out.mlir

Each line of the input is treated as one lambda expression and is emitted as
one func.func definition.  A single-function file is emitted bare; a
multi-function file is wrapped in a builtin.module { ... } block.

Encoding conventions (must match mlir_to_lam.py):
  * Outer lambdas  →  function arguments (%arg0, %arg1, …)
  * ((lam body) expr)  →  SSA let-binding; introduces a fresh %vN variable
  * (prim $i $j …)  →  primitive application with de Bruijn variable references
  * Attribute suffix: transfer.get_0 → "transfer.get"(...) {index = 0}
                      transfer.cmp_6 → "transfer.cmp"(...) {predicate = 6 : i64}
                      transfer.constant_1 → "transfer.constant"(...) {value = 1 : index}
                      arith.constant_1   → "arith.constant"() {value = 1 : i1}
"""

import re
import sys
from pathlib import Path


# ── MLIR types ────────────────────────────────────────────────────────────────

INT  = "!transfer.integer"
ABS  = "!transfer.abs_value<[!transfer.integer, !transfer.integer]>"
BOOL = "i1"


# ── Attribute suffix → MLIR attribute dict ────────────────────────────────────

# Maps the base op name to (attribute_name, optional_type_qualifier).
_ATTR_MAP: dict[str, tuple[str, str | None]] = {
    "transfer.get":      ("index",     None),
    "transfer.constant": ("value",     "index"),
    "transfer.cmp":      ("predicate", "i64"),
    "arith.constant":    ("value",     "i1"),
}


def _decode_op(encoded: str) -> tuple[str, str]:
    """Split an encoded primitive into (mlir_op_name, attr_dict_string).

    Examples:
        'transfer.get_0'  -> ('transfer.get',  '{index = 0}')
        'transfer.cmp_6'  -> ('transfer.cmp',  '{predicate = 6 : i64}')
        'transfer.add'    -> ('transfer.add',  '')
        'arith.constant_1'-> ('arith.constant','{value = 1 : i1}')
    """
    m = re.match(r'^(.+?)_(-?\d+)$', encoded)
    if m:
        base, val = m.group(1), m.group(2)
        if base in _ATTR_MAP:
            attr_name, attr_ty = _ATTR_MAP[base]
            if attr_ty:
                return base, f'{{{attr_name} = {val} : {attr_ty}}}'
            else:
                return base, f'{{{attr_name} = {val}}}'
    return encoded, ''


# ── Type inference ────────────────────────────────────────────────────────────

def _result_type(op: str, operand_types: list[str]) -> str:
    """Infer the MLIR result type of a decoded op."""
    # Boolean-valued results
    if op.startswith('transfer.cmp_'):
        return BOOL
    if op in {'arith.andi', 'arith.ori', 'arith.xori'}:
        return BOOL
    overflow_prefixes = (
        'transfer.sadd_overflow', 'transfer.ssub_overflow',
        'transfer.smul_overflow', 'transfer.uadd_overflow',
        'transfer.usub_overflow', 'transfer.umul_overflow',
        'transfer.sshl_overflow', 'transfer.ushl_overflow',
    )
    if any(op.startswith(p) for p in overflow_prefixes):
        return BOOL

    # Abstract-value results
    if op == 'transfer.make':
        return ABS

    # Select: result type mirrors the value operands (positions 1 and 2)
    if op == 'transfer.select' and len(operand_types) >= 2:
        return operand_types[1]

    # Default: integer bit-vector
    return INT


def _expected_arg_type(op: str, arg_idx: int) -> str | None:
    """What type does op expect at operand position arg_idx?  None = unknown."""
    # transfer.get_N (digit suffix) extracts from an abstract value
    if re.match(r'^transfer\.get_\d+$', op):
        return ABS
    if op == 'transfer.make':
        return INT
    if op in {'arith.andi', 'arith.ori', 'arith.xori'}:
        return BOOL
    if op == 'transfer.select' and arg_idx == 0:
        return BOOL
    if op.startswith('transfer.') or op.startswith('arith.'):
        return INT
    return None  # function calls and unknown primitives


# ── AST ───────────────────────────────────────────────────────────────────────

class _Lam:
    __slots__ = ('body',)
    def __init__(self, body): self.body = body

class _App:
    __slots__ = ('func', 'arg')
    def __init__(self, func, arg): self.func = func; self.arg = arg

class _Var:
    __slots__ = ('index',)
    def __init__(self, index): self.index = index

class _Prim:
    __slots__ = ('name',)
    def __init__(self, name): self.name = name


# ── Parser ────────────────────────────────────────────────────────────────────

def _tokenize(s: str) -> list[str]:
    return re.findall(r'\(|\)|\$\d+|[^\s()]+', s)


def _as_expr(item):
    """Convert a raw stack item (str keyword or AST node) to an AST node."""
    return _Prim(item) if isinstance(item, str) else item


def parse_lam(s: str):
    """Parse a stitch lambda calculus expression iteratively (no recursion limit)."""
    tokens = _tokenize(s.strip())
    if not tokens:
        raise ValueError("Empty expression")

    # stack: list of in-progress groups, each group is a list of items
    # (strings for unresolved keywords/primitives, or AST nodes).
    stack: list[list] = []
    result = None

    for tok in tokens:
        if tok == '(':
            stack.append([])

        elif tok == ')':
            if not stack:
                raise ValueError("Unexpected ')'")
            group = stack.pop()
            if not group:
                raise ValueError("Empty group '()'")

            first = group[0]
            rest  = group[1:]

            if first in ('lam', 'lambda'):
                if len(rest) != 1:
                    raise ValueError(f"lam expects 1 body, got {len(rest)}")
                expr = _Lam(_as_expr(rest[0]))
            elif first == 'app':
                if len(rest) != 2:
                    raise ValueError(f"app expects 2 args, got {len(rest)}")
                expr = _App(_as_expr(rest[0]), _as_expr(rest[1]))
            else:
                # (f a b …) — left-associative curried application
                expr = _as_expr(first)
                for item in rest:
                    expr = _App(expr, _as_expr(item))

            if stack:
                stack[-1].append(expr)
            else:
                result = expr

        elif tok.startswith('$'):
            var = _Var(int(tok[1:]))
            if stack:
                stack[-1].append(var)
            else:
                result = var

        else:
            # Primitive name — keep as str so 'lam'/'app' are recognized later
            if stack:
                stack[-1].append(tok)
            else:
                result = _Prim(tok)

    if stack:
        raise ValueError(f"Unclosed '(': {len(stack)} groups still open")
    if result is None:
        raise ValueError("No expression found")
    return result


# ── SSA decoding ──────────────────────────────────────────────────────────────

def _collect_app(expr) -> tuple:
    """Flatten a left-associative App chain into (head, [arg1, arg2, …])."""
    args: list = []
    while isinstance(expr, _App):
        args.insert(0, expr.arg)
        expr = expr.func
    return expr, args


def _extract_op(expr, scope: list[str],
                assignments: list | None = None,
                counter: list[int] | None = None,
                free_vars: dict[str, str] | None = None) -> tuple[str, list[str]]:
    """Extract (op_name, [operand_var_names]) from a primitive application.

    When *assignments* and *counter* are supplied, non-trivial (_App) sub-
    expressions are recursively flattened into intermediate SSA bindings so
    they can be used as simple variable operands.
    """
    head, args = _collect_app(expr)

    if isinstance(head, _Prim):
        raw = head.name
        op_name = (free_vars or {}).get(raw, raw)
    elif isinstance(head, _Var):
        op_name = scope[head.index]
    else:
        raise ValueError(f"Cannot extract op from {type(head).__name__}")

    operands: list[str] = []
    for a in args:
        if isinstance(a, _Var):
            operands.append(scope[a.index])
        elif isinstance(a, _Prim):
            raw = a.name
            operands.append((free_vars or {}).get(raw, raw))
        elif isinstance(a, _App) and assignments is not None and counter is not None:
            # Non-trivial sub-expression: flatten into an intermediate binding.
            rv = f'%v{counter[0]}'
            counter[0] += 1
            sub_op, sub_ops = _extract_op(a, scope, assignments, counter, free_vars)
            assignments.append((rv, sub_op, sub_ops))
            operands.append(rv)
        else:
            raise ValueError(f"Non-trivial operand: {type(a).__name__}")

    return op_name, operands


def decode_function(lam_expr,
                    free_vars: dict[str, str] | None = None,
                    ) -> tuple[list[str], list[tuple], str]:
    """Decode a full lambda expression into SSA components.

    Args:
        lam_expr  – parsed AST
        free_vars – mapping of Stitch free-variable names to MLIR names,
                    e.g. {'#0': '%h0', '#1': '%h1'}.  These are added as
                    leading function arguments in the output.

    Returns:
        arg_names   – ['%h0', ..., '%arg0', '%arg1', ...]  (free vars first)
        assignments – [('%vN', 'mlir.op', ['%x', '%y', ...]), ...]
        ret_var     – variable name returned by the function
    """
    # Peel outer Lam nodes → function arguments.
    lam_arg_names: list[str] = []
    body = lam_expr
    while isinstance(body, _Lam):
        lam_arg_names.append(f'%arg{len(lam_arg_names)}')
        body = body.body

    # Free-var names precede lambda args in the final signature.
    fv_names: list[str] = list((free_vars or {}).values())
    arg_names = fv_names + lam_arg_names

    # After peeling n args, the innermost lambda bound arg[n-1] as $0.
    scope: list[str] = list(reversed(lam_arg_names))
    assignments: list[tuple] = []
    counter = [0]  # mutable so _extract_op sub-calls can share it

    # Iterative decoding: walk the let-binding chain without recursion.
    # Each step is: body = App(Lam(inner), val_expr)  →  process val_expr,
    # bind result, continue with inner.
    expr = body
    while True:
        if isinstance(expr, _Var):
            ret_var = scope[expr.index]
            break

        if isinstance(expr, _App) and isinstance(expr.func, _Lam):
            # Let-binding: ((lam inner) val_expr)
            rv = f'%v{counter[0]}'
            counter[0] += 1
            op, ops = _extract_op(expr.arg, scope, assignments, counter, free_vars)
            assignments.append((rv, op, ops))
            scope = [rv] + scope
            expr = expr.func.body  # continue with inner body
            continue

        # Non-let application or bare primitive at the innermost position:
        # emit one final assignment and use that as the return value.
        rv = f'%v{counter[0]}'
        counter[0] += 1
        op, ops = _extract_op(expr, scope, assignments, counter, free_vars)
        assignments.append((rv, op, ops))
        ret_var = rv
        break

    return arg_names, assignments, ret_var


# ── MLIR generation ───────────────────────────────────────────────────────────

def function_to_mlir(func_name: str,
                     arg_names: list[str],
                     assignments: list[tuple],
                     ret_var: str) -> str:
    """Generate a func.func MLIR definition."""

    type_env: dict[str, str] = {}

    # ── Infer argument types from their first usage ──────────────────────────
    arg_set = set(arg_names)
    for _rv, op, operand_vars in assignments:
        for idx, var in enumerate(operand_vars):
            if var in arg_set and var not in type_env:
                exp = _expected_arg_type(op, idx)
                if exp is not None:
                    type_env[var] = exp

    # Default unresolved args to ABS (most common case in this corpus).
    for a in arg_names:
        type_env.setdefault(a, ABS)

    # ── Forward-propagate result types; emit MLIR lines ──────────────────────
    body_lines: list[str] = []

    for result_var, op_name, operand_vars in assignments:
        op_types = [type_env.get(v, INT) for v in operand_vars]
        res_ty = _result_type(op_name, op_types)
        type_env[result_var] = res_ty

        mlir_op, attr_str = _decode_op(op_name)
        ops_str   = ', '.join(operand_vars)
        types_str = ', '.join(op_types)

        # Ops with a '.' in their name are dialect ops → quoted generic form.
        # Names without '.' came from func.call → emit as func.call.
        if '.' in mlir_op:
            op_expr = f'"{mlir_op}"({ops_str})'
        else:
            op_expr = f'func.call @{mlir_op}({ops_str})'

        if attr_str:
            line = f'  {result_var} = {op_expr} {attr_str} : ({types_str}) -> {res_ty}'
        else:
            line = f'  {result_var} = {op_expr} : ({types_str}) -> {res_ty}'

        body_lines.append(line)

    ret_ty = type_env.get(ret_var, ABS)
    body_lines.append(f'  func.return {ret_var} : {ret_ty}')

    # ── Function header ───────────────────────────────────────────────────────
    arg_sig = ', '.join(f'{a} : {type_env[a]}' for a in arg_names)

    return '\n'.join([
        f'func.func @{func_name}({arg_sig}) -> {ret_ty} {{',
        *body_lines,
        '}',
    ])


# ── Stitch abstraction header ─────────────────────────────────────────────────

def _parse_stitch_header(line: str) -> tuple[dict[str, str], str]:
    """Parse a Stitch abstraction header, if present.

    'fn_0(#0,#1,#2) := body'  →  ({'#0':'%h0','#1':'%h1','#2':'%h2'}, 'body')
    Any other line             →  ({}, line)
    """
    m = re.match(r'^fn_\d+\(([^)]*)\)\s*:=\s*(.+)$', line, re.DOTALL)
    if not m:
        return {}, line
    params = [p.strip() for p in m.group(1).split(',') if p.strip()]
    free_vars = {p: f'%h{p[1:]}' for p in params}   # '#0' → '%h0'
    return free_vars, m.group(2).strip()


# ── Beta reduction / fn-N inlining ───────────────────────────────────────────

def _shift(expr, amount: int, cutoff: int = 0):
    """Increase all free de Bruijn indices >= cutoff by amount."""
    if isinstance(expr, _Var):
        return _Var(expr.index + amount) if expr.index >= cutoff else expr
    if isinstance(expr, _Lam):
        return _Lam(_shift(expr.body, amount, cutoff + 1))
    if isinstance(expr, _App):
        return _App(_shift(expr.func, amount, cutoff),
                    _shift(expr.arg,  amount, cutoff))
    return expr  # _Prim — no de Bruijn vars


def _subst_db(body, val, depth: int = 0):
    """Beta step: replace _Var(depth) with val inside body, removing that binder."""
    if isinstance(body, _Var):
        if body.index == depth:
            return _shift(val, depth)
        if body.index > depth:
            return _Var(body.index - 1)
        return body
    if isinstance(body, _Lam):
        return _Lam(_subst_db(body.body, val, depth + 1))
    if isinstance(body, _App):
        return _App(_subst_db(body.func, val, depth),
                    _subst_db(body.arg,  val, depth))
    return body  # _Prim


def _beta_step(expr):
    """One structural pass of beta-reduction; returns (new_expr, did_reduce)."""
    if isinstance(expr, _App):
        if isinstance(expr.func, _Lam):
            return _subst_db(expr.func.body, expr.arg), True
        f2, cf = _beta_step(expr.func)
        a2, ca = _beta_step(expr.arg)
        return _App(f2, a2), cf or ca
    if isinstance(expr, _Lam):
        b2, cb = _beta_step(expr.body)
        return _Lam(b2), cb
    return expr, False


def _beta_reduce(expr):
    """Fully beta-reduce expr (iterate until no redexes remain)."""
    changed = True
    while changed:
        expr, changed = _beta_step(expr)
    return expr


def _subst_prims(expr, mapping: dict, depth: int = 0):
    """Replace _Prim nodes by name from mapping, shifting free de Bruijn vars by depth.

    depth tracks how many binders we are currently under inside the target
    expression, so that variables free in the substituted value are lifted by
    the same amount before being placed under those binders.
    """
    if isinstance(expr, _Prim):
        if expr.name in mapping:
            return _shift(mapping[expr.name], depth)
        return expr
    if isinstance(expr, _Var):
        return expr
    if isinstance(expr, _Lam):
        return _Lam(_subst_prims(expr.body, mapping, depth + 1))
    if isinstance(expr, _App):
        return _App(_subst_prims(expr.func, mapping, depth),
                    _subst_prims(expr.arg,  mapping, depth))
    return expr


def _inline_step(expr, fn_defs: dict):
    """Single inlining pass; returns (new_expr, did_change)."""
    if isinstance(expr, _Lam):
        b2, c = _inline_step(expr.body, fn_defs)
        return _Lam(b2), c
    if isinstance(expr, _App):
        f2, cf = _inline_step(expr.func, fn_defs)
        a2, ca = _inline_step(expr.arg, fn_defs)
        app = _App(f2, a2)
        # Check whether this is a fully-applied fn_N call.
        head, args = _collect_app(app)
        if isinstance(head, _Prim) and head.name in fn_defs:
            fv_names, body = fn_defs[head.name]
            if len(args) >= len(fv_names):
                mapping = dict(zip(fv_names, args[:len(fv_names)]))
                inlined = _subst_prims(body, mapping)
                for arg in args[len(fv_names):]:
                    inlined = _App(inlined, arg)
                return _beta_reduce(inlined), True
        # Opportunistic beta-reduction at this node.
        if isinstance(f2, _Lam):
            return _subst_db(f2.body, a2), True
        return app, cf or ca
    return expr, False


def _inline_fn_calls(expr, fn_defs: dict):
    """Iteratively inline stitch fn_N calls and beta-reduce until stable."""
    changed = True
    while changed:
        expr, changed = _inline_step(expr, fn_defs)
    return expr


# ── File processing ───────────────────────────────────────────────────────────

def lamstr_to_mlir(text: str) -> str:
    lam_lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    if not lam_lines:
        return ''

    # First pass: collect fn_N definitions so we can inline them later.
    fn_defs: dict[str, tuple[list[str], object]] = {}
    for line in lam_lines:
        m = re.match(r'^(fn_\d+)\(([^)]*)\)\s*:=\s*(.+)$', line, re.DOTALL)
        if m:
            params = [p.strip() for p in m.group(2).split(',') if p.strip()]
            try:
                fn_defs[m.group(1)] = (params, parse_lam(m.group(3).strip()))
            except Exception:
                pass

    funcs: list[str] = []
    for i, line in enumerate(lam_lines):
        func_name = f'func{i}'
        try:
            free_vars, body_str = _parse_stitch_header(line)
            expr = parse_lam(body_str)
            if fn_defs:
                expr = _inline_fn_calls(expr, fn_defs)
            arg_names, assignments, ret_var = decode_function(expr, free_vars or None)
            funcs.append(function_to_mlir(func_name, arg_names, assignments, ret_var))
        except Exception as exc:
            print(f'Warning [{func_name}:{i + 1}]: {exc}', file=sys.stderr)

    if not funcs:
        return ''

    if len(funcs) == 1:
        return funcs[0] + '\n'
    else:
        # Multiple functions: wrap in a module.
        indented = '\n'.join(
            '\n'.join(f'  {ln}' for ln in fn.splitlines())
            for fn in funcs
        )
        return f'builtin.module {{\n{indented}\n}}\n'

def lam_file_to_mlir(path: Path) -> str:
    """Convert a .lam file to MLIR text."""
    return lamstr_to_mlir(path.read_text())

# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <file.lam> [file2.lam ...] [-o out.mlir]',
              file=sys.stderr)
        sys.exit(1)

    args = sys.argv[1:]
    out_path: Path | None = None

    if '-o' in args:
        idx = args.index('-o')
        out_path = Path(args[idx + 1])
        args = args[:idx] + args[idx + 2:]

    output = ''.join(lam_file_to_mlir(Path(p)) for p in args)

    if out_path is not None:
        out_path.write_text(output)
    else:
        sys.stdout.write(output)


if __name__ == '__main__':
    main()
