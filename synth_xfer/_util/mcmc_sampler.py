from typing import Callable
from math import sqrt, log

import xdsl.dialects.arith as arith
from xdsl.dialects.builtin import FunctionType, IntegerAttr, UnitAttr, i1
from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir import OpResult, Operation
from xdsl_smt.dialects.transfer import (
    AbstractValueType,
    AddOp,
    AndOp,
    AShrOp,
    ClearHighBitsOp,
    ClearLowBitsOp,
    ClearSignBitOp,
    CmpOp,
    Constant,
    CountLOneOp,
    CountLZeroOp,
    CountROneOp,
    CountRZeroOp,
    GetAllOnesOp,
    GetBitWidthOp,
    GetOp,
    LShrOp,
    MakeOp,
    MulOp,
    NegOp,
    OrOp,
    PopCountOp,
    SDivOp,
    SelectOp,
    SetHighBitsOp,
    SetLowBitsOp,
    SetSignBitOp,
    ShlOp,
    SMaxOp,
    SMinOp,
    SRemOp,
    SubOp,
    TransIntegerType,
    UDivOp,
    UMaxOp,
    UMinOp,
    UnaryOp,
    URemOp,
    XorOp,
)

from synth_xfer._util.cond_func import FunctionWithCondition
from synth_xfer._util.cost_model import (
    abduction_cost,
    precise_cost,
    sound_and_precise_cost,
)
from synth_xfer._util.solution_set import SolutionSet
from synth_xfer._util.dsl_operators import BOOL_T, INT_T, get_operand_kinds, get_result_kind
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.mutation_program import MutationProgram
from synth_xfer._util.random import Random
from synth_xfer._util.synth_context import (
    SynthesizerContext,
    get_ret_type,
    is_int_op,
    not_in_main_body,
)

# Hyperparams
gamma = 0.99   # exponential decay constant
eta = 1.0      # initial value for npulled
beta = 0.25    # exploration tuning
epsilon = 0.01 # epsilon for epsilon greedy

# Names of all the operator subsets (not including ITE)
subset_names = ["bitwise", "add", "max", "mul", "shift", "bitset", "bitcount"]

# All operator subsets and their corresponding operations. There is no ITE
# operator, and there are some operations which aren't categorized (PopCountOp,
# SelectOp, UnaryOp)

# ADDED CmpOp to bitwise subset
subsets = {
    "bitwise" : [AndOp, OrOp, XorOp, NegOp, CmpOp],
    "add" : [AddOp, SubOp],
    "max" : [UMaxOp, UMinOp, SMaxOp, SMinOp],
    "mul" : [MulOp, UDivOp, SDivOp, URemOp, SRemOp],
    "shift" : [ShlOp, AShrOp, LShrOp],
    "bitset" : [SetHighBitsOp, SetLowBitsOp, ClearLowBitsOp, ClearHighBitsOp, SetSignBitOp, ClearSignBitOp],
    "bitcount" : [CountLOneOp, CountLZeroOp, CountROneOp, CountRZeroOp],
#    "ite" : []
}

