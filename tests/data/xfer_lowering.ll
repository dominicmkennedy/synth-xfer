; ModuleID = ""
target triple = "unknown-unknown-unknown"
target datalayout = ""

define [2 x i4] @"kb_and_4"([2 x i4] %".1", [2 x i4] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i4] %".1", 0
  %"lhs1" = extractvalue [2 x i4] %".1", 1
  %"rhs0" = extractvalue [2 x i4] %".2", 0
  %"rhs1" = extractvalue [2 x i4] %".2", 1
  %".4" = or i4 %"lhs0", %"rhs0"
  %".5" = and i4 %"lhs1", %"rhs1"
  %"r" = insertvalue [2 x i4] zeroinitializer, i4 %".4", 0
  %"r.1" = insertvalue [2 x i4] %"r", i4 %".5", 1
  ret [2 x i4] %"r.1"
}

define [2 x i64] @"kb_and_4_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i4
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i4
  %".8" = insertvalue [2 x i4] zeroinitializer, i4 %".5", 0
  %".9" = insertvalue [2 x i4] %".8", i4 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i4
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i4
  %".14" = insertvalue [2 x i4] zeroinitializer, i4 %".11", 0
  %".15" = insertvalue [2 x i4] %".14", i4 %".13", 1
  %".16" = call [2 x i4] @"kb_and_4"([2 x i4] %".9", [2 x i4] %".15")
  %".17" = extractvalue [2 x i4] %".16", 0
  %".18" = zext i4 %".17" to i64
  %".19" = extractvalue [2 x i4] %".16", 1
  %".20" = zext i4 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i8] @"kb_and_8"([2 x i8] %".1", [2 x i8] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i8] %".1", 0
  %"lhs1" = extractvalue [2 x i8] %".1", 1
  %"rhs0" = extractvalue [2 x i8] %".2", 0
  %"rhs1" = extractvalue [2 x i8] %".2", 1
  %".4" = or i8 %"lhs0", %"rhs0"
  %".5" = and i8 %"lhs1", %"rhs1"
  %"r" = insertvalue [2 x i8] zeroinitializer, i8 %".4", 0
  %"r.1" = insertvalue [2 x i8] %"r", i8 %".5", 1
  ret [2 x i8] %"r.1"
}

define [2 x i64] @"kb_and_8_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i8
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i8
  %".8" = insertvalue [2 x i8] zeroinitializer, i8 %".5", 0
  %".9" = insertvalue [2 x i8] %".8", i8 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i8
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i8
  %".14" = insertvalue [2 x i8] zeroinitializer, i8 %".11", 0
  %".15" = insertvalue [2 x i8] %".14", i8 %".13", 1
  %".16" = call [2 x i8] @"kb_and_8"([2 x i8] %".9", [2 x i8] %".15")
  %".17" = extractvalue [2 x i8] %".16", 0
  %".18" = zext i8 %".17" to i64
  %".19" = extractvalue [2 x i8] %".16", 1
  %".20" = zext i8 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i64] @"kb_and_64"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i64] %".1", 0
  %"lhs1" = extractvalue [2 x i64] %".1", 1
  %"rhs0" = extractvalue [2 x i64] %".2", 0
  %"rhs1" = extractvalue [2 x i64] %".2", 1
  %".4" = or i64 %"lhs0", %"rhs0"
  %".5" = and i64 %"lhs1", %"rhs1"
  %"r" = insertvalue [2 x i64] zeroinitializer, i64 %".4", 0
  %"r.1" = insertvalue [2 x i64] %"r", i64 %".5", 1
  ret [2 x i64] %"r.1"
}

define [2 x i64] @"kb_and_64_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = extractvalue [2 x i64] %".1", 1
  %".6" = insertvalue [2 x i64] zeroinitializer, i64 %".4", 0
  %".7" = insertvalue [2 x i64] %".6", i64 %".5", 1
  %".8" = extractvalue [2 x i64] %".2", 0
  %".9" = extractvalue [2 x i64] %".2", 1
  %".10" = insertvalue [2 x i64] zeroinitializer, i64 %".8", 0
  %".11" = insertvalue [2 x i64] %".10", i64 %".9", 1
  %".12" = call [2 x i64] @"kb_and_64"([2 x i64] %".7", [2 x i64] %".11")
  %".13" = extractvalue [2 x i64] %".12", 0
  %".14" = extractvalue [2 x i64] %".12", 1
  %".15" = insertvalue [2 x i64] zeroinitializer, i64 %".13", 0
  %".16" = insertvalue [2 x i64] %".15", i64 %".14", 1
  ret [2 x i64] %".16"
}

