#!/usr/bin/env python3
"""Convert MLIR transfer-dialect functions to stitch lambda calculus.

Usage:
    python mlir_to_lam.py file.mlir [file2.mlir ...]
    python mlir_to_lam.py file.mlir -o out.lam

Each function in the input is emitted as one lambda expression on its own line.
Variables are encoded as de Bruijn indices ($0 = innermost binding).
SSA let-bindings are encoded as ((lam body) expr).
"""

import re
import sys
from pathlib import Path


# ── Primitives ────────────────────────────────────────────────────────────────

def _first_int(attr_str: str) -> int | None:
    """Return the first integer value found in an attribute dict string."""
    m = re.search(r'=\s*(-?\d+)', attr_str)
    return int(m.group(1)) if m else None


def op_primitive(op_name: str, attr_str: str) -> str:
    """Build a stitch primitive name from an MLIR op name + attribute string.

    Ops with a single integer attribute (index/value/predicate) have that
    value appended: e.g. "transfer.get" {index=0} -> transfer.get_0.
    """
    val = _first_int(attr_str)
    if val is not None:
        return f'{op_name}_{val}'
    return op_name


# ── Lambda calculus builder ───────────────────────────────────────────────────

def build_lambda(
    args: list[str],
    assignments: list[tuple[str, str, list[str]]],
    ret_var: str,
) -> str:
    """Translate an SSA function into stitch lambda calculus.

    Args:
        args: function argument names in declaration order [a0, a1, ..., aN-1].
        assignments: list of (result_var, primitive, [operand_vars...]).
        ret_var: the SSA variable that is returned.

    Returns:
        A string like (lam (lam ((lam $0) (transfer.add $1 $0)))).

    Encoding:
        * Function args become the outermost lambdas (a0 = outermost, aN-1 = innermost).
        * Each SSA assignment ``v = f(x, y)`` becomes a let-binding encoded as
          ``((lam <rest>) (f $i $j))``, which binds v as $0 in <rest>.
        * de Bruijn index $i refers to the variable bound by the i-th lambda
          counting inward from the current position.
    """
    # scope[i] = variable name at de Bruijn index $i.
    # After binding all args: the last arg is innermost ($0), first arg is outermost.
    scope: list[str] = list(reversed(args))

    # Record the scope snapshot at the time each expression is evaluated.
    steps: list[tuple[list[str], str, list[str]]] = []
    for result_var, prim, operands in assignments:
        steps.append((list(scope), prim, list(operands)))
        scope = [result_var] + scope  # result is now $0; everything shifts up

    final_scope = scope

    if ret_var not in final_scope:
        raise ValueError(
            f'return variable {ret_var!r} not in scope {final_scope!r}'
        )

    # Build the expression inside-out.
    # Innermost body: a reference to the returned variable.
    body = f'${final_scope.index(ret_var)}'

    # Wrap with let-bindings from last assignment to first.
    for i in range(len(steps) - 1, -1, -1):
        scope_at_i, prim, operands = steps[i]
        op_strs: list[str] = []
        for op in operands:
            if op not in scope_at_i:
                raise ValueError(
                    f'operand {op!r} not in scope at step {i}: {scope_at_i!r}'
                )
            op_strs.append(f'${scope_at_i.index(op)}')

        expr = f'({prim} {" ".join(op_strs)})' if op_strs else prim
        body = f'((lam {body}) {expr})'

    # Wrap with one lambda per function argument (outermost = first arg).
    for _ in args:
        body = f'(lam {body})'

    return body


# ── MLIR line-level parsers ───────────────────────────────────────────────────

def _operand_names(operand_str: str) -> list[str]:
    """Extract bare variable names from '%a, %b, %c' style strings."""
    return re.findall(r'%(\w+)', operand_str)


# Pattern for the generic MLIR assignment form:
#   %result = "dialect.op"(%a, %b) {attrs} : (types) -> type
_GENERIC_ASSIGN = re.compile(
    r'^\s*%(\w+)\s*=\s*"([^"]+)"\s*\(([^)]*)\)\s*(\{[^}]*\})?\s*:'
)

# Pattern for a plain arith assignment:
#   %result = arith.andi %a, %b : i1
_STD_ASSIGN = re.compile(
    r'^\s*%(\w+)\s*=\s*([\w.]+)\s+((?:%[\w]+\s*,\s*)*%[\w]+)\s*:'
)

# Generic return: "func.return"(%v) : ...
_GENERIC_RETURN = re.compile(r'^\s*"func\.return"\s*\(([^)]*)\)\s*:')

# Standard return: func.return %v : type  OR  return %v : type
_STD_RETURN = re.compile(r'^\s*(?:func\.)?return\s+%(\w+)')