class MCMCSampler:
    current: MutationProgram
    current_cmp: EvalResult
    context: SynthesizerContext
    random: Random
    cost_func: Callable[[EvalResult, float], float]
    step_cnt: int
    total_steps: int
    is_cond: bool
    length: int
    ops: dict[type[Operation], tuple[float, float]] # {operator : (score, npulled)}
    subset_scores: dict[str, tuple[float, float]]   # {subset : (score, npulled)}
    timestep: int                                   # timestep for decay
    pulled_operator: type[Operation] | None         # operator used for previous mutation
    pulled_subset: str | None                       # subset used for previous mutation
    mab: str                                       # whether to use MAB

    def __init__(
        self,
        func: FuncOp,
        context: SynthesizerContext,
        cost_func: Callable[[EvalResult, float], float],
        length: int,
        total_steps: int,
        reset_init_program: bool = True,
        random_init_program: bool = True,
        is_cond: bool = False,
        mab: str = "",
    ):
        self.is_cond = is_cond
        self.mab = mab
        if is_cond:
            cond_type = FunctionType.from_lists(
                func.function_type.inputs,  # pyright: ignore [reportArgumentType]
                [i1],
            )
            func = FuncOp("cond", cond_type)
        self.context = context
        self.cost_func = cost_func
        self.total_steps = total_steps
        self.step_cnt = 0
        self.random = context.get_random_class()
        self.length = length
        if reset_init_program:
            self.current = self.construct_init_program(func, self.length)
            if random_init_program:
                self.reset_to_random_prog()
        
        # Go through all the operations and add them to ops
        self.ops = {}
        for op in context.dsl_ops[BOOL_T].get_all_elements():
            self.ops[op] = (0, eta)
        for op in context.dsl_ops[INT_T].get_all_elements():
            self.ops[op] = (0, eta)

        self.subset_scores = {
        "bitwise" : (0, eta), 
        "add" : (0, eta), 
        "max" : (0, eta), 
        "mul" : (0, eta), 
        "shift" : (0, eta), 
        "bitset" : (0, eta), 
        "bitcount" : (0, eta)
        }
        self.timestep = 1
        self.pulled_operator = None
        self.pulled_subset = None
    
    def update_mab_dist(self, current_cost: float, proposed_cost: float):
        """
        Calculate the cost of whatever operator we mutated with and update the 
        MAB distribution.
        """
        if self.mab == "op":
            self.update_mab_dist_op(current_cost, proposed_cost)
        elif self.mab == "subs":
            self.update_mab_dist_subs(current_cost, proposed_cost)
        else:
            # do nothing, not using MAB
            pass

    def update_mab_dist_op(self, current_cost: float, proposed_cost: float):
        """
        Update the MAB distribution for the operator.
        """
        # self.pulled_operator will be None if previous mutation was operand
        if (self.pulled_operator != None):
            # decay score and npulled for all operations
            for op in self.ops.keys():
                score, npulled = self.ops[op]
                self.ops[op] = (score * gamma, npulled * gamma)
            
            # score is how much the mutation improves the cost
            score = current_cost - proposed_cost

            assert self.pulled_operator in self.ops, "Pulled operator should be in ops"

            # update score of pulled operator
            old_score, old_npulled = self.ops[self.pulled_operator]
            self.ops[self.pulled_operator] = (old_score + score, old_npulled + 1)
            self.pulled_operator = None

    def update_mab_dist_subs(self, current_cost: float, proposed_cost: float):
        """
        Calculate the cost of whatever subset we mutated with and update the 
        subset distribution.
        """
        # self.pulled_subset will be None if previous mutation was operand
        if (self.pulled_subset != None):
            # decay score and npulled for all subsets
            for subset, (score, npulled) in self.subset_scores.items():
                self.subset_scores[subset] = (score * gamma, npulled * gamma)
            
            # score is how much the mutation improves the cost
            score = current_cost - proposed_cost

            assert self.pulled_subset in self.subset_scores, "Pulled subset should be in subset_scores"

            # update score of pulled subset
            old_score, old_npulled = self.subset_scores[self.pulled_subset]
            self.subset_scores[self.pulled_subset] = (old_score + score, old_npulled + 1)
            self.pulled_subset = None

    def compute_cost(self, cmp: EvalResult) -> float:
        return self.cost_func(cmp, self.step_cnt / self.total_steps)

    def compute_current_cost(self):
        return self.compute_cost(self.current_cmp)

    def get_current(self):
        return self.current.func

    def accept_proposed(self, proposed_cmp: EvalResult):
        self.current.remove_history()
        self.current_cmp = proposed_cmp
        self.step_cnt += 1

    def reject_proposed(self):
        self.current.revert_operation()
        self.step_cnt += 1

    def replace_entire_operation(self, idx: int, history: bool):
        """
        Random pick an operation and replace it with a new one
        """
        old_op = self.current.ops[idx]
        valid_operands = {
            ty: self.current.get_valid_operands(idx, ty) for ty in [INT_T, BOOL_T]
        }
        new_op = None
        while new_op is None:
            new_op = self.context.get_random_op(get_ret_type(old_op), valid_operands)

        self.current.subst_operation(old_op, new_op, history)
        
    def replace_entire_operation_mab(self, idx: int, history: bool):
        """
        Random pick an operation and replace it with a new one chosen by
        multi-armed bandit

        idx : where the operation to replace lives (i.e., line number in program)
        history : whether to save the operation being replaced
        """
        self.timestep += 1
        old_op = self.current.ops[idx]
        op_type = get_ret_type(old_op)

        # score of each operation
        values : dict[type[Operation], float] = {}

        # Get all operations that return the target type
        ops_with_target_type = set(self.context.dsl_ops[op_type].get_all_elements())

        # calculate decayed timestep
        pulled = 0
        for _, (score, npulled) in self.ops.items():
            pulled += npulled

        # calculate score for each operator
        for op, (score, npulled) in self.ops.items():
            if op in ops_with_target_type:
                values[op] = score / npulled + 2*sqrt(beta * log(pulled) / npulled)

        # dict comp, all valid operands based on operation position
        valid_operands = {
            type : self.current.get_valid_operands(idx, type)
            for type in [INT_T, BOOL_T]
        }

        assert values, "No valid operations available for replacement"

        new_op: Operation | None = None
        best_op: type[Operation] | None = None
        while new_op is None:

            # epsilon greedy — can probably take this out now that we don't care about MCMC guarantees
            if self.random.random() < epsilon:  ## Maybe this is where nd is coming from???
                best_op = self.random.choice(list(values.keys()))
            else:
                best_op = max(values.keys(), key=lambda k: values[k])
            
            # a tuple of lists of operands that can fill the operator
            operands_vals = tuple(valid_operands[t] for t in get_operand_kinds(best_op))

            if (op_type == BOOL_T):
                # build i1
                new_op = self.context.build_i1_op(best_op, operands_vals)
            else:
                # build int
                new_op = self.context.build_int_op(best_op, operands_vals)

            del values[best_op]
        
        assert best_op is not None, "best_op should be set in the loop"
        assert new_op is not None, "new_op should be set in the loop"

        self.pulled_operator = best_op
        self.current.subst_operation(old_op, new_op, history)

    def replace_entire_operation_subs(self, idx: int, history: bool, solution_set: SolutionSet):
        self.timestep += 1
        old_op = self.current.ops[idx]
        op_type = get_ret_type(old_op)
        # print(f"Replacing operation of type: {old_op}, with type:'{op_type}'")

        # score of each subset
        values: dict[str, float] = {}

        # only add subsets where at least one op has correct return type
        subs_with_target_type = set()
        for subset, operators in subsets.items():
            for op in operators:
                # print(f"Checking operator: {op}, with type:'{get_result_kind(op)}'")
                if get_result_kind(op) == op_type:
                    # print(f"Adding subset: {subset}")
                    subs_with_target_type.add(subset)

        # if len(subs_with_target_type) > 0:
        #     print(f"Subsets with target type: {subs_with_target_type}")
        # else:
        #     print(f"No subsets with target type {op_type}, operation: {old_op}")
    
        # calculate decayed timestep
        pulled = 0
        for _, (_, npulled) in self.subset_scores.items():
            pulled += npulled
        
        # calculate score for each subset
        for subset, (score, npulled) in self.subset_scores.items():
            if subset in subs_with_target_type:
                values[subset] = score / npulled + 2*sqrt(beta * log(pulled) / npulled)
        
        # dict comp, all valid operands based on operation position
        valid_operands = {
            type : self.current.get_valid_operands(idx, type)
            for type in [INT_T, BOOL_T]
        }

        new_op: Operation | None = None
        best_op: type[Operation] | None = None
        best_subs: str | None = None
        while new_op is None:
            # select the subset with the best score
            assert len(values) > 0, "No valid subsets available for replacement (should at least be able to replace w/ self)"
            best_subs = max(values.keys(), key=lambda k: values[k])

            # track scores of ops in the best subset
            op_scores: dict[type[Operation], float] = {}

            # Need to keep the very first old_op in case need to revert later on (call it original_op)
            # Otherwise we keep subst_operator for each of the ops in the subset
            # Without needing to revert..., it will just replace the old_op with the new_op
            # Once we figure out the best op, do a subst_operator(original_op, best_op, history=True)
            # For acceptance criteria

            # loop through all the operators in the subset to find the highest scoring one
            for op in subsets[best_subs]:
                
                # only care about ops with correct return type, 
                # but op is not a full "Operation" object, so we use get_result_kind
                if (get_result_kind(op) == op_type):
                    operands_vals = tuple(valid_operands[t] for t in get_operand_kinds(op))

                    # build operation
                    if (op_type == BOOL_T):
                        new_op = self.context.build_i1_op(op, operands_vals)
                    else:
                        new_op = self.context.build_int_op(op, operands_vals)

                    if (new_op is None):
                        continue

                    self.current.subst_operation(old_op, new_op, history=True)

                    fwc = FunctionWithCondition(self.current.func.clone())
                    fwc.set_func_name(f"{self.current.func.sym_name.data}_temp")
                    cmp_results = solution_set.eval_improve([fwc])
                    score = self.compute_cost(cmp_results[0])
                    op_scores[op] = score
                    self.current.revert_operation()
                
                    # IDEA:
                    # self.context.subst_operator(old_op, new_op, history=False)
                    # calculate the score of the new program -- requires some stuff that currently lives in synthesize_one_iteration
                    # store scores and then mutate with best operator
            
            # find op with best score in the subset
            if len(op_scores) > 0:
                best_op = min(op_scores.keys(), key=lambda k: op_scores[k])
                # substitute original op for best op (with history so can revert later if rejected)
                operands_vals = tuple(valid_operands[t] for t in get_operand_kinds(best_op))
                if op_type == BOOL_T:
                    new_op = self.context.build_i1_op(best_op, operands_vals)
                else:
                    new_op = self.context.build_int_op(best_op, operands_vals)

        
        self.current.subst_operation(old_op, new_op, history)
        
        # Don't think we need to update
        # self.pulled_operator = best_op
        self.pulled_subset = best_subs

    def replace_operand(self, idx: int, history: bool):
        op = self.current.ops[idx]
        new_op = op.clone()

        self.current.subst_operation(op, new_op, history)

        ith = self.context.random.randint(0, len(op.operands) - 1)
        operand_kinds = get_operand_kinds(type(op))

        vals = self.current.get_valid_operands(idx, operand_kinds[ith])

        success = False
        while not success:
            success = self.context.replace_operand(new_op, ith, vals)

    def construct_init_program(self, _func: FuncOp, length: int):
        func = _func.clone()
        block = func.body.block
        for op in block.ops:
            block.detach_op(op)

        if self.context.weighted:
            func.attributes["from_weighted_dsl"] = UnitAttr()

        # Part I: GetOp
        for arg in block.args:
            if isinstance(arg.type, AbstractValueType):
                for i, field_type in enumerate(arg.type.get_fields()):
                    op = GetOp(arg, i)
                    block.add_op(op)

        assert isinstance(block.last_op, GetOp)
        tmp_int_ssavalue = block.last_op.results[0]

        # Part II: Constants
        true: arith.ConstantOp = arith.ConstantOp(
            IntegerAttr.from_int_and_width(1, 1), i1
        )
        false: arith.ConstantOp = arith.ConstantOp(
            IntegerAttr.from_int_and_width(0, 1), i1
        )
        all_ones = GetAllOnesOp(tmp_int_ssavalue)
        zero = Constant(tmp_int_ssavalue, 0)
        one = Constant(tmp_int_ssavalue, 1)
        get_bw = GetBitWidthOp(tmp_int_ssavalue)
        block.add_op(true)
        block.add_op(false)
        block.add_op(zero)
        block.add_op(one)
        block.add_op(all_ones)
        block.add_op(get_bw)

        if not self.is_cond:
            # Part III: Main Body
            last_int_op = block.last_op
            for i in range(length):
                if i % 4 == 0:
                    nop_bool = CmpOp(tmp_int_ssavalue, tmp_int_ssavalue, 0)
                    block.add_op(nop_bool)
                elif i % 4 == 1:
                    int_nop = AddOp(tmp_int_ssavalue, tmp_int_ssavalue)
                    block.add_op(int_nop)
                elif i % 4 == 2:
                    last_int_op = AndOp(tmp_int_ssavalue, tmp_int_ssavalue)
                    block.add_op(last_int_op)
                else:
                    last_int_op = AndOp(tmp_int_ssavalue, tmp_int_ssavalue)
                    block.add_op(last_int_op)

            # Part IV: MakeOp
            output = list(func.function_type.outputs)[0]
            assert isinstance(output, AbstractValueType)
            operands: list[OpResult] = []
            for i, field_type in enumerate(output.get_fields()):
                assert isinstance(field_type, TransIntegerType)
                assert last_int_op is not None
                operands.append(last_int_op.results[0])
                while True:
                    last_int_op = last_int_op.prev_op
                    assert last_int_op is not None
                    if is_int_op(last_int_op):
                        break

            return_val = MakeOp(operands)
            block.add_op(return_val)

        else:
            # Part III: Main Body
            last_bool_op = true
            for i in range(length):
                if i % 4 == 0:
                    last_int_op = AndOp(tmp_int_ssavalue, tmp_int_ssavalue)
                    block.add_op(last_int_op)
                else:
                    last_bool_op = CmpOp(tmp_int_ssavalue, tmp_int_ssavalue, 0)
                    block.add_op(last_bool_op)

            return_val = last_bool_op.results[0]

        # Part V: Return
        block.add_op(ReturnOp(return_val))

        return MutationProgram(func)

    def sample_next(self, solution_set: SolutionSet):
        """
        Sample the next program.
        Return the new program with the proposal ratio.
        """

        live_ops = self.current.get_modifiable_operations()
        live_op_indices = [x[1] for x in live_ops]

        sample_mode = self.random.random()

        # replace an operation with a new operation
        if sample_mode < 0.3 and live_op_indices:
            idx = self.random.choice(live_op_indices)
            if (self.mab == "op"):
                self.replace_entire_operation_mab(idx, True)
            elif (self.mab == "subs"):
                self.replace_entire_operation_subs(idx, True, solution_set)
            else:
                self.replace_entire_operation(idx, True)
        # replace an operand in an operation
        elif sample_mode < 1 and live_op_indices:
            idx = self.random.choice(live_op_indices)
            self.replace_operand(idx, True)
        # elif sample_mode < 1:
        #     # replace an operand in makeOp
        #     ratio = self.replace_make_operand(ops, len(ops) - 2)
        return self

    def reset_to_random_prog(self):
        # Part III-2: Random reset main body
        total_ops_len = len(self.current.ops)
        # Only modify ops in the main body
        for i in range(total_ops_len):
            if not not_in_main_body(self.current.ops[i]):
                self.replace_entire_operation(i, False)