define [2 x i4] @"kb_or_4"([2 x i4] %".1", [2 x i4] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i4] %".1", 0
  %"lhs1" = extractvalue [2 x i4] %".1", 1
  %"rhs0" = extractvalue [2 x i4] %".2", 0
  %"rhs1" = extractvalue [2 x i4] %".2", 1
  %".4" = and i4 %"lhs0", %"rhs0"
  %".5" = or i4 %"lhs1", %"rhs1"
  %"r" = insertvalue [2 x i4] zeroinitializer, i4 %".4", 0
  %"r.1" = insertvalue [2 x i4] %"r", i4 %".5", 1
  ret [2 x i4] %"r.1"
}

define [2 x i64] @"kb_or_4_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i4
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i4
  %".8" = insertvalue [2 x i4] zeroinitializer, i4 %".5", 0
  %".9" = insertvalue [2 x i4] %".8", i4 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i4
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i4
  %".14" = insertvalue [2 x i4] zeroinitializer, i4 %".11", 0
  %".15" = insertvalue [2 x i4] %".14", i4 %".13", 1
  %".16" = call [2 x i4] @"kb_or_4"([2 x i4] %".9", [2 x i4] %".15")
  %".17" = extractvalue [2 x i4] %".16", 0
  %".18" = zext i4 %".17" to i64
  %".19" = extractvalue [2 x i4] %".16", 1
  %".20" = zext i4 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i8] @"kb_or_8"([2 x i8] %".1", [2 x i8] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i8] %".1", 0
  %"lhs1" = extractvalue [2 x i8] %".1", 1
  %"rhs0" = extractvalue [2 x i8] %".2", 0
  %"rhs1" = extractvalue [2 x i8] %".2", 1
  %".4" = and i8 %"lhs0", %"rhs0"
  %".5" = or i8 %"lhs1", %"rhs1"
  %"r" = insertvalue [2 x i8] zeroinitializer, i8 %".4", 0
  %"r.1" = insertvalue [2 x i8] %"r", i8 %".5", 1
  ret [2 x i8] %"r.1"
}

define [2 x i64] @"kb_or_8_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i8
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i8
  %".8" = insertvalue [2 x i8] zeroinitializer, i8 %".5", 0
  %".9" = insertvalue [2 x i8] %".8", i8 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i8
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i8
  %".14" = insertvalue [2 x i8] zeroinitializer, i8 %".11", 0
  %".15" = insertvalue [2 x i8] %".14", i8 %".13", 1
  %".16" = call [2 x i8] @"kb_or_8"([2 x i8] %".9", [2 x i8] %".15")
  %".17" = extractvalue [2 x i8] %".16", 0
  %".18" = zext i8 %".17" to i64
  %".19" = extractvalue [2 x i8] %".16", 1
  %".20" = zext i8 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i64] @"kb_or_64"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i64] %".1", 0
  %"lhs1" = extractvalue [2 x i64] %".1", 1
  %"rhs0" = extractvalue [2 x i64] %".2", 0
  %"rhs1" = extractvalue [2 x i64] %".2", 1
  %".4" = and i64 %"lhs0", %"rhs0"
  %".5" = or i64 %"lhs1", %"rhs1"
  %"r" = insertvalue [2 x i64] zeroinitializer, i64 %".4", 0
  %"r.1" = insertvalue [2 x i64] %"r", i64 %".5", 1
  ret [2 x i64] %"r.1"
}

define [2 x i64] @"kb_or_64_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = extractvalue [2 x i64] %".1", 1
  %".6" = insertvalue [2 x i64] zeroinitializer, i64 %".4", 0
  %".7" = insertvalue [2 x i64] %".6", i64 %".5", 1
  %".8" = extractvalue [2 x i64] %".2", 0
  %".9" = extractvalue [2 x i64] %".2", 1
  %".10" = insertvalue [2 x i64] zeroinitializer, i64 %".8", 0
  %".11" = insertvalue [2 x i64] %".10", i64 %".9", 1
  %".12" = call [2 x i64] @"kb_or_64"([2 x i64] %".7", [2 x i64] %".11")
  %".13" = extractvalue [2 x i64] %".12", 0
  %".14" = extractvalue [2 x i64] %".12", 1
  %".15" = insertvalue [2 x i64] zeroinitializer, i64 %".13", 0
  %".16" = insertvalue [2 x i64] %".15", i64 %".14", 1
  ret [2 x i64] %".16"
}

