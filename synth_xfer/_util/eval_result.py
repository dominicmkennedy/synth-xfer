from dataclasses import dataclass
from typing import Callable, TypeVar


@dataclass
class PerBitRes:
    "The evaluation result of (a candidate transformer f MEET a set of sound transformer F) and the best transformer f_best"

    all_cases: int
    "The number of inputs"

    bitwidth: int
    "The bitwidth it evaluates on"

    sounds: int
    "The number of inputs on which (f MEET F) gets sound"

    exacts: int
    "The number of inputs on which (f MEET F) gets exact"

    dist: float
    r"dist(f,g) := \sum{a} d(f(a) /\ g(a), best(a))"

    base_dist: float
    r"base_dis(f,g) := \sum{a} d(g(a), best(a))"

    unsolved_cases: int
    "The number of unsolved inputs (F do not get exact)"

    unsolved_exacts: int
    "The number of unsolved inputs on which (f MEET F) gets exact"

    sound_dist: float
    r"sound_dis(f,g) := \sum{a, f(a) is sound} d(f(a) /\ g(a), best(a)) + \sum{a, f(a) is unsound} d(g(a), best(a))"
    "sound_dis is equal to dist if f is sound."

    def __str__(self):
        s = ""
        s += f"bw: {self.bitwidth:<3}"
        s += f"all: {self.all_cases:<6}"
        s += f"s: {self.sounds:<6}"
        s += f"e: {self.exacts:<6}"
        s += f"uall: {self.unsolved_cases:<6}"
        s += f"ue: {self.unsolved_exacts:<6}"
        s += f"dis: {self.dist:<8}"
        s += f"bdis: {self.base_dist:<8}"
        s += f"sdis: {self.sound_dist:<8}"
        return s

    def get_sound_prop(self) -> float:
        return self.sounds / self.all_cases

    def get_exact_prop(self) -> float:
        return self.exacts / self.all_cases


def get_per_bit(a: str) -> list[PerBitRes]:
    T = TypeVar("T")

    x = a.split("\n")

    def get(in_str: str, to_match: str, parser: Callable[[str], T]) -> T:
        og_str, to_parse = in_str.split(":")

        assert og_str.strip() == to_match

        return parser(to_parse)

    def get_ints(s: str) -> list[int]:
        return eval(s)

    def get_floats(s: str) -> list[float]:
        return eval(s)

    bw = get(x[0], "bw", int)
    num_cases = get(x[1], "num cases", int)
    num_unsolved_cases = get(x[2], "num unsolved", int)
    base_distance = get(x[3], "base distance", float)
    sound = get(x[4], "num sound", get_ints)
    distance = get(x[5], "distance", get_floats)
    exact = get(x[6], "num exact", get_ints)
    num_unsolved_exact_cases = get(x[7], "num unsolved exact", get_ints)
    sound_distance = get(x[8], "sound distance", get_floats)

    assert len(sound) > 0, "No output from EvalEngine"
    assert (
        len(sound)
        == len(distance)
        == len(exact)
        == len(num_unsolved_exact_cases)
        == len(sound_distance)
    ), "EvalEngine output mismatch"

    return [
        PerBitRes(
            all_cases=num_cases,
            sounds=sound[i],
            exacts=exact[i],
            dist=distance[i],
            unsolved_cases=num_unsolved_cases,
            unsolved_exacts=num_unsolved_exact_cases[i],
            base_dist=base_distance,
            sound_dist=sound_distance[i],
            bitwidth=bw,
        )
        for i in range(len(sound))
    ]


class EvalResult:
    # Static variables
    lbws: set[int] = set()
    mbws: set[int] = set()
    hbws: set[int] = set()

    # Per Bit Results
    per_bit_res: list[PerBitRes]
    max_bit: int

    # These metrics are defined over all bitwidths
    all_cases: int
    sounds: int
    dist: float
    base_dist: float
    sound_dist: float

    # These metrics are defined over low and medium bitwidths
    all_low_med_cases: int
    exacts: int
    unsolved_cases: int
    unsolved_exacts: int

    @classmethod
    def init_bw_settings(
        cls,
        lbws: set[int],
        mbws: set[int],
        hbws: set[int],
    ):
        cls.lbws = lbws
        cls.mbws = mbws
        cls.hbws = hbws

    def __init__(self, per_bit_res: list[PerBitRes]):
        per_bit_res.sort(key=lambda x: x.bitwidth)
        self.per_bit_res = per_bit_res
        self.max_bit = max(per_bit_res, key=lambda x: x.bitwidth).bitwidth
        self.all_cases = sum(res.all_cases for res in per_bit_res)
        self.sounds = sum(res.sounds for res in per_bit_res)
        self.dist = sum(res.dist for res in per_bit_res)
        self.base_dist = sum(res.base_dist for res in per_bit_res)
        self.sound_dist = sum(res.sound_dist for res in per_bit_res)

        low_med_res = self.get_low_med_res()
        self.all_low_med_cases = sum(res.all_cases for res in low_med_res)
        self.exacts = sum(res.exacts for res in low_med_res)
        self.unsolved_cases = sum(res.unsolved_cases for res in low_med_res)
        self.unsolved_exacts = sum(res.unsolved_exacts for res in low_med_res)

    def __str__(self):
        return "\n".join(str(res) for res in self.per_bit_res)

    def get_low_med_res(self) -> list[PerBitRes]:
        return [
            res
            for res in self.per_bit_res
            if res.bitwidth in EvalResult.lbws | EvalResult.mbws
        ]

    def get_high_res(self) -> list[PerBitRes]:
        return [res for res in self.per_bit_res if res.bitwidth in EvalResult.hbws]

    def get_unsolved_cases(self) -> int:
        return self.unsolved_cases

    def get_unsolved_exacts(self) -> int:
        return self.unsolved_exacts

    def get_exacts(self) -> int:
        return self.exacts

    def get_dist(self) -> float:
        return self.dist

    def get_base_dist(self) -> float:
        return self.base_dist

    def get_sound_dist(self) -> float:
        return self.sound_dist

    def get_sound_prop(self) -> float:
        return self.sounds / self.all_cases

    def get_exact_prop(self) -> float:
        return self.exacts / self.all_low_med_cases

    def get_unsolved_exact_prop(self) -> float:
        return self.unsolved_exacts / self.unsolved_cases

    def get_new_exact_prop(self) -> float:
        return self.unsolved_exacts / self.all_low_med_cases

    def is_sound(self):
        return self.sounds == self.all_cases

    def get_potential_improve(self):
        return (self.base_dist - self.sound_dist) / (self.base_dist)