def setup_mcmc(
    transfer_func: FuncOp,
    precise_set: list[FuncOp],
    num_abd_proc: int,
    num_programs: int,
    context_regular: SynthesizerContext,
    context_weighted: SynthesizerContext,
    context_cond: SynthesizerContext,
    program_length: int,
    total_rounds: int,
    cond_length: int,
    mab: str
) -> tuple[list[MCMCSampler], list[FuncOp], tuple[range, range, range]]:
    """
    A mcmc sampler use one of 3 modes: sound & precise, precise, condition
    This function specify which mode should be used for each mcmc sampler
    For example, mcmc samplers with index in sp_range should use "sound&precise"
    """

    p_size = 0
    c_size = num_abd_proc
    sp_size = num_programs - p_size - c_size

    if len(precise_set) == 0:
        sp_size += c_size
        c_size = 0

    sp_range = range(0, sp_size)
    p_range = range(sp_size, sp_size + p_size)
    c_range = range(sp_size + p_size, sp_size + p_size + c_size)

    prec_set_after_distribute: list[FuncOp] = []

    if c_size > 0:
        # Distribute the precise funcs into c_range
        prec_set_size = len(precise_set)
        base_count = c_size // prec_set_size
        remainder = c_size % prec_set_size
        for i, item in enumerate(precise_set):
            for _ in range(base_count + (1 if i < remainder else 0)):
                prec_set_after_distribute.append(item.clone())

    mcmc_samplers: list[MCMCSampler] = []
    for i in range(num_programs):
        if i in sp_range:
            spl = MCMCSampler(
                transfer_func,
                context_regular
                if i < (sp_range.start + sp_range.stop) // 2
                else context_weighted,
                sound_and_precise_cost,
                program_length,
                total_rounds,
                random_init_program=True,
                mab=mab
            )
        elif i in p_range:
            spl = MCMCSampler(
                transfer_func,
                context_regular
                if i < (p_range.start + p_range.stop) // 2
                else context_weighted,
                precise_cost,
                program_length,
                total_rounds,
                random_init_program=True,
                mab=mab
            )
        else:
            spl = MCMCSampler(
                transfer_func,
                context_cond,
                abduction_cost,
                cond_length,
                total_rounds,
                random_init_program=True,
                is_cond=True,
                mab=mab
            )

        mcmc_samplers.append(spl)

    return mcmc_samplers, prec_set_after_distribute, (sp_range, p_range, c_range)