define [2 x i4] @"kb_xor_4"([2 x i4] %".1", [2 x i4] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i4] %".1", 0
  %"lhs1" = extractvalue [2 x i4] %".1", 1
  %"rhs0" = extractvalue [2 x i4] %".2", 0
  %"rhs1" = extractvalue [2 x i4] %".2", 1
  %".4" = and i4 %"lhs0", %"rhs0"
  %".5" = and i4 %"lhs1", %"rhs1"
  %".6" = and i4 %"lhs0", %"rhs1"
  %".7" = and i4 %"lhs1", %"rhs0"
  %".8" = or i4 %".4", %".5"
  %".9" = or i4 %".6", %".7"
  %"r" = insertvalue [2 x i4] zeroinitializer, i4 %".8", 0
  %"r.1" = insertvalue [2 x i4] %"r", i4 %".9", 1
  ret [2 x i4] %"r.1"
}

define [2 x i64] @"kb_xor_4_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i4
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i4
  %".8" = insertvalue [2 x i4] zeroinitializer, i4 %".5", 0
  %".9" = insertvalue [2 x i4] %".8", i4 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i4
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i4
  %".14" = insertvalue [2 x i4] zeroinitializer, i4 %".11", 0
  %".15" = insertvalue [2 x i4] %".14", i4 %".13", 1
  %".16" = call [2 x i4] @"kb_xor_4"([2 x i4] %".9", [2 x i4] %".15")
  %".17" = extractvalue [2 x i4] %".16", 0
  %".18" = zext i4 %".17" to i64
  %".19" = extractvalue [2 x i4] %".16", 1
  %".20" = zext i4 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i8] @"kb_xor_8"([2 x i8] %".1", [2 x i8] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i8] %".1", 0
  %"lhs1" = extractvalue [2 x i8] %".1", 1
  %"rhs0" = extractvalue [2 x i8] %".2", 0
  %"rhs1" = extractvalue [2 x i8] %".2", 1
  %".4" = and i8 %"lhs0", %"rhs0"
  %".5" = and i8 %"lhs1", %"rhs1"
  %".6" = and i8 %"lhs0", %"rhs1"
  %".7" = and i8 %"lhs1", %"rhs0"
  %".8" = or i8 %".4", %".5"
  %".9" = or i8 %".6", %".7"
  %"r" = insertvalue [2 x i8] zeroinitializer, i8 %".8", 0
  %"r.1" = insertvalue [2 x i8] %"r", i8 %".9", 1
  ret [2 x i8] %"r.1"
}

define [2 x i64] @"kb_xor_8_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i8
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i8
  %".8" = insertvalue [2 x i8] zeroinitializer, i8 %".5", 0
  %".9" = insertvalue [2 x i8] %".8", i8 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i8
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i8
  %".14" = insertvalue [2 x i8] zeroinitializer, i8 %".11", 0
  %".15" = insertvalue [2 x i8] %".14", i8 %".13", 1
  %".16" = call [2 x i8] @"kb_xor_8"([2 x i8] %".9", [2 x i8] %".15")
  %".17" = extractvalue [2 x i8] %".16", 0
  %".18" = zext i8 %".17" to i64
  %".19" = extractvalue [2 x i8] %".16", 1
  %".20" = zext i8 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i64] @"kb_xor_64"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs0" = extractvalue [2 x i64] %".1", 0
  %"lhs1" = extractvalue [2 x i64] %".1", 1
  %"rhs0" = extractvalue [2 x i64] %".2", 0
  %"rhs1" = extractvalue [2 x i64] %".2", 1
  %".4" = and i64 %"lhs0", %"rhs0"
  %".5" = and i64 %"lhs1", %"rhs1"
  %".6" = and i64 %"lhs0", %"rhs1"
  %".7" = and i64 %"lhs1", %"rhs0"
  %".8" = or i64 %".4", %".5"
  %".9" = or i64 %".6", %".7"
  %"r" = insertvalue [2 x i64] zeroinitializer, i64 %".8", 0
  %"r.1" = insertvalue [2 x i64] %"r", i64 %".9", 1
  ret [2 x i64] %"r.1"
}

