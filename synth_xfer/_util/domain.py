from enum import Enum


class AbstractDomain(Enum):
    KnownBits = "KnownBits", 2
    UConstRange = "UConstRange", 2
    SConstRange = "SConstRange", 2

    vec_size: int

    def __new__(
        cls,
        value: str,
        vec_size: int,
    ):
        obj = object.__new__(cls)
        obj._value_ = value
        obj.vec_size = vec_size
        return obj

    def __str__(self) -> str:
        return self.name
