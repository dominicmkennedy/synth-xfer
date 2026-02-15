from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser, Namespace
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer._util.point_eval import eval_transfer_point, get_transfer_shape
from synth_xfer.cli.eval_final import resolve_xfer_name

_DOMAIN_PREFIX: dict[AbstractDomain, str] = {
    AbstractDomain.KnownBits: "kb",
    AbstractDomain.UConstRange: "ucr",
    AbstractDomain.SConstRange: "scr",
}
_XFER_PREFIX_DOMAIN: dict[str, AbstractDomain] = {
    "kb_": AbstractDomain.KnownBits,
    "ucr_": AbstractDomain.UConstRange,
    "scr_": AbstractDomain.SConstRange,
    "mod3_": AbstractDomain.Mod3,
    "mod5_": AbstractDomain.Mod5,
    "mod7_": AbstractDomain.Mod7,
    "mod11_": AbstractDomain.Mod11,
    "mod13_": AbstractDomain.Mod13,
}


def _register_parser() -> Namespace:
    p = ArgumentParser(
        prog="eval-point",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("--bw", type=int, required=True, help="Bitwidth")
    p.add_argument(
        "--xfer-file",
        type=Path,
        help="Path to transfer file (if omitted, inferred from --domain/--op)",
    )
    p.add_argument("--xfer-name", type=str, help="Transfer function name override")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract domain (required when --xfer-file is omitted)",
    )
    p.add_argument(
        "--op",
        type=str,
        help="Operation stem or path (used to infer tests/data/<prefix>_<op>.mlir)",
    )
    p.add_argument(
        "--arg",
        action="append",
        default=[],
        help=(
            "One abstract input argument as comma-separated lanes, "
            "e.g. --arg 0x21524110,0xdeadbeef --arg 0xffffffef,16"
        ),
    )
    p.add_argument(
        "--concrete-arg",
        action="append",
        default=[],
        help=(
            "One concrete input argument (repeat per op-arg), auto-encoded to domain, "
            "e.g. --concrete-arg 0xdeadbeef --concrete-arg 16"
        ),
    )
    p.add_argument(
        "--concrete-lhs",
        type=str,
        help="Convenience alias for first concrete argument",
    )
    p.add_argument(
        "--concrete-rhs",
        type=str,
        help="Convenience alias for second concrete argument",
    )
    return p.parse_args()


def _parse_lane_vals(text: str) -> tuple[int, ...]:
    vals = [x.strip() for x in text.split(",")]
    if any(v == "" for v in vals):
        raise ValueError(f"Malformed --arg value: {text!r}")
    return tuple(int(v, 0) for v in vals)


def _parse_concrete_aliases(args: Namespace) -> tuple[int, ...]:
    if args.concrete_rhs is not None and args.concrete_lhs is None:
        raise ValueError("--concrete-rhs requires --concrete-lhs")

    alias_vals: list[str] = []
    if args.concrete_lhs is not None:
        alias_vals.append(args.concrete_lhs)
    if args.concrete_rhs is not None:
        alias_vals.append(args.concrete_rhs)

    if args.concrete_arg and alias_vals:
        raise ValueError(
            "Do not mix --concrete-arg with --concrete-lhs/--concrete-rhs; use one style"
        )

    raw_vals = args.concrete_arg if args.concrete_arg else alias_vals
    return tuple(int(x, 0) for x in raw_vals)


def _infer_xfer_file(domain: AbstractDomain, op: str) -> Path:
    if domain not in _DOMAIN_PREFIX:
        raise ValueError(
            f"Auto xfer-file inference is unsupported for domain {domain}; "
            "pass --xfer-file explicitly"
        )

    op_stem = Path(op).stem.lower()
    repo_root = Path(__file__).resolve().parents[2]
    fp = repo_root / "tests" / "data" / f"{_DOMAIN_PREFIX[domain]}_{op_stem}.mlir"
    if not fp.is_file():
        raise FileNotFoundError(f"Inferred transfer file not found: {fp}")

    return fp


def _infer_domain_from_xfer_file(xfer_file: Path) -> AbstractDomain | None:
    stem = xfer_file.stem.lower()
    for prefix, domain in _XFER_PREFIX_DOMAIN.items():
        if stem.startswith(prefix):
            return domain
    return None


def _mask(v: int, bits: int) -> int:
    return v & ((1 << bits) - 1)


