from pathlib import Path
import subprocess
import sys

from synth_xfer._util.parse_mlir import parse_mlir_func
from synth_xfer._util.point_eval import eval_transfer_point, get_transfer_shape

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"


def test_eval_transfer_point_kb_ashr_32():
    kb_ashr = parse_mlir_func(DATA_DIR / "kb_ashr.mlir")
    shape = get_transfer_shape(kb_ashr, 32)

    assert shape.arg_lane_bits == ((32, 32), (32, 32))
    assert shape.ret_lane_bits == (32, 32)

    lhs = 0xDEADBEEF
    rhs = 16
    mask = (1 << 32) - 1

    res = eval_transfer_point(
        kb_ashr,
        32,
        (
            ((~lhs) & mask, lhs),
            ((~rhs) & mask, rhs),
        ),
    )

    assert res == (0x00002152, 0xFFFFDEAD)


def test_eval_point_cli_concrete_args_kb_ashr_32():
    out = subprocess.check_output(
        [
            sys.executable,
            "-m",
            "synth_xfer.cli.eval_point",
            "--bw",
            "32",
            "--xfer-file",
            "tests/data/kb_ashr.mlir",
            "--concrete-arg",
            "0xdeadbeef",
            "--concrete-arg",
            "16",
        ],
        cwd=PROJ_DIR,
        text=True,
    )
    assert "res: 0x00002152, 0xffffdead" in out
    assert "known_zero = 0x2152" in out
    assert "known_one  = 0xffffdead" in out
    assert "exact     = 0xffffdead" in out


def test_eval_point_cli_concrete_lhs_rhs_kb_ashr_32():
    out = subprocess.check_output(
        [
            sys.executable,
            "-m",
            "synth_xfer.cli.eval_point",
            "--bw",
            "32",
            "-d",
            "KnownBits",
            "--op",
            "Ashr",
            "--concrete-lhs",
            "0xdeadbeef",
            "--concrete-rhs",
            "16",
        ],
        cwd=PROJ_DIR,
        text=True,
    )
    assert "res: 0x00002152, 0xffffdead" in out