define [2 x i64] @"kb_xor_64_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = extractvalue [2 x i64] %".1", 1
  %".6" = insertvalue [2 x i64] zeroinitializer, i64 %".4", 0
  %".7" = insertvalue [2 x i64] %".6", i64 %".5", 1
  %".8" = extractvalue [2 x i64] %".2", 0
  %".9" = extractvalue [2 x i64] %".2", 1
  %".10" = insertvalue [2 x i64] zeroinitializer, i64 %".8", 0
  %".11" = insertvalue [2 x i64] %".10", i64 %".9", 1
  %".12" = call [2 x i64] @"kb_xor_64"([2 x i64] %".7", [2 x i64] %".11")
  %".13" = extractvalue [2 x i64] %".12", 0
  %".14" = extractvalue [2 x i64] %".12", 1
  %".15" = insertvalue [2 x i64] zeroinitializer, i64 %".13", 0
  %".16" = insertvalue [2 x i64] %".15", i64 %".14", 1
  ret [2 x i64] %".16"
}

define [2 x i4] @"cr_add_4"([2 x i4] %".1", [2 x i4] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs_lower" = extractvalue [2 x i4] %".1", 0
  %"lhs_upper" = extractvalue [2 x i4] %".1", 1
  %"rhs_lower" = extractvalue [2 x i4] %".2", 0
  %"rhs_upper" = extractvalue [2 x i4] %".2", 1
  %".4" = add i4 %"lhs_lower", %"rhs_lower"
  %".5" = add i4 %"lhs_upper", %"rhs_upper"
  %"res_lower_ov_ov" = call {i4, i1} @"llvm.uadd.with.overflow.i4"(i4 %"lhs_lower", i4 %"rhs_lower")
  %"res_lower_ov" = extractvalue {i4, i1} %"res_lower_ov_ov", 1
  %"res_upper_ov_ov" = call {i4, i1} @"llvm.uadd.with.overflow.i4"(i4 %"lhs_upper", i4 %"rhs_upper")
  %"res_upper_ov" = extractvalue {i4, i1} %"res_upper_ov_ov", 1
  %"lower_ge_upper" = icmp ugt i4 %".4", %".5"
  %".6" = xor i1 %"res_lower_ov", %"res_upper_ov"
  %".7" = or i1 %"lower_ge_upper", %".6"
  %".8" = select  i1 %".7", i4 0, i4 %".4"
  %".9" = select  i1 %".7", i4 15, i4 %".5"
  %"r" = insertvalue [2 x i4] zeroinitializer, i4 %".8", 0
  %"r.1" = insertvalue [2 x i4] %"r", i4 %".9", 1
  ret [2 x i4] %"r.1"
}

declare {i4, i1} @"llvm.uadd.with.overflow.i4"(i4 %".1", i4 %".2")

define [2 x i64] @"cr_add_4_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i4
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i4
  %".8" = insertvalue [2 x i4] zeroinitializer, i4 %".5", 0
  %".9" = insertvalue [2 x i4] %".8", i4 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i4
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i4
  %".14" = insertvalue [2 x i4] zeroinitializer, i4 %".11", 0
  %".15" = insertvalue [2 x i4] %".14", i4 %".13", 1
  %".16" = call [2 x i4] @"cr_add_4"([2 x i4] %".9", [2 x i4] %".15")
  %".17" = extractvalue [2 x i4] %".16", 0
  %".18" = zext i4 %".17" to i64
  %".19" = extractvalue [2 x i4] %".16", 1
  %".20" = zext i4 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i8] @"cr_add_8"([2 x i8] %".1", [2 x i8] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs_lower" = extractvalue [2 x i8] %".1", 0
  %"lhs_upper" = extractvalue [2 x i8] %".1", 1
  %"rhs_lower" = extractvalue [2 x i8] %".2", 0
  %"rhs_upper" = extractvalue [2 x i8] %".2", 1
  %".4" = add i8 %"lhs_lower", %"rhs_lower"
  %".5" = add i8 %"lhs_upper", %"rhs_upper"
  %"res_lower_ov_ov" = call {i8, i1} @"llvm.uadd.with.overflow.i8"(i8 %"lhs_lower", i8 %"rhs_lower")
  %"res_lower_ov" = extractvalue {i8, i1} %"res_lower_ov_ov", 1
  %"res_upper_ov_ov" = call {i8, i1} @"llvm.uadd.with.overflow.i8"(i8 %"lhs_upper", i8 %"rhs_upper")
  %"res_upper_ov" = extractvalue {i8, i1} %"res_upper_ov_ov", 1
  %"lower_ge_upper" = icmp ugt i8 %".4", %".5"
  %".6" = xor i1 %"res_lower_ov", %"res_upper_ov"
  %".7" = or i1 %"lower_ge_upper", %".6"
  %".8" = select  i1 %".7", i8 0, i8 %".4"
  %".9" = select  i1 %".7", i8 255, i8 %".5"
  %"r" = insertvalue [2 x i8] zeroinitializer, i8 %".8", 0
  %"r.1" = insertvalue [2 x i8] %"r", i8 %".9", 1
  ret [2 x i8] %"r.1"
}

