from itertools import chain, combinations
import xdsl.dialects.arith as arith
from synth_xfer._util.dsl_operators import DslOpSet, BOOL_T, INT_T
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

op_groups: dict[str, DslOpSet] = {
    "bitwise" : {INT_T: [AndOp, OrOp, XorOp, NegOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]}, 
    "add" : {INT_T: [AddOp, SubOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]}, 
    "max" : {INT_T: [UMaxOp, UMinOp, SMaxOp, SMinOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]}, 
    "mul" : {INT_T: [MulOp, UDivOp, SDivOp, URemOp, SRemOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]},
    "shift" : {INT_T: [ShlOp, AShrOp, LShrOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]},
    "bitset" : {INT_T: [SetHighBitsOp, SetLowBitsOp, ClearLowBitsOp, ClearHighBitsOp, SetSignBitOp, ClearSignBitOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]},
    "bitcount" : {INT_T: [CountLOneOp, CountLZeroOp, CountROneOp, CountRZeroOp], BOOL_T: [arith.AndIOp, arith.OrIOp, arith.XOrIOp, CmpOp]}
}

def get_op_groups() -> list[str]:
    """ return a list of all the op group names """

    return list(op_groups.keys())

def get_ops_in_group(name: str) -> DslOpSet | None:
    """ return the ops in a given group """

    if name in op_groups:
        return op_groups[name]
    return None

def get_ops_in_subset(subset: tuple[str, ...]) -> DslOpSet | None:
    """ return the ops in a given subset """

    ops: DslOpSet = {INT_T: [], BOOL_T: []}

    for op_group in subset:
        if op_group not in op_groups:
            return None

        ops[INT_T] += get_ops_in_group(op_group)[INT_T]
        ops[BOOL_T] += get_ops_in_group(op_group)[BOOL_T]
    
    ops[INT_T] = list(set(ops[INT_T]))
    ops[BOOL_T] = list(set(ops[BOOL_T]))

    return ops

def get_feature_vector(subset: tuple[str, ...]) -> tuple[float, ...] | None:
    """ 
    return the feature vector for a given subset. features are of the form:

    (bitwise, add, max, mul, shift, bitset, bitcount)
    """
    fvec: tuple[float, ...] = (0, 0, 0, 0, 0, 0, 0)

    for group in subset:
        match group:
            case 'bitwise':
                fvec[0] = 1
            case 'add':
                fvec[1] = 1
            case 'max':
                fvec[2] = 1
            case 'mul':
                fvec[3] = 1
            case 'shift':
                fvec[4] = 1
            case 'bitset':
                fvec[5] = 1
            case 'bitcount':
                fvec[6] = 1
            case _:
                return None
    
    return fvec


def get_name_powerset() -> list[tuple[str, ...]]:
    """ return the powerset of all the group names """

    names = list(chain.from_iterable(combinations(op_groups, r) for r in range(1,len(op_groups)+1)))

    return names

def get_full_powerset() -> dict[tuple[str, ...], DslOpSet]:
    """ 
    returns all possible subsets of operator groups. the dict keys are tuples
    corresponding to the groups present in the subset. the values are DslOpSets
    with all the allowed operators
    """

    # generate powerset of group names
    groupset = get_name_powerset()

    ps: dict[tuple[str, ...], DslOpSet] = {}

    for subset in groupset:
        ops: DslOpSet = {INT_T: [], BOOL_T: []}

        # merge DslOpSets for every op group in the subset
        for op_group in subset:
            ops[INT_T] += get_ops_in_group(op_group)[INT_T]
            ops[BOOL_T] += get_ops_in_group(op_group)[BOOL_T]

        ops[INT_T] = list(set(ops[INT_T]))
        ops[BOOL_T] = list(set(ops[BOOL_T]))

        ps[subset] = ops
    
    return ps