def _encode_concrete_arg(
    domain: AbstractDomain, concrete: int, lane_bits: tuple[int, ...]
) -> tuple[int, ...]:
    if domain == AbstractDomain.KnownBits:
        if len(lane_bits) != 2:
            raise ValueError(
                f"KnownBits expects 2 lanes, but transfer arg has {len(lane_bits)}"
            )
        c0 = _mask(concrete, lane_bits[0])
        c1 = _mask(concrete, lane_bits[1])
        return (_mask(~c0, lane_bits[0]), c1)

    if domain in {AbstractDomain.UConstRange, AbstractDomain.SConstRange}:
        if len(lane_bits) != 2:
            raise ValueError(
                f"{domain} expects 2 lanes, but transfer arg has {len(lane_bits)}"
            )
        c0 = _mask(concrete, lane_bits[0])
        c1 = _mask(concrete, lane_bits[1])
        return (c0, c1)

    if domain.const_bw is not None and len(lane_bits) == 1:
        residue = concrete % domain.const_bw
        return (_mask(1 << residue, lane_bits[0]),)

    raise ValueError(
        f"Unsupported concrete encoding for domain {domain}; pass abstract lanes via --arg"
    )


def _resolve_input_args(
    args: Namespace,
    domain: AbstractDomain | None,
    lane_shape: tuple[tuple[int, ...], ...],
) -> tuple[tuple[int, ...], ...]:
    abst_args = tuple(_parse_lane_vals(x) for x in args.arg)
    conc_args = _parse_concrete_aliases(args)

    if abst_args and conc_args:
        raise ValueError("Do not mix --arg with --concrete-* inputs")
    if not abst_args and not conc_args:
        raise ValueError("Pass inputs via --arg or --concrete-*")

    if abst_args:
        return abst_args

    if domain is None:
        raise ValueError(
            "Concrete inputs require a domain; pass --domain or use a known xfer filename prefix"
        )
    if len(conc_args) != len(lane_shape):
        raise ValueError(f"Expected {len(lane_shape)} concrete args, got {len(conc_args)}")

    return tuple(
        _encode_concrete_arg(domain, v, bits)
        for v, bits in zip(conc_args, lane_shape, strict=True)
    )


def _format_lane_hex(vals: tuple[int, ...], bits: tuple[int, ...]) -> str:
    return ", ".join(
        f"0x{(v & ((1 << b) - 1)):0{(b + 3) // 4}x}"
        for v, b in zip(vals, bits, strict=True)
    )


def _print_domain_friendly(
    domain: AbstractDomain | None, bw: int, vals: tuple[int, ...]
) -> None:
    if domain == AbstractDomain.KnownBits and len(vals) == 2:
        print(f"known_zero = 0x{vals[0]:x}")
        print(f"known_one  = 0x{vals[1]:x}")
        all_ones = (1 << bw) - 1
        if (vals[0] & vals[1]) == 0 and ((vals[0] | vals[1]) & all_ones) == all_ones:
            print(f"exact     = 0x{(vals[1] & all_ones):x}")
    elif domain in {AbstractDomain.UConstRange, AbstractDomain.SConstRange} and len(vals) == 2:
        print(f"lower = 0x{vals[0]:x}")
        print(f"upper = 0x{vals[1]:x}")
        if vals[0] == vals[1]:
            print(f"exact = 0x{vals[0]:x}")
    elif domain is not None and domain.const_bw is not None and len(vals) == 1:
        bits = vals[0]
        residues = [str(i) for i in range(domain.const_bw) if ((bits >> i) & 1) == 1]
        print(f"residues mod {domain.const_bw}: {{{', '.join(residues)}}}")


def main() -> None:
    args = _register_parser()
    if args.bw <= 0 or args.bw > 64:
        raise ValueError("--bw must be in [1, 64]")

    domain = AbstractDomain[args.domain] if args.domain is not None else None
    if args.xfer_file is None:
        if domain is None or args.op is None:
            raise ValueError("Pass --xfer-file, or pass both --domain and --op")
        xfer_file = _infer_xfer_file(domain, args.op)
    else:
        xfer_file = args.xfer_file
        if domain is None:
            domain = _infer_domain_from_xfer_file(xfer_file)

    xfer_mod = parse_mlir_mod(xfer_file)
    xfer_fns = get_fns(xfer_mod)
    xfer_name = resolve_xfer_name(xfer_fns, args.xfer_name)
    xfer_fn = xfer_fns[xfer_name]

    shape = get_transfer_shape(xfer_fn, args.bw)
    arg_vals = _resolve_input_args(args, domain, shape.arg_lane_bits)
    if len(arg_vals) != len(shape.arg_lane_bits):
        raise ValueError(
            f"Expected {len(shape.arg_lane_bits)} --arg values, got {len(arg_vals)}"
        )

    res = eval_transfer_point(xfer_fn, args.bw, arg_vals)

    print(f"xfer_file: {xfer_file}")
    print(f"xfer_name: {xfer_name}")
    print(f"bw: {args.bw}")
    for i, (vals, bits) in enumerate(zip(arg_vals, shape.arg_lane_bits, strict=True)):
        print(f"arg{i}: {_format_lane_hex(vals, bits)}")
    print(f"res: {_format_lane_hex(res, shape.ret_lane_bits)}")
    _print_domain_friendly(domain, args.bw, res)


if __name__ == "__main__":
    main()