declare {i8, i1} @"llvm.uadd.with.overflow.i8"(i8 %".1", i8 %".2")

define [2 x i64] @"cr_add_8_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i8
  %".6" = extractvalue [2 x i64] %".1", 1
  %".7" = trunc i64 %".6" to i8
  %".8" = insertvalue [2 x i8] zeroinitializer, i8 %".5", 0
  %".9" = insertvalue [2 x i8] %".8", i8 %".7", 1
  %".10" = extractvalue [2 x i64] %".2", 0
  %".11" = trunc i64 %".10" to i8
  %".12" = extractvalue [2 x i64] %".2", 1
  %".13" = trunc i64 %".12" to i8
  %".14" = insertvalue [2 x i8] zeroinitializer, i8 %".11", 0
  %".15" = insertvalue [2 x i8] %".14", i8 %".13", 1
  %".16" = call [2 x i8] @"cr_add_8"([2 x i8] %".9", [2 x i8] %".15")
  %".17" = extractvalue [2 x i8] %".16", 0
  %".18" = zext i8 %".17" to i64
  %".19" = extractvalue [2 x i8] %".16", 1
  %".20" = zext i8 %".19" to i64
  %".21" = insertvalue [2 x i64] zeroinitializer, i64 %".18", 0
  %".22" = insertvalue [2 x i64] %".21", i64 %".20", 1
  ret [2 x i64] %".22"
}

define [2 x i64] @"cr_add_64"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs_lower" = extractvalue [2 x i64] %".1", 0
  %"lhs_upper" = extractvalue [2 x i64] %".1", 1
  %"rhs_lower" = extractvalue [2 x i64] %".2", 0
  %"rhs_upper" = extractvalue [2 x i64] %".2", 1
  %".4" = add i64 %"lhs_lower", %"rhs_lower"
  %".5" = add i64 %"lhs_upper", %"rhs_upper"
  %"res_lower_ov_ov" = call {i64, i1} @"llvm.uadd.with.overflow.i64"(i64 %"lhs_lower", i64 %"rhs_lower")
  %"res_lower_ov" = extractvalue {i64, i1} %"res_lower_ov_ov", 1
  %"res_upper_ov_ov" = call {i64, i1} @"llvm.uadd.with.overflow.i64"(i64 %"lhs_upper", i64 %"rhs_upper")
  %"res_upper_ov" = extractvalue {i64, i1} %"res_upper_ov_ov", 1
  %"lower_ge_upper" = icmp ugt i64 %".4", %".5"
  %".6" = xor i1 %"res_lower_ov", %"res_upper_ov"
  %".7" = or i1 %"lower_ge_upper", %".6"
  %".8" = select  i1 %".7", i64 0, i64 %".4"
  %".9" = select  i1 %".7", i64 18446744073709551615, i64 %".5"
  %"r" = insertvalue [2 x i64] zeroinitializer, i64 %".8", 0
  %"r.1" = insertvalue [2 x i64] %"r", i64 %".9", 1
  ret [2 x i64] %"r.1"
}

declare {i64, i1} @"llvm.uadd.with.overflow.i64"(i64 %".1", i64 %".2")

define [2 x i64] @"cr_add_64_shim"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [2 x i64] %".1", 0
  %".5" = extractvalue [2 x i64] %".1", 1
  %".6" = insertvalue [2 x i64] zeroinitializer, i64 %".4", 0
  %".7" = insertvalue [2 x i64] %".6", i64 %".5", 1
  %".8" = extractvalue [2 x i64] %".2", 0
  %".9" = extractvalue [2 x i64] %".2", 1
  %".10" = insertvalue [2 x i64] zeroinitializer, i64 %".8", 0
  %".11" = insertvalue [2 x i64] %".10", i64 %".9", 1
  %".12" = call [2 x i64] @"cr_add_64"([2 x i64] %".7", [2 x i64] %".11")
  %".13" = extractvalue [2 x i64] %".12", 0
  %".14" = extractvalue [2 x i64] %".12", 1
  %".15" = insertvalue [2 x i64] zeroinitializer, i64 %".13", 0
  %".16" = insertvalue [2 x i64] %".15", i64 %".14", 1
  ret [2 x i64] %".16"
}
