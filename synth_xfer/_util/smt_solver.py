from enum import Enum
from typing import Protocol

import bitwuzla
import cvc5
import z3


class SolverKind(str, Enum):
    z3 = "z3"
    cvc5 = "cvc5"
    bitwuzla = "bitwuzla"

    def __str__(self) -> str:
        return self.value


class Model(Protocol):
    def get_bv(self, name: str) -> int | None: ...
    def items(self) -> list[tuple[str, int]]: ...


def _normalize_smt2(text: str) -> str:
    lines = [line for line in text.splitlines() if line.strip() != "(check-sat)"]
    if not any(line.startswith("(set-logic ") for line in lines):
        lines.insert(0, "(set-logic QF_BV)")
    return "\n".join(lines)


class Z3Model:
    def __init__(self, model: z3.ModelRef):
        self._model = model

    def get_bv(self, name: str) -> int | None:
        for decl in self._model:
            if str(decl) != name:
                continue
            value = self._model[decl]
            if isinstance(value, z3.BitVecNumRef):
                return value.as_long()
        return None

    def items(self) -> list[tuple[str, int]]:
        items: list[tuple[str, int]] = []
        for decl in self._model:
            value = self._model[decl]
            if isinstance(decl, z3.FuncDeclRef) and isinstance(value, z3.BitVecNumRef):
                items.append((str(decl), value.as_long()))
        return items


class CVC5Model:
    def __init__(self, solver: cvc5.Solver, symbol_manager: cvc5.SymbolManager):  # type: ignore
        self._solver = solver
        self._symbol_manager = symbol_manager

    def get_bv(self, name: str) -> int | None:
        for term in self._symbol_manager.getDeclaredTerms():
            if not term.hasSymbol() or term.getSymbol() != name:
                continue
            value = self._solver.getValue(term)
            if value.isBitVectorValue():
                return int(value.getBitVectorValue(), 2)
        return None

    def items(self) -> list[tuple[str, int]]:
        items: list[tuple[str, int]] = []
        for term in self._symbol_manager.getDeclaredTerms():
            if not term.hasSymbol():
                continue
            value = self._solver.getValue(term)
            if value.isBitVectorValue():
                items.append((term.getSymbol(), int(value.getBitVectorValue(), 2)))
        return items


class BitwuzlaModel:
    def __init__(self, bzla: bitwuzla.Bitwuzla, parser: bitwuzla.Parser):
        self._bzla = bzla
        self._parser = parser

    @staticmethod
    def parse_bv_bits(value: str) -> int | None:
        if value.startswith("#b"):
            return int(value[2:], 2)
        if value.startswith("#x"):
            return int(value[2:], 16)
        return None

    def get_bv(self, name: str) -> int | None:
        for term in self._parser.get_declared_funs():
            if term.symbol() != name:
                continue
            return self.parse_bv_bits(str(self._bzla.get_value(term)))
        return None

    def items(self) -> list[tuple[str, int]]:
        items: list[tuple[str, int]] = []
        for term in self._parser.get_declared_funs():
            value = self.parse_bv_bits(str(self._bzla.get_value(term)))
            if value is not None:
                items.append((term.symbol(), value))
        return items


class IncrementalSolver(Protocol):
    def push(self) -> None: ...
    def pop(self) -> None: ...
    def add_smt2(self, text: str) -> None: ...
    def check(self) -> bool | None: ...
    def model(self) -> Model | None: ...


class Z3Solver:
    def __init__(self, base_smt2: str, timeout: int):
        self._solver = z3.Solver()
        self._solver.set(timeout=timeout * 1000)
        self._solver.from_string(_normalize_smt2(base_smt2))

    def push(self) -> None:
        self._solver.push()

    def pop(self) -> None:
        self._solver.pop()

    def add_smt2(self, text: str) -> None:
        self._solver.from_string(text)

    def check(self) -> bool | None:
        result = self._solver.check()
        if result == z3.unknown:
            return None
        return result == z3.sat

    def model(self) -> Model | None:
        return Z3Model(self._solver.model())


class CVC5Solver:
    def __init__(self, base_smt2: str, timeout: int):
        self._solver = cvc5.Solver()  # type: ignore
        self._solver.setOption("produce-models", "true")
        self._solver.setOption("tlimit-per", str(timeout * 1000))
        self._parser = cvc5.InputParser(self._solver)  # type: ignore
        self._symbol_manager = self._parser.getSymbolManager()
        self.add_smt2(_normalize_smt2(base_smt2))

    def _invoke(self, text: str) -> None:
        self._parser.setStringInput(cvc5.InputLanguage.SMT_LIB_2_6, text, "<text>")  # type: ignore
        while True:
            cmd = self._parser.nextCommand()
            if cmd.isNull():
                return
            cmd.invoke(self._solver, self._symbol_manager)

    def push(self) -> None:
        self._solver.push()

    def pop(self) -> None:
        self._solver.pop()

    def add_smt2(self, text: str) -> None:
        self._invoke(text)

    def check(self) -> bool | None:
        result = self._solver.checkSat()
        if result.isUnknown():
            return None
        return result.isSat()

    def model(self) -> Model | None:
        return CVC5Model(self._solver, self._symbol_manager)


class BitwuzlaSolver:
    def __init__(self, base_smt2: str, timeout: int):
        self._term_manager = bitwuzla.TermManager()
        options = bitwuzla.Options()
        options.set(bitwuzla.Option.PRODUCE_MODELS, True)
        options.set(bitwuzla.Option.TIME_LIMIT_PER, timeout * 1000)
        self._parser = bitwuzla.Parser(self._term_manager, options)
        self.add_smt2(_normalize_smt2(base_smt2))
        self._solver = self._parser.bitwuzla()

    def push(self) -> None:
        self._solver.push()

    def pop(self) -> None:
        self._solver.pop()

    def add_smt2(self, text: str) -> None:
        self._parser.parse(text, True, False)

    def check(self) -> bool | None:
        result = self._solver.check_sat()
        if result == bitwuzla.Result.UNKNOWN:
            return None
        return result == bitwuzla.Result.SAT

    def model(self) -> Model | None:
        return BitwuzlaModel(self._solver, self._parser)


def make_solver(kind: SolverKind, base_smt2: str, timeout: int) -> IncrementalSolver:
    if kind == SolverKind.z3:
        return Z3Solver(base_smt2, timeout)
    if kind == SolverKind.cvc5:
        return CVC5Solver(base_smt2, timeout)
    if kind == SolverKind.bitwuzla:
        return BitwuzlaSolver(base_smt2, timeout)
