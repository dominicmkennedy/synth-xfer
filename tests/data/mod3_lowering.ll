; ModuleID = ""
target triple = "unknown-unknown-unknown"
target datalayout = ""

define [1 x i3] @"getTop_16"([1 x i3] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"idx_0" = extractvalue [1 x i3] %".1", 0
  %"idx_0.1" = insertvalue [1 x i3] zeroinitializer, i3 7, 0
  ret [1 x i3] %"idx_0.1"
}

define [1 x i64] @"getTop_16_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i3
  %".5" = insertvalue [1 x i3] zeroinitializer, i3 %".4", 0
  %".6" = call [1 x i3] @"getTop_16"([1 x i3] %".5")
  %".7" = extractvalue [1 x i3] %".6", 0
  %".8" = zext i3 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}

define [1 x i3] @"getTop_64"([1 x i3] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"idx_0" = extractvalue [1 x i3] %".1", 0
  %"idx_0.1" = insertvalue [1 x i3] zeroinitializer, i3 7, 0
  ret [1 x i3] %"idx_0.1"
}

define [1 x i64] @"getTop_64_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i3
  %".5" = insertvalue [1 x i3] zeroinitializer, i3 %".4", 0
  %".6" = call [1 x i3] @"getTop_64"([1 x i3] %".5")
  %".7" = extractvalue [1 x i3] %".6", 0
  %".8" = zext i3 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}

define [1 x i3] @"meet_16"([1 x i3] %".1", [1 x i3] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs" = extractvalue [1 x i3] %".1", 0
  %"rhs" = extractvalue [1 x i3] %".2", 0
  %".4" = and i3 %"lhs", %"rhs"
  %"ret_abst" = insertvalue [1 x i3] zeroinitializer, i3 %".4", 0
  ret [1 x i3] %"ret_abst"
}

define [1 x i64] @"meet_16_shim"([1 x i64] %".1", [1 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [1 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i3
  %".6" = insertvalue [1 x i3] zeroinitializer, i3 %".5", 0
  %".7" = extractvalue [1 x i64] %".2", 0
  %".8" = trunc i64 %".7" to i3
  %".9" = insertvalue [1 x i3] zeroinitializer, i3 %".8", 0
  %".10" = call [1 x i3] @"meet_16"([1 x i3] %".6", [1 x i3] %".9")
  %".11" = extractvalue [1 x i3] %".10", 0
  %".12" = zext i3 %".11" to i64
  %".13" = insertvalue [1 x i64] zeroinitializer, i64 %".12", 0
  ret [1 x i64] %".13"
}

define [1 x i3] @"meet_64"([1 x i3] %".1", [1 x i3] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs" = extractvalue [1 x i3] %".1", 0
  %"rhs" = extractvalue [1 x i3] %".2", 0
  %".4" = and i3 %"lhs", %"rhs"
  %"ret_abst" = insertvalue [1 x i3] zeroinitializer, i3 %".4", 0
  ret [1 x i3] %"ret_abst"
}

define [1 x i64] @"meet_64_shim"([1 x i64] %".1", [1 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [1 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i3
  %".6" = insertvalue [1 x i3] zeroinitializer, i3 %".5", 0
  %".7" = extractvalue [1 x i64] %".2", 0
  %".8" = trunc i64 %".7" to i3
  %".9" = insertvalue [1 x i3] zeroinitializer, i3 %".8", 0
  %".10" = call [1 x i3] @"meet_64"([1 x i3] %".6", [1 x i3] %".9")
  %".11" = extractvalue [1 x i3] %".10", 0
  %".12" = zext i3 %".11" to i64
  %".13" = insertvalue [1 x i64] zeroinitializer, i64 %".12", 0
  ret [1 x i64] %".13"
}

define [1 x i3] @"empty_transformer_16"([1 x i3] %".1") alwaysinline norecurse nounwind readnone
{
entry:
}

define [1 x i64] @"empty_transformer_16_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i3
  %".5" = insertvalue [1 x i3] zeroinitializer, i3 %".4", 0
  %".6" = call [1 x i3] @"empty_transformer_16"([1 x i3] %".5")
  %".7" = extractvalue [1 x i3] %".6", 0
  %".8" = zext i3 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}

define [1 x i3] @"empty_transformer_64"([1 x i3] %".1") alwaysinline norecurse nounwind readnone
{
entry:
}

define [1 x i64] @"empty_transformer_64_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i3
  %".5" = insertvalue [1 x i3] zeroinitializer, i3 %".4", 0
  %".6" = call [1 x i3] @"empty_transformer_64"([1 x i3] %".5")
  %".7" = extractvalue [1 x i3] %".6", 0
  %".8" = zext i3 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}
