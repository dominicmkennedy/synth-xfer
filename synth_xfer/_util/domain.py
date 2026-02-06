from enum import Enum


class AbstractDomain(Enum):
    KnownBits = "KnownBits", 2, None
    UConstRange = "UConstRange", 2, None
    SConstRange = "SConstRange", 2, None
    Mod3 = "Mod3", 1, 3
    Mod5 = "Mod5", 1, 5
    Mod7 = "Mod7", 1, 7
    Mod11 = "Mod11", 1, 11
    Mod13 = "Mod13", 1, 13

    vec_size: int
    const_bw: int | None

    def __new__(
        cls,
        value: str,
        vec_size: int,
        const_bw: int | None,
    ):
        obj = object.__new__(cls)
        obj._value_ = value
        obj.vec_size = vec_size
        obj.const_bw = const_bw
        return obj

    def __str__(self) -> str:
        return self.name