def _parse_body_lines(
    lines: list[str],
) -> tuple[list[tuple[str, str, list[str]]], str | None]:
    """Parse SSA body lines into (assignments, ret_var)."""
    assignments: list[tuple[str, str, list[str]]] = []
    ret_var: str | None = None

    for raw in lines:
        line = raw.strip()
        if not line:
            continue

        # Generic return (checked before generic assign to avoid mis-match).
        m = _GENERIC_RETURN.match(line)
        if m:
            names = _operand_names(m.group(1))
            if names:
                ret_var = names[0]
            continue

        # Standard return.
        m = _STD_RETURN.match(line)
        if m:
            ret_var = m.group(1)
            continue

        # Generic assignment.
        m = _GENERIC_ASSIGN.match(line)
        if m:
            result = m.group(1)
            op = m.group(2)
            operands = _operand_names(m.group(3))
            attrs = m.group(4) or ''
            prim = op_primitive(op, attrs)
            assignments.append((result, prim, operands))
            continue

        # func.call @funcname(%a, %b) : ...
        m = re.match(r'^\s*%(\w+)\s*=\s*func\.call\s+@(\w+)\s*\(([^)]*)\)', line)
        if m:
            result = m.group(1)
            op = m.group(2)  # use the callee name as the primitive
            operands = _operand_names(m.group(3))
            assignments.append((result, op, operands))
            continue

        # Plain arith/dialect assignment without quotes.
        m = _STD_ASSIGN.match(line)
        if m:
            result = m.group(1)
            op = m.group(2)
            operands = _operand_names(m.group(3))
            assignments.append((result, op, operands))
            continue

    return assignments, ret_var


# ── Top-level file parsers ────────────────────────────────────────────────────

# A function record: (args, assignments, ret_var)
_FuncRecord = tuple[list[str], list[tuple[str, str, list[str]]], str]


def _parse_generic_file(text: str) -> list[_FuncRecord]:
    """Parse a file using the MLIR generic format ("func.func"() ({...}))."""
    # The block header looks like: ^0(%a : type, %b : type):
    m = re.search(
        r'\^0\(([^)]*)\)\s*:\s*\n(.*?)(?=\s*\}\))',
        text,
        re.DOTALL,
    )
    if not m:
        return []

    args = _operand_names(m.group(1))
    assignments, ret_var = _parse_body_lines(m.group(2).splitlines())

    if ret_var is None:
        return []
    return [(args, assignments, ret_var)]


# Matches the function signature up to and including the closing ')' of args.
_FUNC_SIG = re.compile(r'func\.func\s+@\w+\s*\(([^)]*)\)')


def _skip_brace_block(text: str, open_pos: int) -> int:
    """Given position of '{', return position just past the matching '}'."""
    depth = 1
    i = open_pos + 1
    while i < len(text) and depth > 0:
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
        i += 1
    return i


def _parse_standard_file(text: str) -> list[_FuncRecord]:
    """Parse a file that uses standard func.func syntax (possibly in a module)."""
    results: list[_FuncRecord] = []
    pos = 0

    while True:
        fm = _FUNC_SIG.search(text, pos)
        if not fm:
            break

        args = _operand_names(fm.group(1))

        # Scan past the return type annotation (and optional 'attributes {...}')
        # to find the function body opening '{'.
        i = fm.end()
        while i < len(text) and text[i] != '{':
            i += 1
        if i >= len(text):
            pos = fm.end() + 1
            continue

        # If 'attributes' appeared between the signature and this '{', the brace
        # we found is the attributes dict — skip it and find the body '{' next.
        pre = text[fm.end(): i]
        if 'attributes' in pre:
            i = _skip_brace_block(text, i)
            while i < len(text) and text[i] != '{':
                i += 1
            if i >= len(text):
                pos = fm.end() + 1
                continue

        # text[i] is now the opening '{' of the function body.
        body_end = _skip_brace_block(text, i)
        body_text = text[i + 1: body_end - 1]
        assignments, ret_var = _parse_body_lines(body_text.splitlines())

        if ret_var is not None:
            results.append((args, assignments, ret_var))

        pos = body_end

    return results


# ── Public API ────────────────────────────────────────────────────────────────

def mlir_to_lam(text: str) -> list[str]:
    """Convert an MLIR string and return a list of lambda calculus strings"""
    if '"func.func"' in text:
        funcs = _parse_generic_file(text)
    else:
        funcs = _parse_standard_file(text)

    expressions: list[str] = []
    for args, assignments, ret_var in funcs:
        try:
            expressions.append(build_lambda(args, assignments, ret_var))
        except ValueError as exc:
            print(f'Warning [{path.name}]: {exc}', file=sys.stderr)

    return expressions

def mlir_file_to_lam(path: Path) -> list[str]:
    """Parse an MLIR file and return a list of lambda calculus strings."""
    text = path.read_text()
    return mlir_to_lam(text)

# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <file.mlir> [file2.mlir ...] [-o out.lam]',
              file=sys.stderr)
        sys.exit(1)

    args = sys.argv[1:]
    out_path: Path | None = None

    # Simple -o flag handling.
    if '-o' in args:
        idx = args.index('-o')
        out_path = Path(args[idx + 1])
        args = args[:idx] + args[idx + 2:]

    lines: list[str] = []
    for path_str in args:
        path = Path(path_str)
        lines.extend(mlir_file_to_lam(path))

    output = '\n'.join(lines)
    if output:
        output += '\n'

    if out_path is not None:
        out_path.write_text(output)
    else:
        sys.stdout.write(output)


if __name__ == '__main__':
    main()
