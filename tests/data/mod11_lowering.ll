; ModuleID = ""
target triple = "unknown-unknown-unknown"
target datalayout = ""

define [1 x i11] @"getTop_16"([1 x i11] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"idx_0" = extractvalue [1 x i11] %".1", 0
  %"idx_0.1" = insertvalue [1 x i11] zeroinitializer, i11 2047, 0
  ret [1 x i11] %"idx_0.1"
}

define [1 x i64] @"getTop_16_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i11
  %".5" = insertvalue [1 x i11] zeroinitializer, i11 %".4", 0
  %".6" = call [1 x i11] @"getTop_16"([1 x i11] %".5")
  %".7" = extractvalue [1 x i11] %".6", 0
  %".8" = zext i11 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}

define [1 x i11] @"getTop_64"([1 x i11] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %"idx_0" = extractvalue [1 x i11] %".1", 0
  %"idx_0.1" = insertvalue [1 x i11] zeroinitializer, i11 2047, 0
  ret [1 x i11] %"idx_0.1"
}

define [1 x i64] @"getTop_64_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i11
  %".5" = insertvalue [1 x i11] zeroinitializer, i11 %".4", 0
  %".6" = call [1 x i11] @"getTop_64"([1 x i11] %".5")
  %".7" = extractvalue [1 x i11] %".6", 0
  %".8" = zext i11 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}

define [1 x i11] @"meet_16"([1 x i11] %".1", [1 x i11] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs" = extractvalue [1 x i11] %".1", 0
  %"rhs" = extractvalue [1 x i11] %".2", 0
  %".4" = and i11 %"lhs", %"rhs"
  %"ret_abst" = insertvalue [1 x i11] zeroinitializer, i11 %".4", 0
  ret [1 x i11] %"ret_abst"
}

define [1 x i64] @"meet_16_shim"([1 x i64] %".1", [1 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [1 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i11
  %".6" = insertvalue [1 x i11] zeroinitializer, i11 %".5", 0
  %".7" = extractvalue [1 x i64] %".2", 0
  %".8" = trunc i64 %".7" to i11
  %".9" = insertvalue [1 x i11] zeroinitializer, i11 %".8", 0
  %".10" = call [1 x i11] @"meet_16"([1 x i11] %".6", [1 x i11] %".9")
  %".11" = extractvalue [1 x i11] %".10", 0
  %".12" = zext i11 %".11" to i64
  %".13" = insertvalue [1 x i64] zeroinitializer, i64 %".12", 0
  ret [1 x i64] %".13"
}

define [1 x i11] @"meet_64"([1 x i11] %".1", [1 x i11] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %"lhs" = extractvalue [1 x i11] %".1", 0
  %"rhs" = extractvalue [1 x i11] %".2", 0
  %".4" = and i11 %"lhs", %"rhs"
  %"ret_abst" = insertvalue [1 x i11] zeroinitializer, i11 %".4", 0
  ret [1 x i11] %"ret_abst"
}

define [1 x i64] @"meet_64_shim"([1 x i64] %".1", [1 x i64] %".2") alwaysinline norecurse nounwind readnone
{
entry:
  %".4" = extractvalue [1 x i64] %".1", 0
  %".5" = trunc i64 %".4" to i11
  %".6" = insertvalue [1 x i11] zeroinitializer, i11 %".5", 0
  %".7" = extractvalue [1 x i64] %".2", 0
  %".8" = trunc i64 %".7" to i11
  %".9" = insertvalue [1 x i11] zeroinitializer, i11 %".8", 0
  %".10" = call [1 x i11] @"meet_64"([1 x i11] %".6", [1 x i11] %".9")
  %".11" = extractvalue [1 x i11] %".10", 0
  %".12" = zext i11 %".11" to i64
  %".13" = insertvalue [1 x i64] zeroinitializer, i64 %".12", 0
  ret [1 x i64] %".13"
}

define [1 x i11] @"empty_transformer_16"([1 x i11] %".1") alwaysinline norecurse nounwind readnone
{
entry:
}

define [1 x i64] @"empty_transformer_16_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i11
  %".5" = insertvalue [1 x i11] zeroinitializer, i11 %".4", 0
  %".6" = call [1 x i11] @"empty_transformer_16"([1 x i11] %".5")
  %".7" = extractvalue [1 x i11] %".6", 0
  %".8" = zext i11 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}

define [1 x i11] @"empty_transformer_64"([1 x i11] %".1") alwaysinline norecurse nounwind readnone
{
entry:
}

define [1 x i64] @"empty_transformer_64_shim"([1 x i64] %".1") alwaysinline norecurse nounwind readnone
{
entry:
  %".3" = extractvalue [1 x i64] %".1", 0
  %".4" = trunc i64 %".3" to i11
  %".5" = insertvalue [1 x i11] zeroinitializer, i11 %".4", 0
  %".6" = call [1 x i11] @"empty_transformer_64"([1 x i11] %".5")
  %".7" = extractvalue [1 x i11] %".6", 0
  %".8" = zext i11 %".7" to i64
  %".9" = insertvalue [1 x i64] zeroinitializer, i64 %".8", 0
  ret [1 x i64] %".9"
}
