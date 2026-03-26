from argparse import ArgumentParser, ArgumentTypeError, Namespace

from synth_xfer._util.random import Sampler


def int_tuple(s: str) -> tuple[int, int]:
    try:
        items = s.split(",")
        if len(items) != 2:
            raise ValueError
        return (int(items[0]), int(items[1]))
    except Exception:
        raise ArgumentTypeError(f"Invalid tuple format: '{s}'. Expected format: int,int")


def int_triple(s: str) -> tuple[int, int, int]:
    try:
        items = s.split(",")
        if len(items) != 3:
            raise ValueError
        return (int(items[0]), int(items[1]), int(items[2]))
    except Exception:
        raise ArgumentTypeError(
            f"Invalid tuple format: '{s}'. Expected format: int,int,int"
        )


def int_list(s: str) -> list[int]:
    result: list[int] = []

    if s == "[]":
        return []

    for chunk in s.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue

        if "-" in chunk:
            parts = chunk.split("-")
            if len(parts) != 2 or not parts[0] or not parts[1]:
                raise ArgumentTypeError(f"Invalid range: {chunk!r}")

            try:
                start = int(parts[0].strip())
                end = int(parts[1].strip())
            except ValueError:
                raise ArgumentTypeError(f"Invalid range: {chunk!r}")

            if start < 0 or end < 0:
                raise ArgumentTypeError(f"Negative values are not allowed: {chunk!r}")
            if start > end:
                raise ArgumentTypeError(f"Range start must be <= end (got {chunk!r})")

            result.extend(range(start, end + 1))
        else:
            try:
                value = int(chunk)
            except ValueError:
                raise ArgumentTypeError(f"Invalid integer: {chunk!r}")
            if value < 0:
                raise ArgumentTypeError(f"Negative values are not allowed: {chunk!r}")
            result.append(value)

    if not result:
        raise ArgumentTypeError("Empty list of integers")

    return result


def make_sampler_parser(p: ArgumentParser):
    mx = p.add_mutually_exclusive_group(required=False)
    mx.add_argument(
        "--uniform", action="store_true", help="Use uniform sampling (default)"
    )
    mx.add_argument("--normal", action="store_true", help="Use normal sampling")
    mx.add_argument(
        "--skew-left", action="store_true", help="Use skew-normal left sampling"
    )
    mx.add_argument(
        "--skew-right", action="store_true", help="Use skew-normal right sampling"
    )
    mx.add_argument(
        "--bimodal", action="store_true", help="Use bimodal symmetric sampling"
    )

    g_normal = p.add_argument_group("normal options")
    g_normal.add_argument(
        "--sigma", type=float, default=0.15, help="Stddev in unit space"
    )

    g_skew = p.add_argument_group("skew options")
    g_skew.add_argument("--alpha", type=float, default=5.0, help="Skew magnitude (>0)")

    g_bimodal = p.add_argument_group("bimodal options")
    g_bimodal.add_argument(
        "--separation", type=float, default=0.22, help="Peak separation in [0, 0.49]"
    )

    return p


def get_sampler(args: Namespace) -> Sampler:
    if args.normal:
        return Sampler.normal(sigma=args.sigma)
    if args.skew_left:
        return Sampler.skew_left(sigma=args.sigma, alpha=args.alpha)
    if args.skew_right:
        return Sampler.skew_right(sigma=args.sigma, alpha=args.alpha)
    if args.bimodal:
        return Sampler.bimodal(sigma=args.sigma, separation=args.separation)

    return Sampler.uniform()
