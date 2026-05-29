#pragma once

#include "ConstantRange.h"
#include "KnownBits.h"

#include <array>
#include <bit>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <functional>
#include <optional>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <variant>
#include <vector>

namespace llvm {

using KBUnaryXfer = std::function<KnownBits(const KnownBits &, unsigned)>;
using KBBinaryXfer =
    std::function<KnownBits(const KnownBits &, const KnownBits &)>;
using KBTernaryXfer = std::function<KnownBits(
    const KnownBits &, const KnownBits &, const KnownBits &)>;
using KBAnyXfer = std::variant<KBUnaryXfer, KBBinaryXfer, KBTernaryXfer>;
struct KBOpSpec {
  KBAnyXfer xfer;
};

using CRUnaryXfer =
    std::function<ConstantRange(const ConstantRange &, unsigned)>;
using CRBinaryXfer =
    std::function<ConstantRange(const ConstantRange &, const ConstantRange &)>;
using CRTernaryXfer = std::function<ConstantRange(
    const ConstantRange &, const ConstantRange &, const ConstantRange &)>;
using CRAnyXfer = std::variant<CRUnaryXfer, CRBinaryXfer, CRTernaryXfer>;
struct CROpSpec {
  CRAnyXfer xfer;
};

inline static const auto u_wrap = ConstantRange::PreferredRangeType::Unsigned;
inline static const auto s_wrap = ConstantRange::PreferredRangeType::Signed;
inline static const int nsw = OverflowingBinaryOperator::NoSignedWrap;
inline static const int nuw = OverflowingBinaryOperator::NoUnsignedWrap;

#define KB_UNARY_OP(e)                                                         \
  KBUnaryXfer {                                                                \
    [](const KnownBits &x, unsigned bw) {                                      \
      (void)bw;                                                                \
      return e;                                                                \
    }                                                                          \
  }
#define KB_BINARY_OP(e)                                                        \
  KBBinaryXfer {                                                               \
    [](const KnownBits &l, const KnownBits &r) { return e; }                   \
  }

#define KB_ICMP_OP(cmp)                                                        \
  KBBinaryXfer {                                                               \
    [](const KnownBits &l, const KnownBits &r) {                               \
      auto x = cmp(l, r);                                                      \
      if (!x) {                                                                \
        return KnownBits(1);                                                   \
      } else {                                                                 \
        return KnownBits::makeConstant(APInt(1, *x));                          \
      }                                                                        \
    }                                                                          \
  }

inline KnownBits kb_select(const KnownBits &cond, const KnownBits &l,
                           const KnownBits &r) {
  if (cond.isUnknown())
    return l.intersectWith(r);
  return cond.isNonZero() ? l : r;
}

// logic from valuetracking.cpp
inline KnownBits kb_ctlz(const KnownBits &x, unsigned bw, bool is_zero_undef) {
  KnownBits known(bw);
  unsigned possible_lz = x.countMaxLeadingZeros();
  if (is_zero_undef)
    possible_lz = std::min(possible_lz, bw - 1);
  unsigned low_bits = static_cast<unsigned>(std::bit_width(possible_lz));
  known.Zero.setBitsFrom(low_bits);
  return known;
}

inline KnownBits kb_cttz(const KnownBits &x, unsigned bw, bool is_zero_undef) {
  KnownBits known(bw);
  unsigned possible_tz = x.countMaxTrailingZeros();
  if (is_zero_undef)
    possible_tz = std::min(possible_tz, bw - 1);
  unsigned low_bits = static_cast<unsigned>(std::bit_width(possible_tz));
  known.Zero.setBitsFrom(low_bits);
  return known;
}

inline KnownBits kb_ctpop(const KnownBits &x, unsigned bw) {
  KnownBits known(bw);
  unsigned bits_possibly_set = x.countMaxPopulation();
  unsigned low_bits = static_cast<unsigned>(std::bit_width(bits_possibly_set));
  known.Zero.setBitsFrom(low_bits);
  return known;
}

#define CR_UNARY_OP(e)                                                         \
  CRUnaryXfer {                                                                \
    [](const ConstantRange &x, unsigned bw) {                                  \
      (void)bw;                                                                \
      return e;                                                                \
    }                                                                          \
  }

#define CR_BINARY_OP(e)                                                        \
  CRBinaryXfer {                                                               \
    [](const ConstantRange &l, const ConstantRange &r) { return e; }           \
  }

#define CR_ICMP_OP(cmp_pred)                                                   \
  CRBinaryXfer {                                                               \
    [](const ConstantRange &l, const ConstantRange &r) {                       \
      if (l.icmp(cmp_pred, r))                                                 \
        return ConstantRange(APInt(1, 1));                                     \
      else                                                                     \
        return ConstantRange::getFull(1);                                      \
    }                                                                          \
  }

inline ConstantRange cr_select(const ConstantRange &cond,
                               const ConstantRange &l, const ConstantRange &r) {
  if (cond.isFullSet())
    return l.unionWith(r);
  return cond.contains(APInt(1, 1)) ? l : r;
}

// clang-format off
inline const std::unordered_map<std::string_view, KBOpSpec> kb_xfer_table = {
    {"TruncToBool",     {KB_UNARY_OP(x.trunc(1))}},
    {"ZextBool",        {KB_UNARY_OP(x.zext(bw))}},
    {"SextBool",        {KB_UNARY_OP(x.sext(bw))}},
    {"Abs",             {KB_UNARY_OP(x.abs(false))}},
    {"AbsUndef",        {KB_UNARY_OP(x.abs(true))}},
    {"PopCount",        {KB_UNARY_OP(kb_ctpop(x, bw))}},
    {"CountLZero",      {KB_UNARY_OP(kb_ctlz(x, bw, false))}},
    {"CountLZeroUndef", {KB_UNARY_OP(kb_ctlz(x, bw, true))}},
    {"CountRZero",      {KB_UNARY_OP(kb_cttz(x, bw, false))}},
    {"CountRZeroUndef", {KB_UNARY_OP(kb_cttz(x, bw, true))}},
    {"AddNswNuw",       {KB_BINARY_OP(KnownBits::add(l, r, /*NSW=*/true, /*NUW=*/true))}},
    {"AddNsw",          {KB_BINARY_OP(KnownBits::add(l, r, /*NSW=*/true, /*NUW=*/false))}},
    {"AddNuw",          {KB_BINARY_OP(KnownBits::add(l, r, /*NSW=*/false, /*NUW=*/true))}},
    {"Add",             {KB_BINARY_OP(KnownBits::add(l, r))}},
    {"And",             {KB_BINARY_OP(KnownBits(l) &= r)}},
    {"AshrExact",       {KB_BINARY_OP(KnownBits::ashr(l, r, false, /*Exact=*/true))}},
    {"Ashr",            {KB_BINARY_OP(KnownBits::ashr(l, r))}},
    {"LshrExact",       {KB_BINARY_OP(KnownBits::lshr(l, r, false, /*Exact=*/true))}},
    {"Lshr",            {KB_BINARY_OP(KnownBits::lshr(l, r))}},
    {"Mods",            {KB_BINARY_OP(KnownBits::srem(l, r))}},
    {"Modu",            {KB_BINARY_OP(KnownBits::urem(l, r))}},
    {"MulNswNuw",       {KB_BINARY_OP(llvm::kb_mul_wrapper(l, r, true, true))}},
    {"MulNsw",          {KB_BINARY_OP(llvm::kb_mul_wrapper(l, r, true, false))}},
    {"MulNuw",          {KB_BINARY_OP(llvm::kb_mul_wrapper(l, r, false, true))}},
    {"Mul",             {KB_BINARY_OP(KnownBits::mul(l, r))}},
    {"OrDisjoint",      {KB_BINARY_OP(KnownBits(l) |= r)}}, // Using flagless fallback
    {"Or",              {KB_BINARY_OP(KnownBits(l) |= r)}},
    {"SdivExact",       {KB_BINARY_OP(KnownBits::sdiv(l, r, /*Exact=*/true))}},
    {"Sdiv",            {KB_BINARY_OP(KnownBits::sdiv(l, r))}},
    {"ShlNswNuw",       {KB_BINARY_OP(KnownBits::shl(l, r, /*NUW=*/true, /*NSW=*/true))}},
    {"ShlNsw",          {KB_BINARY_OP(KnownBits::shl(l, r, /*NUW=*/false, /*NSW=*/true))}},
    {"ShlNuw",          {KB_BINARY_OP(KnownBits::shl(l, r, /*NUW=*/true, /*NSW=*/false))}},
    {"Shl",             {KB_BINARY_OP(KnownBits::shl(l, r))}},
    {"SubNswNuw",       {KB_BINARY_OP(KnownBits::sub(l, r, /*NSW=*/true, /*NUW=*/true))}},
    {"SubNsw",          {KB_BINARY_OP(KnownBits::sub(l, r, /*NSW=*/true, /*NUW=*/false))}},
    {"SubNuw",          {KB_BINARY_OP(KnownBits::sub(l, r, /*NSW=*/false, /*NUW=*/true))}},
    {"Sub",             {KB_BINARY_OP(KnownBits::sub(l, r))}},
    {"UdivExact",       {KB_BINARY_OP(KnownBits::udiv(l, r, /*Exact=*/true))}},
    {"Udiv",            {KB_BINARY_OP(KnownBits::udiv(l, r))}},
    {"Xor",             {KB_BINARY_OP(KnownBits(l) ^= r)}},
    {"Umax",            {KB_BINARY_OP(KnownBits::umax(l, r))}},
    {"Umin",            {KB_BINARY_OP(KnownBits::umin(l, r))}},
    {"Smax",            {KB_BINARY_OP(KnownBits::smax(l, r))}},
    {"Smin",            {KB_BINARY_OP(KnownBits::smin(l, r))}},
    {"SaddSat",         {KB_BINARY_OP(KnownBits::sadd_sat(l, r))}},
    {"UaddSat",         {KB_BINARY_OP(KnownBits::uadd_sat(l, r))}},
    {"SsubSat",         {KB_BINARY_OP(KnownBits::ssub_sat(l, r))}},
    {"UsubSat",         {KB_BINARY_OP(KnownBits::usub_sat(l, r))}},
    // {"SmulSat",      TODO add KnownBits transformer},
    // {"UmulSat",      TODO add KnownBits transformer},
    // {"SshlSat",      TODO add KnownBits transformer},
    // {"UshlSat",      TODO add KnownBits transformer},
    {"ICmpEq",          {KB_ICMP_OP(KnownBits::eq)}},
    {"ICmpNe",          {KB_ICMP_OP(KnownBits::ne)}},
    {"ICmpSlt",         {KB_ICMP_OP(KnownBits::slt)}},
    {"ICmpSle",         {KB_ICMP_OP(KnownBits::sle)}},
    {"ICmpSgt",         {KB_ICMP_OP(KnownBits::sgt)}},
    {"ICmpSge",         {KB_ICMP_OP(KnownBits::sge)}},
    {"ICmpUlt",         {KB_ICMP_OP(KnownBits::ult)}},
    {"ICmpUle",         {KB_ICMP_OP(KnownBits::ule)}},
    {"ICmpUgt",         {KB_ICMP_OP(KnownBits::ugt)}},
    {"ICmpUge",         {KB_ICMP_OP(KnownBits::uge)}},
    {"Select",          {kb_select}},
};
// clang-format on

// clang-format off
inline const std::unordered_map<std::string_view, CROpSpec> ucr_xfer_table = {
    {"Abs",             {CR_UNARY_OP(x.abs(false))}},
    {"AbsUndef",        {CR_UNARY_OP(x.abs(true))}},
    {"TruncToBool",     {CR_UNARY_OP(x.truncate(1))}},
    {"ZextBool",        {CR_UNARY_OP(x.zeroExtend(bw))}},
    {"SextBool",        {CR_UNARY_OP(x.signExtend(bw))}},
    {"PopCount",        {CR_UNARY_OP(x.ctpop())}},
    {"CountLZero",      {CR_UNARY_OP(x.ctlz(false))}},
    {"CountLZeroUndef", {CR_UNARY_OP(x.ctlz(true))}},
    {"CountRZero",      {CR_UNARY_OP(x.cttz(false))}},
    {"CountRZeroUndef", {CR_UNARY_OP(x.cttz(true))}},
    {"AddNswNuw",       {CR_BINARY_OP(l.addWithNoWrap(r, nsw | nuw, u_wrap))}},
    {"AddNsw",          {CR_BINARY_OP(l.addWithNoWrap(r, nsw, u_wrap))}},
    {"AddNuw",          {CR_BINARY_OP(l.addWithNoWrap(r, nuw, u_wrap))}},
    {"Add",             {CR_BINARY_OP(l.add(r))}},
    {"And",             {CR_BINARY_OP(l.binaryAnd(r))}},
    {"AshrExact",       {CR_BINARY_OP(l.ashr(r))}}, // NOTE: Using flagless fallback
    {"Ashr",            {CR_BINARY_OP(l.ashr(r))}},
    {"LshrExact",       {CR_BINARY_OP(l.lshr(r))}}, // NOTE: Using flagless fallback
    {"Lshr",            {CR_BINARY_OP(l.lshr(r))}},
    {"Mods",            {CR_BINARY_OP(l.srem(r))}},
    {"Modu",            {CR_BINARY_OP(l.urem(r))}},
    {"MulNswNuw",       {CR_BINARY_OP(l.multiplyWithNoWrap(r, nsw | nuw, u_wrap))}},
    {"MulNsw",          {CR_BINARY_OP(l.multiplyWithNoWrap(r, nsw, u_wrap))}},
    {"MulNuw",          {CR_BINARY_OP(l.multiplyWithNoWrap(r, nuw, u_wrap))}},
    {"Mul",             {CR_BINARY_OP(l.multiply(r))}},
    {"OrDisjoint",      {CR_BINARY_OP(l.binaryOr(r))}}, // NOTE: Using flagless fallback
    {"Or",              {CR_BINARY_OP(l.binaryOr(r))}},
    {"SdivExact",       {CR_BINARY_OP(l.sdiv(r))}}, // NOTE: Using flagless fallback
    {"Sdiv",            {CR_BINARY_OP(l.sdiv(r))}},
    {"ShlNswNuw",       {CR_BINARY_OP(l.shlWithNoWrap(r, nsw | nuw, u_wrap))}},
    {"ShlNsw",          {CR_BINARY_OP(l.shlWithNoWrap(r, nsw, u_wrap))}},
    {"ShlNuw",          {CR_BINARY_OP(l.shlWithNoWrap(r, nuw, u_wrap))}},
    {"Shl",             {CR_BINARY_OP(l.shl(r))}},
    {"SubNswNuw",       {CR_BINARY_OP(l.subWithNoWrap(r, nsw | nuw, u_wrap))}},
    {"SubNsw",          {CR_BINARY_OP(l.subWithNoWrap(r, nsw, u_wrap))}},
    {"SubNuw",          {CR_BINARY_OP(l.subWithNoWrap(r, nuw, u_wrap))}},
    {"Sub",             {CR_BINARY_OP(l.sub(r))}},
    {"UdivExact",       {CR_BINARY_OP(l.udiv(r))}}, // NOTE: Using flagless fallback
    {"Udiv",            {CR_BINARY_OP(l.udiv(r))}},
    {"Xor",             {CR_BINARY_OP(l.binaryXor(r))}},
    {"SaddSat",         {CR_BINARY_OP(l.sadd_sat(r))}},
    {"UaddSat",         {CR_BINARY_OP(l.uadd_sat(r))}},
    {"SsubSat",         {CR_BINARY_OP(l.ssub_sat(r))}},
    {"UsubSat",         {CR_BINARY_OP(l.usub_sat(r))}},
    {"SmulSat",         {CR_BINARY_OP(l.smul_sat(r))}},
    {"UmulSat",         {CR_BINARY_OP(l.umul_sat(r))}},
    {"SshlSat",         {CR_BINARY_OP(l.sshl_sat(r))}},
    {"UshlSat",         {CR_BINARY_OP(l.ushl_sat(r))}},
    {"Umax",            {CR_BINARY_OP(l.umax(r))}},
    {"Umin",            {CR_BINARY_OP(l.umin(r))}},
    {"Smax",            {CR_BINARY_OP(l.smax(r))}},
    {"Smin",            {CR_BINARY_OP(l.smin(r))}},
    {"ICmpEq",          {CR_ICMP_OP(ICMP_EQ)}},
    {"ICmpNe",          {CR_ICMP_OP(ICMP_NE)}},
    {"ICmpSlt",         {CR_ICMP_OP(ICMP_SLT)}},
    {"ICmpSle",         {CR_ICMP_OP(ICMP_SLE)}},
    {"ICmpSgt",         {CR_ICMP_OP(ICMP_SGT)}},
    {"ICmpSge",         {CR_ICMP_OP(ICMP_SGE)}},
    {"ICmpUlt",         {CR_ICMP_OP(ICMP_ULT)}},
    {"ICmpUle",         {CR_ICMP_OP(ICMP_ULE)}},
    {"ICmpUgt",         {CR_ICMP_OP(ICMP_UGT)}},
    {"ICmpUge",         {CR_ICMP_OP(ICMP_UGE)}},
    {"Select",          {cr_select}},
};
// clang-format on

// clang-format off
inline const std::unordered_map<std::string_view, CROpSpec> scr_xfer_table = {
    {"Abs",             {CR_UNARY_OP(x.abs(false))}},
    {"AbsUndef",        {CR_UNARY_OP(x.abs(true))}},
    {"TruncToBool",     {CR_UNARY_OP(x.truncate(1))}},
    {"ZextBool",        {CR_UNARY_OP(x.zeroExtend(bw))}},
    {"SextBool",        {CR_UNARY_OP(x.signExtend(bw))}},
    {"PopCount",        {CR_UNARY_OP(x.ctpop())}},
    {"CountLZero",      {CR_UNARY_OP(x.ctlz(false))}},
    {"CountLZeroUndef", {CR_UNARY_OP(x.ctlz(true))}},
    {"CountRZero",      {CR_UNARY_OP(x.cttz(false))}},
    {"CountRZeroUndef", {CR_UNARY_OP(x.cttz(true))}},
    {"AddNswNuw",       {CR_BINARY_OP(l.addWithNoWrap(r, nsw | nuw, s_wrap))}},
    {"AddNsw",          {CR_BINARY_OP(l.addWithNoWrap(r, nsw, s_wrap))}},
    {"AddNuw",          {CR_BINARY_OP(l.addWithNoWrap(r, nuw, s_wrap))}},
    {"Add",             {CR_BINARY_OP(l.add(r))}},
    {"And",             {CR_BINARY_OP(l.binaryAnd(r))}},
    {"AshrExact",       {CR_BINARY_OP(l.ashr(r))}}, // NOTE: Using flagless fallback
    {"Ashr",            {CR_BINARY_OP(l.ashr(r))}},
    {"LshrExact",       {CR_BINARY_OP(l.lshr(r))}}, // NOTE: Using flagless fallback
    {"Lshr",            {CR_BINARY_OP(l.lshr(r))}},
    {"Mods",            {CR_BINARY_OP(l.srem(r))}},
    {"Modu",            {CR_BINARY_OP(l.urem(r))}},
    {"MulNswNuw",       {CR_BINARY_OP(l.multiplyWithNoWrap(r, nsw | nuw, s_wrap))}},
    {"MulNsw",          {CR_BINARY_OP(l.multiplyWithNoWrap(r, nsw, s_wrap))}},
    {"MulNuw",          {CR_BINARY_OP(l.multiplyWithNoWrap(r, nuw, s_wrap))}},
    {"Mul",             {CR_BINARY_OP(l.multiply(r))}},
    {"OrDisjoint",      {CR_BINARY_OP(l.binaryOr(r))}}, // NOTE: Using flagless fallback
    {"Or",              {CR_BINARY_OP(l.binaryOr(r))}},
    {"SdivExact",       {CR_BINARY_OP(l.sdiv(r))}}, // NOTE: Using flagless fallback
    {"Sdiv",            {CR_BINARY_OP(l.sdiv(r))}},
    {"ShlNswNuw",       {CR_BINARY_OP(l.shlWithNoWrap(r, nsw | nuw, s_wrap))}},
    {"ShlNsw",          {CR_BINARY_OP(l.shlWithNoWrap(r, nsw, s_wrap))}},
    {"ShlNuw",          {CR_BINARY_OP(l.shlWithNoWrap(r, nuw, s_wrap))}},
    {"Shl",             {CR_BINARY_OP(l.shl(r))}},
    {"SubNswNuw",       {CR_BINARY_OP(l.subWithNoWrap(r, nsw | nuw, s_wrap))}},
    {"SubNsw",          {CR_BINARY_OP(l.subWithNoWrap(r, nsw, s_wrap))}},
    {"SubNuw",          {CR_BINARY_OP(l.subWithNoWrap(r, nuw, s_wrap))}},
    {"Sub",             {CR_BINARY_OP(l.sub(r))}},
    {"UdivExact",       {CR_BINARY_OP(l.udiv(r))}}, // NOTE: Using flagless fallback
    {"Udiv",            {CR_BINARY_OP(l.udiv(r))}},
    {"Xor",             {CR_BINARY_OP(l.binaryXor(r))}},
    {"SaddSat",         {CR_BINARY_OP(l.sadd_sat(r))}},
    {"UaddSat",         {CR_BINARY_OP(l.uadd_sat(r))}},
    {"SsubSat",         {CR_BINARY_OP(l.ssub_sat(r))}},
    {"UsubSat",         {CR_BINARY_OP(l.usub_sat(r))}},
    {"SmulSat",         {CR_BINARY_OP(l.smul_sat(r))}},
    {"UmulSat",         {CR_BINARY_OP(l.umul_sat(r))}},
    {"SshlSat",         {CR_BINARY_OP(l.sshl_sat(r))}},
    {"UshlSat",         {CR_BINARY_OP(l.ushl_sat(r))}},
    {"Umax",            {CR_BINARY_OP(l.umax(r))}},
    {"Umin",            {CR_BINARY_OP(l.umin(r))}},
    {"Smax",            {CR_BINARY_OP(l.smax(r))}},
    {"Smin",            {CR_BINARY_OP(l.smin(r))}},
    {"ICmpEq",          {CR_ICMP_OP(ICMP_EQ)}},
    {"ICmpNe",          {CR_ICMP_OP(ICMP_NE)}},
    {"ICmpSlt",         {CR_ICMP_OP(ICMP_SLT)}},
    {"ICmpSle",         {CR_ICMP_OP(ICMP_SLE)}},
    {"ICmpSgt",         {CR_ICMP_OP(ICMP_SGT)}},
    {"ICmpSge",         {CR_ICMP_OP(ICMP_SGE)}},
    {"ICmpUlt",         {CR_ICMP_OP(ICMP_ULT)}},
    {"ICmpUle",         {CR_ICMP_OP(ICMP_ULE)}},
    {"ICmpUgt",         {CR_ICMP_OP(ICMP_UGT)}},
    {"ICmpUge",         {CR_ICMP_OP(ICMP_UGE)}},
    {"Select",          {cr_select}},
};
// clang-format on

#undef KB_UNARY_OP
#undef KB_BINARY_OP
#undef KB_ICMP_OP
#undef CR_UNARY_OP
#undef CR_BINARY_OP
#undef CR_ICMP_OP

} // namespace llvm

