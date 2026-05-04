// Note: this code was taken from llvm 22.1.0 files:
// llvm-project/llvm/include/llvm/Support/KnownBits.h
// llvm-project/llvm/lib/Support/KnownBits.cpp
// and `computeKnownBitsMul` was taken from ValueTracking.cpp
// And combinded into a standalone header with codex

#ifndef LLVM_KNOWNBITS_STANDALONE_H
#define LLVM_KNOWNBITS_STANDALONE_H

#include <optional>

#include "APInt.h"

namespace llvm {
namespace knownbits_detail {

static inline bool isPowerOf2_32(uint32_t x) {
  return x && ((x & (x - 1)) == 0);
}

static inline unsigned Log2_32(uint32_t x) {
  return 31u - static_cast<unsigned>(__builtin_clz(x));
}

} // namespace knownbits_detail

struct KnownBits {
  APInt Zero;
  APInt One;

private:
  KnownBits(APInt Zero, APInt One)
      : Zero(std::move(Zero)), One(std::move(One)) {}

  static KnownBits flipSignBit(const KnownBits &Val);

public:
  KnownBits() = default;
  KnownBits(unsigned BitWidth) : Zero(BitWidth, 0), One(BitWidth, 0) {}

  unsigned getBitWidth() const {
    assert(Zero.getBitWidth() == One.getBitWidth() &&
           "Zero and One should have the same width!");
    return Zero.getBitWidth();
  }

  bool hasConflict() const { return Zero.intersects(One); }
  bool isConstant() const {
    return Zero.popcount() + One.popcount() == getBitWidth();
  }
  const APInt &getConstant() const {
    assert(isConstant() && "Can only get value when all bits are known");
    return One;
  }
  bool isUnknown() const { return Zero.isZero() && One.isZero(); }
  bool isZero() const { return Zero.isAllOnes(); }
  bool isAllOnes() const { return One.isAllOnes(); }
  void setAllZero() {
    Zero.setAllBits();
    One.clearAllBits();
  }
  void setAllConflict() {
    Zero.setAllBits();
    One.setAllBits();
  }

  bool isNegative() const { return One.isSignBitSet(); }
  bool isNonNegative() const { return Zero.isSignBitSet(); }
  bool isNonZero() const { return !One.isZero(); }
  bool isStrictlyPositive() const {
    return Zero.isSignBitSet() && !One.isZero();
  }
  void makeNegative() { One.setSignBit(); }
  void makeNonNegative() { Zero.setSignBit(); }
  APInt getMinValue() const { return One; }

  APInt getSignedMinValue() const {
    APInt Min = One;
    if (Zero.isSignBitClear())
      Min.setSignBit();
    return Min;
  }

  APInt getMaxValue() const { return ~Zero; }

  APInt getSignedMaxValue() const {
    APInt Max = ~Zero;
    if (One.isSignBitClear())
      Max.clearSignBit();
    return Max;
  }

  KnownBits trunc(unsigned BitWidth) const {
    return KnownBits(Zero.trunc(BitWidth), One.trunc(BitWidth));
  }

  KnownBits zext(unsigned BitWidth) const {
    unsigned OldBitWidth = getBitWidth();
    APInt NewZero = Zero.zext(BitWidth);
    NewZero.setBitsFrom(OldBitWidth);
    return KnownBits(NewZero, One.zext(BitWidth));
  }

  KnownBits zextOrTrunc(unsigned BitWidth) const {
    if (BitWidth > getBitWidth())
      return zext(BitWidth);
    if (BitWidth < getBitWidth())
      return trunc(BitWidth);
    return *this;
  }

  unsigned countMinTrailingZeros() const { return Zero.countr_one(); }
  unsigned countMinLeadingZeros() const { return Zero.countl_one(); }
  unsigned countMinLeadingOnes() const { return One.countl_one(); }
  unsigned countMinSignBits() const {
    if (isNonNegative())
      return countMinLeadingZeros();
    if (isNegative())
      return countMinLeadingOnes();
    return 1;
  }

