from dataclasses import dataclass
from typing import Any

import llvmlite.binding as llvm


@dataclass(frozen=True)
class FnPtr:
    _addr: int
    _jit: "Jit"

    @property
    def addr(self) -> int:
        if self._jit._closed:
            raise RuntimeError("FnPtr used after Jit was closed")
        return self._addr


class Jit:
    @staticmethod
    def _create_exec_engine() -> tuple[
        llvm.ExecutionEngine, llvm.TargetMachine, llvm.Target
    ]:
        "This engine is reusable for an arbitrary number of modules."

        llvm.initialize_native_target()
        llvm.initialize_native_asmprinter()

        target = llvm.Target.from_default_triple()
        tm = target.create_target_machine(
            cpu=llvm.get_host_cpu_name(),
            features=llvm.get_host_cpu_features().flatten(),
            opt=2,
        )
        backing_mod = llvm.parse_assembly("")

        return llvm.create_mcjit_compiler(backing_mod, tm), tm, target

    engine, tm, target = _create_exec_engine()

    def __init__(self) -> None:
        self.mods: list[llvm.ModuleRef] = []
        self._closed = False

    def __enter__(self) -> "Jit":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        if self._closed:
            return
        for mod in self.mods:
            try:
                self.engine.remove_module(mod)
            except Exception:
                pass
        self.mods.clear()
        self._closed = True

    def add_mod(self, llvm_ir: Any) -> llvm.ModuleRef:
        if self._closed:
            raise RuntimeError("Jit is closed")
        mod = self._create_mod(str(llvm_ir))
        self._run_passes(mod)
        self.engine.add_module(mod)
        self.engine.finalize_object()
        self.engine.run_static_constructors()
        self.mods.append(mod)

        return mod

    def _create_mod(self, llvm_ir: str) -> llvm.ModuleRef:
        if self._closed:
            raise RuntimeError("Jit is closed")
        mod = llvm.parse_assembly(llvm_ir)
        mod.triple = self.target.triple
        mod.data_layout = str(self.tm.target_data)
        mod.verify()

        return mod

    def _run_passes(self, mod: llvm.ModuleRef):
        if self._closed:
            raise RuntimeError("Jit is closed")
        pb = llvm.PassBuilder(self.tm, llvm.PipelineTuningOptions())
        mpm = pb.getModulePassManager()
        mpm.add_instruction_combine_pass()
        mpm.add_simplify_cfg_pass()
        # TODO Add these back if we're able to upgrade llvmlite versions
        # mpm.add_aggressive_dce_pass()
        # mpm.add_aa_eval_pass()
        # mpm.add_aggressive_instcombine_pass()
        # mpm.add_constant_merge_pass()
        # mpm.add_rpo_function_attrs_pass()

        mpm.run(mod, pb)

    def get_fn_ptr(self, fn: str) -> FnPtr:
        if self._closed:
            raise RuntimeError("Jit is closed")

        ptr = self.engine.get_function_address(fn)
        if ptr == 0:
            raise ValueError(f"Function: {fn!r}, not found in in jit.")

        return FnPtr(ptr, self)
