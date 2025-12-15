from dataclasses import dataclass
from enum import Enum
import random
from typing import Any, Sequence

import synth_xfer._eval_engine as ee


class Random:
    from_file: bool
    file_rands: list[int]
    rands_len: int
    index: int

    def __init__(self, seed: int | None = None):
        if seed is not None:
            random.seed(seed)
        self.from_file = False
        self.file_rands = []
        self.rands_len = 0
        self.index = 0

    def __get_rand__(self) -> int:
        result = self.file_rands[self.index]
        self.index += 1
        self.index %= self.rands_len
        return result

    def random(self) -> float:
        if self.from_file:
            result = self.__get_rand__()
            return result / 100
        return random.random()

    def choice[T](self, lst: Sequence[T]) -> T:
        if self.from_file:
            cur_index = self.__get_rand__() % len(lst)
            return lst[cur_index]
        return random.choice(lst)

    def choice_weighted[T](self, lst: Sequence[T], weights: dict[T, int]) -> T:
        # todo: if self.from_file: ...
        w = [weights[key] for key in lst]
        return random.choices(lst, weights=w, k=1)[0]

    def choice2[T](self, lst: Sequence[T]) -> list[T]:
        if self.from_file:
            # assume the file provides 2 different numbers
            cur_index1 = self.__get_rand__() % len(lst)
            cur_index2 = self.__get_rand__() % len(lst)
            return [lst[cur_index1], lst[cur_index2]]
        return random.sample(lst, 2)

    def randint(self, a: int, b: int) -> int:
        if self.from_file:
            # first get the number in range [0, b-a+1)
            rand = self.__get_rand__() % (b - a + 1)
            return rand + a
        return random.randint(a, b)

    def read_from_file(self, rand_file: str):
        lst: list[int] = []
        with open(rand_file) as f:
            for line in f.readlines():
                lst += [int(x) for x in line.split()]
        self.file_rands = lst
        self.rands_len = len(lst)
        self.from_file = True
        assert self.rands_len != 0


@dataclass(frozen=True, slots=True)
class Sampler:
    class DistKind(str, Enum):
        UNIFORM = "uniform"
        NORMAL = "normal"
        SKEW_LEFT = "skew_left"
        SKEW_RIGHT = "skew_right"
        BIMODAL = "bimodal"

    kind: DistKind
    sampler: Any
    sigma: float | None = None
    alpha: float | None = None
    separation: float | None = None

    @staticmethod
    def uniform() -> "Sampler":
        return Sampler(kind=Sampler.DistKind.UNIFORM, sampler=ee.uniform_sampler())

    @staticmethod
    def normal(sigma: float) -> "Sampler":
        Sampler.validate_sigma(sigma)
        return Sampler(
            kind=Sampler.DistKind.NORMAL,
            sigma=sigma,
            sampler=ee.normal_sampler(sigma),
        )

    @staticmethod
    def skew_left(sigma: float, alpha: float) -> "Sampler":
        Sampler.validate_sigma(sigma)
        Sampler.validate_alpha(alpha)
        return Sampler(
            kind=Sampler.DistKind.SKEW_LEFT,
            sigma=sigma,
            alpha=alpha,
            sampler=ee.skew_left_sampler(sigma, alpha),
        )

    @staticmethod
    def skew_right(sigma: float, alpha: float) -> "Sampler":
        Sampler.validate_sigma(sigma)
        Sampler.validate_alpha(alpha)
        return Sampler(
            kind=Sampler.DistKind.SKEW_RIGHT,
            sigma=sigma,
            alpha=alpha,
            sampler=ee.skew_right_sampler(sigma, alpha),
        )

    @staticmethod
    def bimodal(sigma: float, separation: float) -> "Sampler":
        Sampler.validate_sigma(sigma)
        Sampler.validate_separation(separation)
        return Sampler(
            kind=Sampler.DistKind.BIMODAL,
            sigma=sigma,
            separation=separation,
            sampler=ee.bimodal_sampler(sigma, separation),
        )

    def __repr__(self) -> str:
        parts = [str(self.kind.value)]
        if self.sigma is not None:
            parts.append(f"sigma={self.sigma}")
        if self.alpha is not None:
            parts.append(f"alpha={self.alpha}")
        if self.separation is not None:
            parts.append(f"separation={self.separation}")
        return f"SamplerSpec({', '.join(parts)})"

    @staticmethod
    def validate_sigma(sigma: float) -> None:
        if not (float(sigma) > 0.0):
            raise ValueError("sigma must be > 0")

    @staticmethod
    def validate_alpha(alpha: float) -> None:
        if not (float(alpha) > 0.0):
            raise ValueError("alpha must be > 0 (magnitude)")

    @staticmethod
    def validate_separation(separation: float) -> None:
        sep = float(separation)
        if sep < 0.0 or sep > 0.49:
            raise ValueError("separation must be in [0.0, 0.49]")