  unsigned countMaxTrailingZeros() const { return One.countr_zero(); }
  unsigned countMaxLeadingZeros() const { return One.countl_zero(); }
  unsigned countMaxLeadingOnes() const { return Zero.countl_zero(); }
  static KnownBits makeConstant(const APInt &C) { return KnownBits(~C, C); }
  KnownBits intersectWith(const KnownBits &RHS) const {
    return KnownBits(Zero & RHS.Zero, One & RHS.One);
  }
  KnownBits unionWith(const KnownBits &RHS) const {
    return KnownBits(Zero | RHS.Zero, One | RHS.One);
  }
  static bool haveNoCommonBitsSet(const KnownBits &LHS, const KnownBits &RHS) {
    return (LHS.Zero | RHS.Zero).isAllOnes();
  }
  static KnownBits computeForAddCarry(const KnownBits &LHS,
                                      const KnownBits &RHS,
                                      const KnownBits &Carry);
  static KnownBits computeForAddSub(bool Add, bool NSW, bool NUW,
                                    const KnownBits &LHS, const KnownBits &RHS);
  static KnownBits computeForSubBorrow(const KnownBits &LHS, KnownBits RHS,
                                       const KnownBits &Borrow);
  static KnownBits add(const KnownBits &LHS, const KnownBits &RHS,
                       bool NSW = false, bool NUW = false) {
    return computeForAddSub(/*Add=*/true, NSW, NUW, LHS, RHS);
  }
  static KnownBits sub(const KnownBits &LHS, const KnownBits &RHS,
                       bool NSW = false, bool NUW = false) {
    return computeForAddSub(/*Add=*/false, NSW, NUW, LHS, RHS);
  }
  static KnownBits mul(const KnownBits &LHS, const KnownBits &RHS,
                       bool NoUndefSelfMultiply = false);
  static KnownBits sdiv(const KnownBits &LHS, const KnownBits &RHS,
                        bool Exact = false);
  static KnownBits udiv(const KnownBits &LHS, const KnownBits &RHS,
                        bool Exact = false);
  static KnownBits urem(const KnownBits &LHS, const KnownBits &RHS);
  static KnownBits srem(const KnownBits &LHS, const KnownBits &RHS);
  static KnownBits shl(const KnownBits &LHS, const KnownBits &RHS,
                       bool NUW = false, bool NSW = false,
                       bool ShAmtNonZero = false);
  static KnownBits lshr(const KnownBits &LHS, const KnownBits &RHS,
                        bool ShAmtNonZero = false, bool Exact = false);
  static KnownBits ashr(const KnownBits &LHS, const KnownBits &RHS,
                        bool ShAmtNonZero = false, bool Exact = false);
  static std::optional<bool> sgt(const KnownBits &LHS, const KnownBits &RHS);
  KnownBits &operator&=(const KnownBits &RHS) {
    Zero |= RHS.Zero;
    One &= RHS.One;
    return *this;
  }

  KnownBits &operator|=(const KnownBits &RHS) {
    Zero &= RHS.Zero;
    One |= RHS.One;
    return *this;
  }

  KnownBits &operator^=(const KnownBits &RHS) {
    APInt Z = (Zero & RHS.Zero) | (One & RHS.One);
    One = (Zero & RHS.One) | (One & RHS.Zero);
    Zero = std::move(Z);
    return *this;
  }

  KnownBits &operator<<=(unsigned ShAmt) {
    Zero <<= ShAmt;
    One <<= ShAmt;
    return *this;
  }

  KnownBits &operator>>=(unsigned ShAmt) {
    Zero.lshrInPlace(ShAmt);
    One.lshrInPlace(ShAmt);
    return *this;
  }

  bool operator==(const KnownBits &Other) const {
    return Zero == Other.Zero && One == Other.One;
  }

