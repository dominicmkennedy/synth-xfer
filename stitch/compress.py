from stitch_core import compress
from pathlib import Path

long = [
    "kb_SubNswNuw", # 49716 lines
    "kb_UdivExact", # 49489 lines
    "kb_SdivExact", # 4436 lines
    "kb_Sdiv",      # 3668 lines
    "kb_SmulSat",   # 3413 lines
    "kb_MulNswNuw", # 2953 lines
    "kb_SaddSat",   # 2901 lines
    "kb_MulNsw",    # 2441 lines
    "kb_MulNuw",    # 2425 lines
    "kb_SubNsw",    # 2403 lines
    "kb_AvgCeilS",  # 1976 lines
    "kb_AvgCeilU",  # 1965 lines
    "kb_AvgFloorS", # 1945 lines
    "kb_AvgFloorU", # 1934 lines
    "kb_UmulSat",   # 1889 lines
    "kb_Mul",       # 1875 lines
    "kb_Mods",      # 1745 lines
    "kb_ShlNswNuw", # 1733 lines
    "kb_Modu",      # 1706 lines
    "kb_ShlNsw",    # 1556 lines
    "kb_ShlNuw",    # 1349 lines
    "kb_Smax",      # 1132 lines
    "kb_Smin",      # 1132 lines
    "kb_Sub",       # 1123 lines
    "kb_SsubSat",   # 745 lines
]   

# addition, subtraction, absolute difference
kb_additive = [
    "kb_Add", 
    "kb_AddNsw",
    "kb_AddNswNuw",
    "kb_AddNuw",
    "kb_SubNuw",
    "kb_Abds",
    "kb_Abdu",
]

cr_additive = [
    "ucr_Add",
    "ucr_AddNswNuw",
    "ucr_AddNuw",
    "ucr_Sub",
    "ucr_SubNswNuw",
    "scr_AddNswNuw",
    "scr_Sub",
    "scr_SubNswNuw",
]

# multiplication, division, remainder
kb_multiplicative = [
    "kb_Square",
    "kb_Udiv",
]

cr_multiplicative = [
    "ucr_UdivExact",
    "scr_SdivExact",
]

# shifting, rotating, and, or, xor
kb_bitwise = [
    "kb_And",
    "kb_Or",
    "kb_Xor", 
    "kb_Shl",
    "kb_Ashr",
    "kb_AshrExact",
    "kb_Lshr",
    "kb_LshrExact", 
    "kb_Rotl",
    "kb_Rotr",
    "kb_Fshl",
    "kb_Fshr",
]

cr_bitwise = [
    "ucr_And",
    "ucr_Xor",
    "ucr_Shl",
    "scr_And",
    "scr_Xor",
    "scr_Shl",
]

# bit counting
kb_bitcount = [
    "kb_CountLOne",
    "kb_CountLZero",
    "kb_CountROne",
    "kb_CountRZero",
    "kb_PopCount",
]

# saturation and averaging
kb_saturation = [
    "kb_UaddSat",
    
    "kb_UsubSat",
    "kb_SshlSat",
    "kb_UshlSat",
]

cr_saturation = [
    "scr_AvgCeilS",
    "ucr_AvgCeilS",
]

# comparison
kb_comparison = [
    "kb_Umax",
    "kb_Umin",
]

# control
kb_control = [
    "kb_Nop",
]

mod_control = [
    "mod11_xfer_nop",
    "mod13_xfer_nop",
    "mod3_xfer_nop",
    "mod5_xfer_nop",
    "mod7_xfer_nop",
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

    out = f"learned/{name}.txt"
    with open(out, 'w', encoding='utf-8') as file:
        for abstraction in res.abstractions:
            file.write(f"{str(abstraction)}\n")