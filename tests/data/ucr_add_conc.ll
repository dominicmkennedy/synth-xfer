; ModuleID = ""
target triple = "unknown-unknown-unknown"
target datalayout = ""

define [2 x i4] @"meet_4"([2 x i4] %".1", [2 x i4] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs_lb" = extractvalue [2 x i4] %".1", 0
  %"lhs_ub" = extractvalue [2 x i4] %".1", 1
  %"rhs_lb" = extractvalue [2 x i4] %".2", 0
  %"rhs_ub" = extractvalue [2 x i4] %".2", 1
  %"new_lb_cmp" = icmp ugt i4 %"lhs_lb", %"rhs_lb"
  %"new_lb" = select  i1 %"new_lb_cmp", i4 %"lhs_lb", i4 %"rhs_lb"
  %"new_ub_cmp" = icmp ult i4 %"lhs_ub", %"rhs_ub"
  %"new_ub" = select  i1 %"new_ub_cmp", i4 %"lhs_ub", i4 %"rhs_ub"
  %"result" = insertvalue [2 x i4] zeroinitializer, i4 %"new_lb", 0
  %"result.1" = insertvalue [2 x i4] %"result", i4 %"new_ub", 1
  ret [2 x i4] %"result.1"
}

define [2 x i8] @"meet_8"([2 x i8] %".1", [2 x i8] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs_lb" = extractvalue [2 x i8] %".1", 0
  %"lhs_ub" = extractvalue [2 x i8] %".1", 1
  %"rhs_lb" = extractvalue [2 x i8] %".2", 0
  %"rhs_ub" = extractvalue [2 x i8] %".2", 1
  %"new_lb_cmp" = icmp ugt i8 %"lhs_lb", %"rhs_lb"
  %"new_lb" = select  i1 %"new_lb_cmp", i8 %"lhs_lb", i8 %"rhs_lb"
  %"new_ub_cmp" = icmp ult i8 %"lhs_ub", %"rhs_ub"
  %"new_ub" = select  i1 %"new_ub_cmp", i8 %"lhs_ub", i8 %"rhs_ub"
  %"result" = insertvalue [2 x i8] zeroinitializer, i8 %"new_lb", 0
  %"result.1" = insertvalue [2 x i8] %"result", i8 %"new_ub", 1
  ret [2 x i8] %"result.1"
}

define [2 x i64] @"meet_64"([2 x i64] %".1", [2 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs_lb" = extractvalue [2 x i64] %".1", 0
  %"lhs_ub" = extractvalue [2 x i64] %".1", 1
  %"rhs_lb" = extractvalue [2 x i64] %".2", 0
  %"rhs_ub" = extractvalue [2 x i64] %".2", 1
  %"new_lb_cmp" = icmp ugt i64 %"lhs_lb", %"rhs_lb"
  %"new_lb" = select  i1 %"new_lb_cmp", i64 %"lhs_lb", i64 %"rhs_lb"
  %"new_ub_cmp" = icmp ult i64 %"lhs_ub", %"rhs_ub"
  %"new_ub" = select  i1 %"new_ub_cmp", i64 %"lhs_ub", i64 %"rhs_ub"
  %"result" = insertvalue [2 x i64] zeroinitializer, i64 %"new_lb", 0
  %"result.1" = insertvalue [2 x i64] %"result", i64 %"new_ub", 1
  ret [2 x i64] %"result.1"
}

define [2 x i4] @"top_4"([2 x i4] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"arg00" = extractvalue [2 x i4] %".1", 0
  %"result" = insertvalue [2 x i4] zeroinitializer, i4 0, 0
  %"result.1" = insertvalue [2 x i4] %"result", i4 15, 1
  ret [2 x i4] %"result.1"
}

define [2 x i8] @"top_8"([2 x i8] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"arg00" = extractvalue [2 x i8] %".1", 0
  %"result" = insertvalue [2 x i8] zeroinitializer, i8 0, 0
  %"result.1" = insertvalue [2 x i8] %"result", i8 255, 1
  ret [2 x i8] %"result.1"
}

define [2 x i64] @"top_64"([2 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"arg00" = extractvalue [2 x i64] %".1", 0
  %"result" = insertvalue [2 x i64] zeroinitializer, i64 0, 0
  %"result.1" = insertvalue [2 x i64] %"result", i64 18446744073709551615, 1
  ret [2 x i64] %"result.1"
}

define i4 @"concrete_op_4"(i4 %".1", i4 %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = add i4 %".1", %".2"
  ret i4 %".4"
}

define i64 @"concrete_op_4_shim"(i64 %".1_wide", i64 %".2_wide") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = trunc i64 %".1_wide" to i4
  %".5" = trunc i64 %".2_wide" to i4
  %".6" = call i4 @"concrete_op_4"(i4 %".4", i4 %".5")
  %".7" = zext i4 %".6" to i64
  ret i64 %".7"
}

define i8 @"concrete_op_8"(i8 %".1", i8 %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = add i8 %".1", %".2"
  ret i8 %".4"
}

define i64 @"concrete_op_8_shim"(i64 %".1_wide", i64 %".2_wide") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = trunc i64 %".1_wide" to i8
  %".5" = trunc i64 %".2_wide" to i8
  %".6" = call i8 @"concrete_op_8"(i8 %".4", i8 %".5")
  %".7" = zext i8 %".6" to i64
  ret i64 %".7"
}

define i64 @"concrete_op_64"(i64 %".1", i64 %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = add i64 %".1", %".2"
  ret i64 %".4"
}

define i64 @"concrete_op_64_shim"(i64 %".1_wide", i64 %".2_wide") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = call i64 @"concrete_op_64"(i64 %".1_wide", i64 %".2_wide")
  ret i64 %".4"
}