  bool operator!=(const KnownBits &Other) const { return !(*this == Other); }

private:
  static KnownBits remGetLowBits(const KnownBits &LHS, const KnownBits &RHS);
};

inline KnownBits operator&(KnownBits LHS, const KnownBits &RHS) {
  LHS &= RHS;
  return LHS;
}

inline KnownBits operator&(const KnownBits &LHS, KnownBits &&RHS) {
  RHS &= LHS;
  return std::move(RHS);
}

inline KnownBits operator|(KnownBits LHS, const KnownBits &RHS) {
  LHS |= RHS;
  return LHS;
}

inline KnownBits operator|(const KnownBits &LHS, KnownBits &&RHS) {
  RHS |= LHS;
  return std::move(RHS);
}

inline KnownBits operator^(KnownBits LHS, const KnownBits &RHS) {
  LHS ^= RHS;
  return LHS;
}

inline KnownBits operator^(const KnownBits &LHS, KnownBits &&RHS) {
  RHS ^= LHS;
  return std::move(RHS);
}

inline KnownBits KnownBits::flipSignBit(const KnownBits &Val) {
  unsigned SignBitPosition = Val.getBitWidth() - 1;
  APInt Zero = Val.Zero;
  APInt One = Val.One;
  Zero.setBitVal(SignBitPosition, Val.One[SignBitPosition]);
  One.setBitVal(SignBitPosition, Val.Zero[SignBitPosition]);
  return KnownBits(Zero, One);
}

static KnownBits computeForAddCarryImpl(const KnownBits &LHS,
                                        const KnownBits &RHS, bool CarryZero,
                                        bool CarryOne) {

  APInt PossibleSumZero = LHS.getMaxValue() + RHS.getMaxValue() + !CarryZero;
  APInt PossibleSumOne = LHS.getMinValue() + RHS.getMinValue() + CarryOne;
  APInt CarryKnownZero = ~(PossibleSumZero ^ LHS.Zero ^ RHS.Zero);
  APInt CarryKnownOne = PossibleSumOne ^ LHS.One ^ RHS.One;
  APInt LHSKnownUnion = LHS.Zero | LHS.One;
  APInt RHSKnownUnion = RHS.Zero | RHS.One;
  APInt CarryKnownUnion = std::move(CarryKnownZero) | CarryKnownOne;
  APInt Known = std::move(LHSKnownUnion) & RHSKnownUnion & CarryKnownUnion;
  KnownBits KnownOut;
  KnownOut.Zero = ~std::move(PossibleSumZero) & Known;
  KnownOut.One = std::move(PossibleSumOne) & Known;
  return KnownOut;
}

inline KnownBits KnownBits::computeForAddCarry(const KnownBits &LHS,
                                               const KnownBits &RHS,
                                               const KnownBits &Carry) {
  assert(Carry.getBitWidth() == 1 && "Carry must be 1-bit");
  return computeForAddCarryImpl(LHS, RHS, Carry.Zero.getBoolValue(),
                                Carry.One.getBoolValue());
}

inline KnownBits KnownBits::computeForAddSub(bool Add, bool NSW, bool NUW,
                                             const KnownBits &LHS,
                                             const KnownBits &RHS) {
  unsigned BitWidth = LHS.getBitWidth();
  KnownBits KnownOut(BitWidth);
  if (LHS.isUnknown() && RHS.isUnknown())
    return KnownOut;

  if (!LHS.isUnknown() && !RHS.isUnknown()) {
    if (Add) {
      KnownOut = computeForAddCarryImpl(LHS, RHS, /*CarryZero=*/true,
                                        /*CarryOne=*/false);
    } else {
      KnownBits NotRHS = RHS;
      std::swap(NotRHS.Zero, NotRHS.One);
      KnownOut = computeForAddCarryImpl(LHS, NotRHS, /*CarryZero=*/false,
                                        /*CarryOne=*/true);
    }
  }

  if (NUW) {
    if (Add) {
      APInt MinVal = LHS.getMinValue().uadd_sat(RHS.getMinValue());
      if (NSW) {
        unsigned NumBits = MinVal.trunc(BitWidth - 1).countl_one();
        KnownOut.One.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      }
      KnownOut.One.setHighBits(MinVal.countl_one());
    } else {
      APInt MaxVal = LHS.getMaxValue().usub_sat(RHS.getMinValue());
      if (NSW) {
        unsigned NumBits = MaxVal.trunc(BitWidth - 1).countl_zero();
        KnownOut.Zero.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      }
      KnownOut.Zero.setHighBits(MaxVal.countl_zero());
    }
  }

  if (NSW) {
    APInt MinVal;
    APInt MaxVal;
    if (Add) {
      MinVal = LHS.getSignedMinValue().sadd_sat(RHS.getSignedMinValue());
      MaxVal = LHS.getSignedMaxValue().sadd_sat(RHS.getSignedMaxValue());
    } else {
      MinVal = LHS.getSignedMinValue().ssub_sat(RHS.getSignedMaxValue());
      MaxVal = LHS.getSignedMaxValue().ssub_sat(RHS.getSignedMinValue());
    }
    if (MinVal.isNonNegative()) {
      unsigned NumBits = MinVal.trunc(BitWidth - 1).countl_one();
      KnownOut.One.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      KnownOut.Zero.setSignBit();
    }
    if (MaxVal.isNegative()) {
      unsigned NumBits = MaxVal.trunc(BitWidth - 1).countl_zero();
      KnownOut.Zero.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      KnownOut.One.setSignBit();
    }
  }

  if (KnownOut.hasConflict())
    KnownOut.setAllZero();
  return KnownOut;
}

inline KnownBits KnownBits::computeForSubBorrow(const KnownBits &LHS,
                                                KnownBits RHS,
                                                const KnownBits &Borrow) {
  assert(Borrow.getBitWidth() == 1 && "Borrow must be 1-bit");

  std::swap(RHS.Zero, RHS.One);
  return computeForAddCarryImpl(LHS, RHS,
                                /*CarryZero=*/Borrow.One.getBoolValue(),
                                /*CarryOne=*/Borrow.Zero.getBoolValue());
}

static unsigned getMaxShiftAmount(const APInt &MaxValue, unsigned BitWidth) {
  if (knownbits_detail::isPowerOf2_32(BitWidth))
    return static_cast<unsigned>(MaxValue.extractBitsAsZExtValue(
        knownbits_detail::Log2_32(BitWidth), 0));
  // This is only an approximate upper bound.
  return static_cast<unsigned>(MaxValue.getLimitedValue(BitWidth - 1));
}

inline KnownBits KnownBits::shl(const KnownBits &LHS, const KnownBits &RHS,
                                bool NUW, bool NSW, bool ShAmtNonZero) {
  unsigned BitWidth = LHS.getBitWidth();
  auto ShiftByConst = [&](const KnownBits &LHS, unsigned ShiftAmt) {
    KnownBits Known;
    bool ShiftedOutZero, ShiftedOutOne;
    Known.Zero = LHS.Zero.ushl_ov(ShiftAmt, ShiftedOutZero);
    Known.Zero.setLowBits(ShiftAmt);
    Known.One = LHS.One.ushl_ov(ShiftAmt, ShiftedOutOne);

    // All cases returning poison have been handled by MaxShiftAmount already.
    if (NSW) {
      if (NUW && ShiftAmt != 0)
        // NUW means we can assume anything shifted out was a zero.
        ShiftedOutZero = true;

      if (ShiftedOutZero)
        Known.makeNonNegative();
      else if (ShiftedOutOne)
        Known.makeNegative();
    }
    return Known;
  };

  // Fast path for a common case when LHS is completely unknown.
  KnownBits Known(BitWidth);
  unsigned MinShiftAmount =
      static_cast<unsigned>(RHS.getMinValue().getLimitedValue(BitWidth));
  if (MinShiftAmount == 0 && ShAmtNonZero)
    MinShiftAmount = 1;
  if (LHS.isUnknown()) {
    Known.Zero.setLowBits(MinShiftAmount);
    if (NUW && NSW && MinShiftAmount != 0)
      Known.makeNonNegative();
    return Known;
  }

  // Determine maximum shift amount, taking NUW/NSW flags into account.
  APInt MaxValue = RHS.getMaxValue();
  unsigned MaxShiftAmount = getMaxShiftAmount(MaxValue, BitWidth);
  if (NUW && NSW)
    MaxShiftAmount = std::min(MaxShiftAmount, LHS.countMaxLeadingZeros() - 1);
  if (NUW)
    MaxShiftAmount = std::min(MaxShiftAmount, LHS.countMaxLeadingZeros());
  if (NSW)
    MaxShiftAmount = std::min(
        MaxShiftAmount,
        std::max(LHS.countMaxLeadingZeros(), LHS.countMaxLeadingOnes()) - 1);

  // Fast path for common case where the shift amount is unknown.
  if (MinShiftAmount == 0 && MaxShiftAmount == BitWidth - 1 &&
      knownbits_detail::isPowerOf2_32(BitWidth)) {
    Known.Zero.setLowBits(LHS.countMinTrailingZeros());
    if (LHS.isAllOnes())
      Known.One.setSignBit();
    if (NSW) {
      if (LHS.isNonNegative())
        Known.makeNonNegative();
      if (LHS.isNegative())
        Known.makeNegative();
    }
    return Known;
  }

  // Find the common bits from all possible shifts.
  unsigned ShiftAmtZeroMask =
      static_cast<unsigned>(RHS.Zero.zextOrTrunc(32).getZExtValue());
  unsigned ShiftAmtOneMask =
      static_cast<unsigned>(RHS.One.zextOrTrunc(32).getZExtValue());
  Known.setAllConflict();
  for (unsigned ShiftAmt = MinShiftAmount; ShiftAmt <= MaxShiftAmount;
       ++ShiftAmt) {
    // Skip if the shift amount is impossible.
    if ((ShiftAmtZeroMask & ShiftAmt) != 0 ||
        (ShiftAmtOneMask | ShiftAmt) != ShiftAmt)
      continue;
    Known = Known.intersectWith(ShiftByConst(LHS, ShiftAmt));
    if (Known.isUnknown())
      break;
  }

  // All shift amounts may result in poison.
  if (Known.hasConflict())
    Known.setAllZero();
  return Known;
}

inline KnownBits KnownBits::lshr(const KnownBits &LHS, const KnownBits &RHS,
                                 bool ShAmtNonZero, bool Exact) {
  unsigned BitWidth = LHS.getBitWidth();
  auto ShiftByConst = [&](const KnownBits &LHS, unsigned ShiftAmt) {
    KnownBits Known = LHS;
    Known >>= ShiftAmt;
    // High bits are known zero.
    Known.Zero.setHighBits(ShiftAmt);
    return Known;
  };

  // Fast path for a common case when LHS is completely unknown.
  KnownBits Known(BitWidth);
  unsigned MinShiftAmount =
      static_cast<unsigned>(RHS.getMinValue().getLimitedValue(BitWidth));
  if (MinShiftAmount == 0 && ShAmtNonZero)
    MinShiftAmount = 1;
  if (LHS.isUnknown()) {
    Known.Zero.setHighBits(MinShiftAmount);
    return Known;
  }

  // Find the common bits from all possible shifts.
  APInt MaxValue = RHS.getMaxValue();
  unsigned MaxShiftAmount = getMaxShiftAmount(MaxValue, BitWidth);

  // If exact, bound MaxShiftAmount to first known 1 in LHS.
  if (Exact) {
    unsigned FirstOne = LHS.countMaxTrailingZeros();
    if (FirstOne < MinShiftAmount) {
      // Always poison. Return zero because we don't like returning conflict.
      Known.setAllZero();
      return Known;
    }
    MaxShiftAmount = std::min(MaxShiftAmount, FirstOne);
  }

  unsigned ShiftAmtZeroMask =
      static_cast<unsigned>(RHS.Zero.zextOrTrunc(32).getZExtValue());
  unsigned ShiftAmtOneMask =
      static_cast<unsigned>(RHS.One.zextOrTrunc(32).getZExtValue());
  Known.setAllConflict();
  for (unsigned ShiftAmt = MinShiftAmount; ShiftAmt <= MaxShiftAmount;
       ++ShiftAmt) {
    // Skip if the shift amount is impossible.
    if ((ShiftAmtZeroMask & ShiftAmt) != 0 ||
        (ShiftAmtOneMask | ShiftAmt) != ShiftAmt)
      continue;
    Known = Known.intersectWith(ShiftByConst(LHS, ShiftAmt));
    if (Known.isUnknown())
      break;
  }

  // All shift amounts may result in poison.
  if (Known.hasConflict())
    Known.setAllZero();
  return Known;
}

inline KnownBits KnownBits::ashr(const KnownBits &LHS, const KnownBits &RHS,
                                 bool ShAmtNonZero, bool Exact) {
  unsigned BitWidth = LHS.getBitWidth();
  auto ShiftByConst = [&](const KnownBits &LHS, unsigned ShiftAmt) {
    KnownBits Known = LHS;
    Known.Zero.ashrInPlace(ShiftAmt);
    Known.One.ashrInPlace(ShiftAmt);
    return Known;
  };

  // Fast path for a common case when LHS is completely unknown.
  KnownBits Known(BitWidth);
  unsigned MinShiftAmount =
      static_cast<unsigned>(RHS.getMinValue().getLimitedValue(BitWidth));
  if (MinShiftAmount == 0 && ShAmtNonZero)
    MinShiftAmount = 1;
  if (LHS.isUnknown()) {
    if (MinShiftAmount == BitWidth) {
      // Always poison. Return zero because we don't like returning conflict.
      Known.setAllZero();
      return Known;
    }
    return Known;
  }

  // Find the common bits from all possible shifts.
  APInt MaxValue = RHS.getMaxValue();
  unsigned MaxShiftAmount = getMaxShiftAmount(MaxValue, BitWidth);

  // If exact, bound MaxShiftAmount to first known 1 in LHS.
  if (Exact) {
    unsigned FirstOne = LHS.countMaxTrailingZeros();
    if (FirstOne < MinShiftAmount) {
      // Always poison. Return zero because we don't like returning conflict.
      Known.setAllZero();
      return Known;
    }
    MaxShiftAmount = std::min(MaxShiftAmount, FirstOne);
  }

  unsigned ShiftAmtZeroMask =
      static_cast<unsigned>(RHS.Zero.zextOrTrunc(32).getZExtValue());
  unsigned ShiftAmtOneMask =
      static_cast<unsigned>(RHS.One.zextOrTrunc(32).getZExtValue());
  Known.setAllConflict();
  for (unsigned ShiftAmt = MinShiftAmount; ShiftAmt <= MaxShiftAmount;
       ++ShiftAmt) {
    // Skip if the shift amount is impossible.
    if ((ShiftAmtZeroMask & ShiftAmt) != 0 ||
        (ShiftAmtOneMask | ShiftAmt) != ShiftAmt)
      continue;
    Known = Known.intersectWith(ShiftByConst(LHS, ShiftAmt));
    if (Known.isUnknown())
      break;
  }

  // All shift amounts may result in poison.
  if (Known.hasConflict())
    Known.setAllZero();
  return Known;
}

inline KnownBits KnownBits::mul(const KnownBits &LHS, const KnownBits &RHS,
                                bool NoUndefSelfMultiply) {
  unsigned BitWidth = LHS.getBitWidth();
  assert(BitWidth == RHS.getBitWidth() && "Operand mismatch");
  assert((!NoUndefSelfMultiply || LHS == RHS) &&
         "Self multiplication knownbits mismatch");
  APInt UMaxLHS = LHS.getMaxValue();
  APInt UMaxRHS = RHS.getMaxValue();
  bool HasOverflow;
  APInt UMaxResult = UMaxLHS.umul_ov(UMaxRHS, HasOverflow);
  unsigned LeadZ = HasOverflow ? 0 : UMaxResult.countl_zero();

  const APInt &Bottom0 = LHS.One;
  const APInt &Bottom1 = RHS.One;
  unsigned TrailBitsKnown0 = (LHS.Zero | LHS.One).countr_one();
  unsigned TrailBitsKnown1 = (RHS.Zero | RHS.One).countr_one();
  unsigned TrailZero0 = LHS.countMinTrailingZeros();
  unsigned TrailZero1 = RHS.countMinTrailingZeros();
  unsigned TrailZ = TrailZero0 + TrailZero1;
  unsigned SmallestOperand =
      std::min(TrailBitsKnown0 - TrailZero0, TrailBitsKnown1 - TrailZero1);
  unsigned ResultBitsKnown = std::min(SmallestOperand + TrailZ, BitWidth);

  APInt BottomKnown =
      Bottom0.getLoBits(TrailBitsKnown0) * Bottom1.getLoBits(TrailBitsKnown1);

  KnownBits Res(BitWidth);
  Res.Zero.setHighBits(LeadZ);
  Res.Zero |= (~BottomKnown).getLoBits(ResultBitsKnown);
  Res.One = BottomKnown.getLoBits(ResultBitsKnown);

  if (NoUndefSelfMultiply) {
    // If X has at least TZ trailing zeroes, then bit (2 * TZ + 1) must be zero.
    unsigned TwoTZP1 = 2 * TrailZero0 + 1;
    if (TwoTZP1 < BitWidth)
      Res.Zero.setBit(TwoTZP1);

    // If X has exactly TZ trailing zeros, then bit (2 * TZ + 2) must also be
    // zero.
    if (TrailZero0 < BitWidth && LHS.One[TrailZero0]) {
      unsigned TwoTZP2 = TwoTZP1 + 1;
      if (TwoTZP2 < BitWidth)
        Res.Zero.setBit(TwoTZP2);
    }
  }

  return Res;
}

static KnownBits divComputeLowBit(KnownBits Known, const KnownBits &LHS,
                                  const KnownBits &RHS, bool Exact) {

  if (!Exact)
    return Known;

  if (LHS.One[0])
    Known.One.setBit(0);

  int MinTZ = static_cast<int>(LHS.countMinTrailingZeros()) -
              static_cast<int>(RHS.countMaxTrailingZeros());
  int MaxTZ = static_cast<int>(LHS.countMaxTrailingZeros()) -
              static_cast<int>(RHS.countMinTrailingZeros());
  if (MinTZ >= 0) {
    // Result has at least MinTZ trailing zeros.
    Known.Zero.setLowBits(static_cast<unsigned>(MinTZ));
    if (MinTZ == MaxTZ) {
      // Result has exactly MinTZ trailing zeros.
      Known.One.setBit(static_cast<unsigned>(MinTZ));
    }
  } else if (MaxTZ < 0) {
    // Poison Result
    Known.setAllZero();
  }

  // In the KnownBits exhaustive tests, we have poison inputs for exact values
  // a LOT. If we have a conflict, just return all zeros.
  if (Known.hasConflict())
    Known.setAllZero();

  return Known;
}

inline KnownBits KnownBits::sdiv(const KnownBits &LHS, const KnownBits &RHS,
                                 bool Exact) {
  // Equivalent of `udiv`. We must have caught this before it was folded.
  if (LHS.isNonNegative() && RHS.isNonNegative())
    return udiv(LHS, RHS, Exact);

  unsigned BitWidth = LHS.getBitWidth();
  KnownBits Known(BitWidth);

  if (LHS.isZero() || RHS.isZero()) {
    // Result is either known Zero or UB. Return Zero either way.
    // Checking this earlier saves us a lot of special cases later on.
    Known.setAllZero();
    return Known;
  }

  std::optional<APInt> Res;
  if (LHS.isNegative() && RHS.isNegative()) {
    // Result non-negative.
    APInt Denom = RHS.getSignedMaxValue();
    APInt Num = LHS.getSignedMinValue();
    // INT_MIN/-1 would be a poison result (impossible). Estimate the division
    // as signed max (we will only set sign bit in the result).
    Res = (Num.isMinSignedValue() && Denom.isAllOnes())
              ? APInt::getSignedMaxValue(BitWidth)
              : Num.sdiv(Denom);
  } else if (LHS.isNegative() && RHS.isNonNegative()) {
    // Result is negative if Exact OR -LHS u>= RHS.
    if (Exact || (-LHS.getSignedMaxValue()).uge(RHS.getSignedMaxValue())) {
      APInt Denom = RHS.getSignedMinValue();
      APInt Num = LHS.getSignedMinValue();
      Res = Denom.isZero() ? Num : Num.sdiv(Denom);
    }
  } else if (LHS.isStrictlyPositive() && RHS.isNegative()) {
    // Result is negative if Exact OR LHS u>= -RHS.
    if (Exact || LHS.getSignedMinValue().uge(-RHS.getSignedMinValue())) {
      APInt Denom = RHS.getSignedMaxValue();
      APInt Num = LHS.getSignedMaxValue();
      Res = Num.sdiv(Denom);
    }
  }

  if (Res) {
    if (Res->isNonNegative()) {
      unsigned LeadZ = Res->countLeadingZeros();
      Known.Zero.setHighBits(LeadZ);
    } else {
      unsigned LeadO = Res->countLeadingOnes();
      Known.One.setHighBits(LeadO);
    }
  }

  Known = divComputeLowBit(Known, LHS, RHS, Exact);
  return Known;
}

inline KnownBits KnownBits::udiv(const KnownBits &LHS, const KnownBits &RHS,
                                 bool Exact) {
  unsigned BitWidth = LHS.getBitWidth();
  KnownBits Known(BitWidth);

  if (LHS.isZero() || RHS.isZero()) {
    Known.setAllZero();
    return Known;
  }

  APInt MinDenom = RHS.getMinValue();
  APInt MaxNum = LHS.getMaxValue();
  APInt MaxRes = MinDenom.isZero() ? MaxNum : MaxNum.udiv(MinDenom);

  unsigned LeadZ = MaxRes.countLeadingZeros();

  Known.Zero.setHighBits(LeadZ);
  Known = divComputeLowBit(Known, LHS, RHS, Exact);

  return Known;
}

inline KnownBits KnownBits::remGetLowBits(const KnownBits &LHS,
                                          const KnownBits &RHS) {
  unsigned BitWidth = LHS.getBitWidth();
  if (!RHS.isZero() && RHS.Zero[0]) {
    unsigned RHSZeros = RHS.countMinTrailingZeros();
    APInt Mask = APInt::getLowBitsSet(BitWidth, RHSZeros);
    APInt OnesMask = LHS.One & Mask;
    APInt ZerosMask = LHS.Zero & Mask;
    return KnownBits(ZerosMask, OnesMask);
  }
  return KnownBits(BitWidth);
}

inline KnownBits KnownBits::urem(const KnownBits &LHS, const KnownBits &RHS) {
  KnownBits Known = remGetLowBits(LHS, RHS);
  if (RHS.isConstant() && RHS.getConstant().isPowerOf2()) {
    APInt HighBits = ~(RHS.getConstant() - 1);
    Known.Zero |= HighBits;
    return Known;
  }

  uint32_t Leaders =
      std::max(LHS.countMinLeadingZeros(), RHS.countMinLeadingZeros());
  Known.Zero.setHighBits(Leaders);
  return Known;
}

inline KnownBits KnownBits::srem(const KnownBits &LHS, const KnownBits &RHS) {
  KnownBits Known = remGetLowBits(LHS, RHS);
  if (RHS.isConstant() && RHS.getConstant().isPowerOf2()) {
    APInt LowBits = RHS.getConstant() - 1;
    if (LHS.isNonNegative() || LowBits.isSubsetOf(LHS.Zero))
      Known.Zero |= ~LowBits;

    if (LHS.isNegative() && LowBits.intersects(LHS.One))
      Known.One |= ~LowBits;
    return Known;
  }

  if (LHS.isNegative() && Known.isNonZero())
    Known.One.setHighBits(
        std::max(LHS.countMinLeadingOnes(), RHS.countMinSignBits()));
  else if (LHS.isNonNegative())
    Known.Zero.setHighBits(
        std::max(LHS.countMinLeadingZeros(), RHS.countMinSignBits()));
  return Known;
}

inline std::optional<bool> KnownBits::sgt(const KnownBits &LHS,
                                          const KnownBits &RHS) {
  // LHS >s RHS -> false if smax(LHS) <= smax(RHS)
  if (LHS.getSignedMaxValue().sle(RHS.getSignedMinValue()))
    return std::optional<bool>(false);
  // LHS >s RHS -> true if smin(LHS) > smax(RHS)
  if (LHS.getSignedMinValue().sgt(RHS.getSignedMaxValue()))
    return std::optional<bool>(true);
  return std::nullopt;
}

// Taken and modified from ValueTracking.cpp
inline void computeKnownBitsMul(bool NSW, bool NUW, KnownBits &Known,
                                KnownBits &Known2) {
  bool isKnownNegative = false;
  bool isKnownNonNegative = false;
  // If the multiplication is known not to overflow, compute the sign bit.
  if (NSW) {
    bool isKnownNonNegativeOp1 = Known.isNonNegative();
    bool isKnownNonNegativeOp0 = Known2.isNonNegative();
    bool isKnownNegativeOp1 = Known.isNegative();
    bool isKnownNegativeOp0 = Known2.isNegative();
    // The product of two numbers with the same sign is non-negative.
    isKnownNonNegative = (isKnownNegativeOp1 && isKnownNegativeOp0) ||
                         (isKnownNonNegativeOp1 && isKnownNonNegativeOp0);
    if (!isKnownNonNegative && NUW) {
      // mul nuw nsw with a factor > 1 is non-negative.
      KnownBits One = KnownBits::makeConstant(APInt(Known.getBitWidth(), 1));
      isKnownNonNegative = KnownBits::sgt(Known, One).value_or(false) ||
                           KnownBits::sgt(Known2, One).value_or(false);
    }

    // The product of a negative number and a non-negative number is either
    // negative or zero.
    if (!isKnownNonNegative)
      isKnownNegative =
          (isKnownNegativeOp1 && isKnownNonNegativeOp0 && Known2.isNonZero()) ||
          (isKnownNegativeOp0 && isKnownNonNegativeOp1 && Known.isNonZero());
  }

  Known = KnownBits::mul(Known, Known2, false);

  // Only make use of no-wrap flags if we failed to compute the sign bit
  // directly.  This matters if the multiplication always overflows, in
  // which case we prefer to follow the result of the direct computation,
  // though as the program is invoking undefined behaviour we can choose
  // whatever we like here.
  if (isKnownNonNegative && !Known.isNegative())
    Known.makeNonNegative();
  else if (isKnownNegative && !Known.isNonNegative())
    Known.makeNegative();
}

inline KnownBits kb_mul_wrapper(const KnownBits &lhs, const KnownBits &rhs,
                                bool nsw, bool nuw) {

  KnownBits lhs_copy = lhs;
  KnownBits rhs_copy = rhs;
  llvm::computeKnownBitsMul(nsw, nuw, lhs_copy, rhs_copy);

  return lhs_copy;
}

} // end namespace llvm

#endif
