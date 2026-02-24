from stitch_core import compress
from pathlib import Path

# addition, subtraction, absolute difference
kb_additive = [
    "kb_Add", 
    "kb_AddNsw",
    "kb_AddNswNuw",
    "kb_AddNuw",
    "kb_Sub",
    "kb_SubNsw",
    "kb_SubNswNuw",
    "kb_SubNuw",
    "kb_Abds",
    "kb_Abdu"
]

cr_additive = [
    "ucr_Add",
    "ucr_AddNswNuw",
    "ucr_AddNuw",
    "ucr_Sub",
    "ucr_SubNswNuw",
    "scr_AddNswNuw",
    "scr_Sub",
    "scr_SubNswNuw"
]

# multiplication, division, remainder
kb_multiplicative = [
    "kb_Mul",
    "kb_MulNsw",
    "kb_MulNswNuw",
    "kb_MulNuw",
    "kb_Square"
    "kb_Sdiv",
    "kb_SdivExact",
    "kb_Udiv",
    "kb_UdivExact",
    "kb_Mods",
    "kb_Modu"
]

cr_multiplicative = [
    "ucr_UdivExact",
    "scr_SdivExact"
]

# shifting, rotating, and, or, xor
kb_bitwise = [
    "kb_And",
    "kb_Or",
    "kb_Xor", 
    "kb_Shl",
    "kb_ShlNsw",
    "kb_ShlNswNuw",
    "kb_ShlNuw",
    "kb_Ashr",
    "kb_AshrExact",
    "kb_Lshr",
    "kb_LshrExact", 
    "kb_Rotl",
    "kb_Rotr",
    "kb_Fshl",
    "kb_Fshr"
]

cr_bitwise = [
    "ucr_And",
    "ucr_Xor",
    "ucr_Shl",
    "scr_And",
    "scr_Xor,"
    "scr_Shl" 
]

# bit counting
kb_bitcount = [
    "kb_CountLOne",
    "kb_CountLZero",
    "kb_CountROne",
    "kb_CountRZero",
    "kb_PopCount"
]

# saturation and averaging
kb_saturation = [
    "kb_SaddSat",
    "kb_UaddSat",
    "kb_SsubSat",
    "kb_UsubSat",
    "kb_SmulSat",
    "kb_UmulSat",
    "kb_SshlSat",
    "kb_UshlSat",
    "kb_AvgCeilS",
    "kb_AvgCeilU",
    "kb_AvgFloorS",
    "kb_AvgFloorU", 
]

cr_saturation = [
    "scr_AvgCeilS",
    "ucr_AvgCeilS"
]

# comparison
kb_comparison = [
    "kb_Smax",
    "kb_Smin",
    "kb_Umax",
    "kb_Umin"
]

# control
kb_control = [
    "kb_Nop"
]

mod_control = [
    "mod11_xfer_nop",
    "mod13_xfer_nop",
    "mod3_xfer_nop",
    "mod5_xfer_nop",
    "mod7_xfer_nop"
]

op_groups = {
    "kb_additive" : kb_additive, 
    "cr_additive" : cr_additive, 
    "kb_multiplicative" : kb_multiplicative, 
    "cr_multiplicative" : cr_multiplicative,
    "kb_bitwise" : kb_bitwise,
    "cr_bitwise ": cr_bitwise,
    "kb_bitcount" : kb_bitcount,
    "kb_saturation" : kb_saturation,
    "cr_saturation" : cr_saturation,
    "kb_comparison" : kb_comparison,
    "kb_control" : kb_control,
    "mod_control" : mod_control
}

for name, group in op_groups.items():
    print(f"Compressing {name} group")

    programs = []
    for file_name in group:
        with open(f"corpus/lam/{file_name}.lam", "r") as file:
            programs.append(file.read())
    
    print(f"Read {len(programs)} files")
    print("Library learning...")

    res = compress(programs, iterations=3, max_arity=3)

    print("Library learned!")

    out = f"learned/{group}.txt"
    with open(out, 'w', encoding='utf-8') as file:
        for abstraction in res.abstractions:
            file.write(f"{str(abstraction)}\n")