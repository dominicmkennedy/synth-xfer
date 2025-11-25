import llvmlite.binding as llvm


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

    def add_mod(self, llvm_ir: str) -> llvm.ModuleRef:
        mod = self.create_mod(llvm_ir)
        self.run_passes(mod)
        self.engine.add_module(mod)
        self.engine.finalize_object()
        self.engine.run_static_constructors()
        self.mods.append(mod)

        return mod

    def create_mod(self, llvm_ir: str) -> llvm.ModuleRef:
        mod = llvm.parse_assembly(llvm_ir)
        mod.triple = self.target.triple
        mod.data_layout = str(self.tm.target_data)
        mod.verify()

        return mod

    def run_passes(self, mod: llvm.ModuleRef):
        pb = llvm.PassBuilder(self.tm, llvm.PipelineTuningOptions())
        mpm = pb.getModulePassManager()
        mpm.add_aggressive_dce_pass()
        mpm.add_aa_eval_pass()
        mpm.add_aggressive_instcombine_pass()
        mpm.add_simplify_cfg_pass()
        mpm.add_constant_merge_pass()
        mpm.add_rpo_function_attrs_pass()

        mpm.run(mod, pb)

    def get_fn_ptr(self, fn: str) -> int:
        ptr = self.engine.get_function_address(fn)
        assert ptr != 0
        return ptr