enum class LLVMDomain { KnownBits, UConstRange, SConstRange };

template <LLVMDomain Kind, size_t NumArgs> class LLVMPattern {
  using ValueT = std::conditional_t<Kind == LLVMDomain::KnownBits,
                                    llvm::KnownBits, llvm::ConstantRange>;

  using UnaryXfer = std::conditional_t<Kind == LLVMDomain::KnownBits,
                                       llvm::KBUnaryXfer, llvm::CRUnaryXfer>;
  using BinaryXfer = std::conditional_t<Kind == LLVMDomain::KnownBits,
                                        llvm::KBBinaryXfer, llvm::CRBinaryXfer>;
  using TernaryXfer =
      std::conditional_t<Kind == LLVMDomain::KnownBits, llvm::KBTernaryXfer,
                         llvm::CRTernaryXfer>;
  using OpSpec = std::conditional_t<Kind == LLVMDomain::KnownBits,
                                    llvm::KBOpSpec, llvm::CROpSpec>;

  struct ArgNode {
    size_t arg;
  };

  struct UnaryOpNode {
    std::reference_wrapper<const UnaryXfer> xfer;
    size_t operand;
  };

  struct BinOpNode {
    std::reference_wrapper<const BinaryXfer> xfer;
    size_t left;
    size_t right;
  };

  struct TernaryOpNode {
    std::reference_wrapper<const TernaryXfer> xfer;
    size_t cond;
    size_t true_value;
    size_t false_value;
  };

  using Node = std::variant<ArgNode, UnaryOpNode, BinOpNode, TernaryOpNode>;

public:
  using ArgArray = std::array<ValueT, NumArgs>;

  ValueT operator()(const ArgArray &args) const {
    assert(!nodes_.empty());
    return eval(nodes_.size() - 1, args, args[0].getBitWidth());
  }

  std::array<std::uint64_t, 2>
  operator()(const std::array<std::array<std::uint64_t, 2>, NumArgs> &args,
             std::size_t bitwidth) const {
    const ArgArray llvm_args =
        [&]<std::size_t... Is>(std::index_sequence<Is...>) {
          return ArgArray{convert_arg(
              {llvm::APInt(static_cast<unsigned>(bitwidth), args[Is][0]),
               llvm::APInt(static_cast<unsigned>(bitwidth), args[Is][1])})...};
        }(std::make_index_sequence<NumArgs>{});

    return llvm_to_arr(
        eval(nodes_.size() - 1, llvm_args, static_cast<unsigned>(bitwidth)));
  }

  static LLVMPattern parse(std::string_view str) {
    Parser parser{str};
    return LLVMPattern{parser.parse()};
  }

private:
  explicit LLVMPattern(std::vector<Node> nodes) : nodes_(std::move(nodes)) {}

  static const auto &xfer_table() {
    if constexpr (Kind == LLVMDomain::KnownBits)
      return llvm::kb_xfer_table;
    else if constexpr (Kind == LLVMDomain::UConstRange)
      return llvm::ucr_xfer_table;
    else if constexpr (Kind == LLVMDomain::SConstRange)
      return llvm::scr_xfer_table;
  }

  static std::array<uint64_t, 2> llvm_to_arr(ValueT value) {
    if constexpr (Kind == LLVMDomain::KnownBits) {
      return {value.Zero.getZExtValue(), value.One.getZExtValue()};
    } else if constexpr (Kind == LLVMDomain::UConstRange) {
      const unsigned bw = value.getLower().getBitWidth();
      if (value.isFullSet() || value.isWrappedSet())
        return {llvm::APInt::getMinValue(bw).getZExtValue(),
                llvm::APInt::getMaxValue(bw).getZExtValue()};
      if (value.isEmptySet())
        return {llvm::APInt::getMaxValue(bw).getZExtValue(),
                llvm::APInt::getMinValue(bw).getZExtValue()};

      return {value.getLower().getZExtValue(),
              (value.getUpper() - 1).getZExtValue()};
    } else if constexpr (Kind == LLVMDomain::SConstRange) {
      const unsigned bw = value.getLower().getBitWidth();
      if (value.isFullSet() || value.isSignWrappedSet())
        return {llvm::APInt::getSignedMinValue(bw).getZExtValue(),
                llvm::APInt::getSignedMaxValue(bw).getZExtValue()};
      if (value.isEmptySet())
        return {llvm::APInt::getSignedMaxValue(bw).getZExtValue(),
                llvm::APInt::getSignedMinValue(bw).getZExtValue()};

      return {value.getLower().getZExtValue(),
              (value.getUpper() - 1).getZExtValue()};
    }
  }

  static ValueT convert_arg(std::array<llvm::APInt, 2> arg) {
    if constexpr (Kind == LLVMDomain::KnownBits) {
      llvm::KnownBits x = llvm::KnownBits(arg[0].getBitWidth());
      x.Zero = arg[0];
      x.One = arg[1];
      return x;
    } else if constexpr (Kind == LLVMDomain::UConstRange) {
      const unsigned bw = arg[0].getBitWidth();
      if (arg[0].isMinValue() && arg[1].isMaxValue())
        return llvm::ConstantRange::getFull(bw);
      if (arg[0].isMaxValue() && arg[1].isMinValue())
        return llvm::ConstantRange::getEmpty(bw);

      return llvm::ConstantRange(arg[0], arg[1] + 1);
    } else if constexpr (Kind == LLVMDomain::SConstRange) {
      const unsigned bw = arg[0].getBitWidth();
      if (arg[0].isMinSignedValue() && arg[1].isMaxSignedValue())
        return llvm::ConstantRange::getFull(bw);
      if (arg[0].isMaxSignedValue() && arg[1].isMinSignedValue())
        return llvm::ConstantRange::getEmpty(bw);

      return llvm::ConstantRange(arg[0], arg[1] + 1);
    }
  }

  class Parser {
  public:
    explicit Parser(std::string_view str) : str_(str) {}

    std::vector<Node> parse() {
      [[maybe_unused]] const size_t root = parse_expr();

      assert(pos_ == str_.size());
      assert(root + 1 == nodes_.size());

      return std::move(nodes_);
    }

  private:
    std::string_view str_;
    size_t pos_ = 0;
    std::vector<Node> nodes_;

    static bool is_ident_char(char c) {
      const auto uc = static_cast<unsigned char>(c);
      return std::isalnum(uc) != 0 || c == '_';
    }

    void expect(char _) {
      assert(pos_ < str_.size());
      assert(str_[pos_] == _);
      ++pos_;
    }

    std::string_view parse_ident() {
      const size_t start = pos_;

      while (pos_ < str_.size() && is_ident_char(str_[pos_]))
        ++pos_;

      assert(start != pos_);
      return str_.substr(start, pos_ - start);
    }

    static bool is_arg_name(std::string_view name) {
      return name.starts_with("arg");
    }

    static size_t parse_arg_index(std::string_view name) {
      assert(is_arg_name(name));

      size_t arg = 0;
      for (char c : name.substr(3))
        arg = arg * 10 + static_cast<size_t>(c - '0');

      return arg;
    }

    size_t add_node(Node node) {
      const size_t idx = nodes_.size();
      nodes_.push_back(std::move(node));
      return idx;
    }

    size_t parse_default_arg(size_t arg) {
      assert(arg < NumArgs);
      return add_node(ArgNode{arg});
    }

    size_t parse_expr() {
      const std::string_view name = parse_ident();

      if (is_arg_name(name)) {
        const size_t arg = parse_arg_index(name);
        assert(arg < NumArgs);
        return add_node(ArgNode{arg});
      }

      const auto &table = xfer_table();
      const auto it = table.find(name);
      assert(it != table.end());
      const OpSpec &spec = it->second;

      const bool bare_op = pos_ == str_.size() || str_[pos_] != '(';
      if (const auto *xfer = std::get_if<UnaryXfer>(&spec.xfer)) {
        const size_t operand = bare_op ? parse_default_arg(0) : [&] {
          expect('(');
          const size_t parsed = parse_expr();
          expect(')');
          return parsed;
        }();
        return add_node(UnaryOpNode{
            .xfer = std::cref(*xfer),
            .operand = operand,
        });
      }

      if (const auto *xfer = std::get_if<BinaryXfer>(&spec.xfer)) {
        const size_t left = bare_op ? parse_default_arg(0) : [&] {
          expect('(');
          const size_t parsed = parse_expr();
          expect(',');
          expect(' ');
          return parsed;
        }();
        const size_t right = bare_op ? parse_default_arg(1) : [&] {
          const size_t parsed = parse_expr();
          expect(')');
          return parsed;
        }();
        return add_node(BinOpNode{
            .xfer = std::cref(*xfer),
            .left = left,
            .right = right,
        });
      }

      const auto *xfer = std::get_if<TernaryXfer>(&spec.xfer);
      assert(xfer != nullptr);
      const size_t cond = bare_op ? parse_default_arg(0) : [&] {
        expect('(');
        const size_t parsed = parse_expr();
        expect(',');
        expect(' ');
        return parsed;
      }();
      const size_t true_value = bare_op ? parse_default_arg(1) : [&] {
        const size_t parsed = parse_expr();
        expect(',');
        expect(' ');
        return parsed;
      }();
      const size_t false_value = bare_op ? parse_default_arg(2) : [&] {
        const size_t parsed = parse_expr();
        expect(')');
        return parsed;
      }();
      return add_node(TernaryOpNode{
          .xfer = std::cref(*xfer),
          .cond = cond,
          .true_value = true_value,
          .false_value = false_value,
      });
    }
  };

  std::vector<Node> nodes_;

  ValueT eval(size_t node_idx, const ArgArray &args, unsigned bitwidth) const {
    assert(node_idx < nodes_.size());

    const Node &node = nodes_[node_idx];

    if (const auto *arg = std::get_if<ArgNode>(&node))
      return args[arg->arg];

    if (const auto *op = std::get_if<UnaryOpNode>(&node))
      return op->xfer.get()(eval(op->operand, args, bitwidth), bitwidth);

    if (const auto *op = std::get_if<BinOpNode>(&node))
      return op->xfer.get()(eval(op->left, args, bitwidth),
                            eval(op->right, args, bitwidth));

    const auto &op = std::get<TernaryOpNode>(node);
    return op.xfer.get()(eval(op.cond, args, bitwidth),
                         eval(op.true_value, args, bitwidth),
                         eval(op.false_value, args, bitwidth));
  }
};
