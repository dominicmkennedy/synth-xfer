#ifndef LLVM_KNOWNBITS_STANDALONE_H
#define LLVM_KNOWNBITS_STANDALONE_H

#include "APInt.h"
#include <optional>

namespace llvm {
namespace knownbits_detail {

static inline bool isPowerOf2_32(uint32_t x) {
  return x && ((x & (x - 1)) == 0);
}

static inline unsigned Log2_32(uint32_t x) {
  return 31u - static_cast<unsigned>(__builtin_clz(x));
}

static inline unsigned Log2_32_Ceil(uint32_t x) {
  if (x <= 1)
    return 0;
  return 32u - static_cast<unsigned>(__builtin_clz(x - 1));
}

} // namespace knownbits_detail

// Struct for tracking the known zeros and ones of a value.
struct KnownBits {
  APInt Zero;
  APInt One;

private:
  // Internal constructor for creating a KnownBits from two APInts.
  KnownBits(APInt Zero, APInt One)
      : Zero(std::move(Zero)), One(std::move(One)) {}

  // Flip the range of values: [-0x80000000, 0x7FFFFFFF] <-> [0, 0xFFFFFFFF]
  static KnownBits flipSignBit(const KnownBits &Val);

public:
  // Default construct Zero and One.
  KnownBits() = default;

  /// Create a known bits object of BitWidth bits initialized to unknown.
  KnownBits(unsigned BitWidth) : Zero(BitWidth, 0), One(BitWidth, 0) {}

  /// Get the bit width of this value.
  unsigned getBitWidth() const {
    assert(Zero.getBitWidth() == One.getBitWidth() &&
           "Zero and One should have the same width!");
    return Zero.getBitWidth();
  }

  /// Returns true if there is conflicting information.
  bool hasConflict() const { return Zero.intersects(One); }

  /// Returns true if we know the value of all bits.
  bool isConstant() const {
    return Zero.popcount() + One.popcount() == getBitWidth();
  }

  /// Returns the value when all bits have a known value. This just returns One
  /// with a protective assertion.
  const APInt &getConstant() const {
    assert(isConstant() && "Can only get value when all bits are known");
    return One;
  }

  /// Returns true if we don't know any bits.
  bool isUnknown() const { return Zero.isZero() && One.isZero(); }

  /// Returns true if we don't know the sign bit.
  bool isSignUnknown() const {
    return !Zero.isSignBitSet() && !One.isSignBitSet();
  }

  /// Resets the known state of all bits.
  void resetAll() {
    Zero.clearAllBits();
    One.clearAllBits();
  }

  /// Returns true if value is all zero.
  bool isZero() const { return Zero.isAllOnes(); }

  /// Returns true if value is all one bits.
  bool isAllOnes() const { return One.isAllOnes(); }

  /// Make all bits known to be zero and discard any previous information.
  void setAllZero() {
    Zero.setAllBits();
    One.clearAllBits();
  }

  /// Make all bits known to be one and discard any previous information.
  void setAllOnes() {
    Zero.clearAllBits();
    One.setAllBits();
  }

  /// Make all bits known to be both zero and one. Useful before a loop that
  /// calls intersectWith.
  void setAllConflict() {
    Zero.setAllBits();
    One.setAllBits();
  }

  /// Returns true if this value is known to be negative.
  bool isNegative() const { return One.isSignBitSet(); }

  /// Returns true if this value is known to be non-negative.
  bool isNonNegative() const { return Zero.isSignBitSet(); }

  /// Returns true if this value is known to be non-zero.
  bool isNonZero() const { return !One.isZero(); }

  /// Returns true if this value is known to be positive.
  bool isStrictlyPositive() const {
    return Zero.isSignBitSet() && !One.isZero();
  }

  /// Returns true if this value is known to be non-positive.
  bool isNonPositive() const { return getSignedMaxValue().isNonPositive(); }

  /// Make this value negative.
  void makeNegative() { One.setSignBit(); }

  /// Make this value non-negative.
  void makeNonNegative() { Zero.setSignBit(); }

  /// Return the minimal unsigned value possible given these KnownBits.
  APInt getMinValue() const {
    // Assume that all bits that aren't known-ones are zeros.
    return One;
  }

  /// Return the minimal signed value possible given these KnownBits.
  APInt getSignedMinValue() const {
    // Assume that all bits that aren't known-ones are zeros.
    APInt Min = One;
    // Sign bit is unknown.
    if (Zero.isSignBitClear())
      Min.setSignBit();
    return Min;
  }

  /// Return the maximal unsigned value possible given these KnownBits.
  APInt getMaxValue() const {
    // Assume that all bits that aren't known-zeros are ones.
    return ~Zero;
  }

  /// Return the maximal signed value possible given these KnownBits.
  APInt getSignedMaxValue() const {
    // Assume that all bits that aren't known-zeros are ones.
    APInt Max = ~Zero;
    // Sign bit is unknown.
    if (One.isSignBitClear())
      Max.clearSignBit();
    return Max;
  }

  /// Return known bits for a truncation of the value we're tracking.
  KnownBits trunc(unsigned BitWidth) const {
    return KnownBits(Zero.trunc(BitWidth), One.trunc(BitWidth));
  }

  /// Return known bits for an "any" extension of the value we're tracking,
  /// where we don't know anything about the extended bits.
  KnownBits anyext(unsigned BitWidth) const {
    return KnownBits(Zero.zext(BitWidth), One.zext(BitWidth));
  }

  /// Return known bits for a zero extension of the value we're tracking.
  KnownBits zext(unsigned BitWidth) const {
    unsigned OldBitWidth = getBitWidth();
    APInt NewZero = Zero.zext(BitWidth);
    NewZero.setBitsFrom(OldBitWidth);
    return KnownBits(NewZero, One.zext(BitWidth));
  }

  /// Return known bits for a sign extension of the value we're tracking.
  KnownBits sext(unsigned BitWidth) const {
    return KnownBits(Zero.sext(BitWidth), One.sext(BitWidth));
  }

  /// Return known bits for an "any" extension or truncation of the value we're
  /// tracking.
  KnownBits anyextOrTrunc(unsigned BitWidth) const {
    if (BitWidth > getBitWidth())
      return anyext(BitWidth);
    if (BitWidth < getBitWidth())
      return trunc(BitWidth);
    return *this;
  }

  /// Return known bits for a zero extension or truncation of the value we're
  /// tracking.
  KnownBits zextOrTrunc(unsigned BitWidth) const {
    if (BitWidth > getBitWidth())
      return zext(BitWidth);
    if (BitWidth < getBitWidth())
      return trunc(BitWidth);
    return *this;
  }

  /// Return known bits for a sign extension or truncation of the value we're
  /// tracking.
  KnownBits sextOrTrunc(unsigned BitWidth) const {
    if (BitWidth > getBitWidth())
      return sext(BitWidth);
    if (BitWidth < getBitWidth())
      return trunc(BitWidth);
    return *this;
  }

  /// Return known bits for a in-register sign extension of the value we're
  /// tracking.
  KnownBits sextInReg(unsigned SrcBitWidth) const;

  /// Insert the bits from a smaller known bits starting at bitPosition.
  void insertBits(const KnownBits &SubBits, unsigned BitPosition) {
    Zero.insertBits(SubBits.Zero, BitPosition);
    One.insertBits(SubBits.One, BitPosition);
  }

  /// Return KnownBits based on this, but updated given that the underlying
  /// value is known to be greater than or equal to Val.
  KnownBits makeGE(const APInt &Val) const;

  /// Returns the minimum number of trailing zero bits.
  unsigned countMinTrailingZeros() const { return Zero.countr_one(); }

  /// Returns the minimum number of trailing one bits.
  unsigned countMinTrailingOnes() const { return One.countr_one(); }

  /// Returns the minimum number of leading zero bits.
  unsigned countMinLeadingZeros() const { return Zero.countl_one(); }

  /// Returns the minimum number of leading one bits.
  unsigned countMinLeadingOnes() const { return One.countl_one(); }

  /// Returns the number of times the sign bit is replicated into the other
  /// bits.
  unsigned countMinSignBits() const {
    if (isNonNegative())
      return countMinLeadingZeros();
    if (isNegative())
      return countMinLeadingOnes();
    // Every value has at least 1 sign bit.
    return 1;
  }

  /// Returns the maximum number of bits needed to represent all possible
  /// signed values with these known bits. This is the inverse of the minimum
  /// number of known sign bits. Examples for bitwidth 5:
  /// 110?? --> 4
  /// 0000? --> 2
  unsigned countMaxSignificantBits() const {
    return getBitWidth() - countMinSignBits() + 1;
  }

  /// Returns the maximum number of trailing zero bits possible.
  unsigned countMaxTrailingZeros() const { return One.countr_zero(); }

  /// Returns the maximum number of trailing one bits possible.
  unsigned countMaxTrailingOnes() const { return Zero.countr_zero(); }

  /// Returns the maximum number of leading zero bits possible.
  unsigned countMaxLeadingZeros() const { return One.countl_zero(); }

  /// Returns the maximum number of leading one bits possible.
  unsigned countMaxLeadingOnes() const { return Zero.countl_zero(); }

  /// Returns the number of bits known to be one.
  unsigned countMinPopulation() const { return One.popcount(); }

  /// Returns the maximum number of bits that could be one.
  unsigned countMaxPopulation() const {
    return getBitWidth() - Zero.popcount();
  }

  /// Returns the maximum number of bits needed to represent all possible
  /// unsigned values with these known bits. This is the inverse of the
  /// minimum number of leading zeros.
  unsigned countMaxActiveBits() const {
    return getBitWidth() - countMinLeadingZeros();
  }

  /// Create known bits from a known constant.
  static KnownBits makeConstant(const APInt &C) { return KnownBits(~C, C); }

  /// Returns KnownBits information that is known to be true for both this and
  /// RHS.
  ///
  /// When an operation is known to return one of its operands, this can be used
  /// to combine information about the known bits of the operands to get the
  /// information that must be true about the result.
  KnownBits intersectWith(const KnownBits &RHS) const {
    return KnownBits(Zero & RHS.Zero, One & RHS.One);
  }

  /// Returns KnownBits information that is known to be true for either this or
  /// RHS or both.
  ///
  /// This can be used to combine different sources of information about the
  /// known bits of a single value, e.g. information about the low bits and the
  /// high bits of the result of a multiplication.
  KnownBits unionWith(const KnownBits &RHS) const {
    return KnownBits(Zero | RHS.Zero, One | RHS.One);
  }

  /// Return true if LHS and RHS have no common bits set.
  static bool haveNoCommonBitsSet(const KnownBits &LHS, const KnownBits &RHS) {
    return (LHS.Zero | RHS.Zero).isAllOnes();
  }

  /// Compute known bits resulting from adding LHS, RHS and a 1-bit Carry.
  static KnownBits computeForAddCarry(const KnownBits &LHS,
                                      const KnownBits &RHS,
                                      const KnownBits &Carry);

  /// Compute known bits resulting from adding LHS and RHS.
  static KnownBits computeForAddSub(bool Add, bool NSW, bool NUW,
                                    const KnownBits &LHS, const KnownBits &RHS);

  /// Compute known bits results from subtracting RHS from LHS with 1-bit
  /// Borrow.
  static KnownBits computeForSubBorrow(const KnownBits &LHS, KnownBits RHS,
                                       const KnownBits &Borrow);

  /// Compute knownbits resulting from addition of LHS and RHS.
  static KnownBits add(const KnownBits &LHS, const KnownBits &RHS,
                       bool NSW = false, bool NUW = false) {
    return computeForAddSub(/*Add=*/true, NSW, NUW, LHS, RHS);
  }

  /// Compute knownbits resulting from subtraction of LHS and RHS.
  static KnownBits sub(const KnownBits &LHS, const KnownBits &RHS,
                       bool NSW = false, bool NUW = false) {
    return computeForAddSub(/*Add=*/false, NSW, NUW, LHS, RHS);
  }

  /// Compute known bits resulting from multiplying LHS and RHS.
  static KnownBits mul(const KnownBits &LHS, const KnownBits &RHS,
                       bool NoUndefSelfMultiply = false);

  /// Compute known bits for sdiv(LHS, RHS).
  static KnownBits sdiv(const KnownBits &LHS, const KnownBits &RHS,
                        bool Exact = false);

  /// Compute known bits for udiv(LHS, RHS).
  static KnownBits udiv(const KnownBits &LHS, const KnownBits &RHS,
                        bool Exact = false);

  /// Compute known bits for urem(LHS, RHS).
  static KnownBits urem(const KnownBits &LHS, const KnownBits &RHS);

  /// Compute known bits for srem(LHS, RHS).
  static KnownBits srem(const KnownBits &LHS, const KnownBits &RHS);

  /// Compute known bits for shl(LHS, RHS).
  /// NOTE: RHS (shift amount) bitwidth doesn't need to be the same as LHS.
  static KnownBits shl(const KnownBits &LHS, const KnownBits &RHS,
                       bool NUW = false, bool NSW = false,
                       bool ShAmtNonZero = false);

  /// Compute known bits for lshr(LHS, RHS).
  /// NOTE: RHS (shift amount) bitwidth doesn't need to be the same as LHS.
  static KnownBits lshr(const KnownBits &LHS, const KnownBits &RHS,
                        bool ShAmtNonZero = false, bool Exact = false);

  /// Compute known bits for ashr(LHS, RHS).
  /// NOTE: RHS (shift amount) bitwidth doesn't need to be the same as LHS.
  static KnownBits ashr(const KnownBits &LHS, const KnownBits &RHS,
                        bool ShAmtNonZero = false, bool Exact = false);

  /// Update known bits based on ANDing with RHS.
  KnownBits &operator&=(const KnownBits &RHS);

  /// Update known bits based on ORing with RHS.
  KnownBits &operator|=(const KnownBits &RHS);

  /// Update known bits based on XORing with RHS.
  KnownBits &operator^=(const KnownBits &RHS);

  /// Shift known bits left by ShAmt. Shift in bits are unknown.
  KnownBits &operator<<=(unsigned ShAmt) {
    Zero <<= ShAmt;
    One <<= ShAmt;
    return *this;
  }

  /// Shift known bits right by ShAmt. Shifted in bits are unknown.
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
  // Internal helper for getting the initial KnownBits for an `srem` or `urem`
  // operation with the low-bits set.
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

  // Compute known bits of the carry.
  APInt CarryKnownZero = ~(PossibleSumZero ^ LHS.Zero ^ RHS.Zero);
  APInt CarryKnownOne = PossibleSumOne ^ LHS.One ^ RHS.One;

  // Compute set of known bits (where all three relevant bits are known).
  APInt LHSKnownUnion = LHS.Zero | LHS.One;
  APInt RHSKnownUnion = RHS.Zero | RHS.One;
  APInt CarryKnownUnion = std::move(CarryKnownZero) | CarryKnownOne;
  APInt Known = std::move(LHSKnownUnion) & RHSKnownUnion & CarryKnownUnion;

  // Compute known bits of the result.
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
  // This can be a relatively expensive helper, so optimistically save some
  // work.
  if (LHS.isUnknown() && RHS.isUnknown())
    return KnownOut;

  if (!LHS.isUnknown() && !RHS.isUnknown()) {
    if (Add) {
      // Sum = LHS + RHS + 0
      KnownOut = computeForAddCarryImpl(LHS, RHS, /*CarryZero=*/true,
                                        /*CarryOne=*/false);
    } else {
      // Sum = LHS + ~RHS + 1
      KnownBits NotRHS = RHS;
      std::swap(NotRHS.Zero, NotRHS.One);
      KnownOut = computeForAddCarryImpl(LHS, NotRHS, /*CarryZero=*/false,
                                        /*CarryOne=*/true);
    }
  }

  // Handle add/sub given nsw and/or nuw.
  if (NUW) {
    if (Add) {
      // (add nuw X, Y)
      APInt MinVal = LHS.getMinValue().uadd_sat(RHS.getMinValue());
      // None of the adds can end up overflowing, so min consecutive highbits
      // in minimum possible of X + Y must all remain set.
      if (NSW) {
        unsigned NumBits = MinVal.trunc(BitWidth - 1).countl_one();
        // If we have NSW as well, we also know we can't overflow the signbit so
        // can start counting from 1 bit back.
        KnownOut.One.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      }
      KnownOut.One.setHighBits(MinVal.countl_one());
    } else {
      // (sub nuw X, Y)
      APInt MaxVal = LHS.getMaxValue().usub_sat(RHS.getMinValue());
      // None of the subs can overflow at any point, so any common high bits
      // will subtract away and result in zeros.
      if (NSW) {
        // If we have NSW as well, we also know we can't overflow the signbit so
        // can start counting from 1 bit back.
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
      // (add nsw X, Y)
      MinVal = LHS.getSignedMinValue().sadd_sat(RHS.getSignedMinValue());
      MaxVal = LHS.getSignedMaxValue().sadd_sat(RHS.getSignedMaxValue());
    } else {
      // (sub nsw X, Y)
      MinVal = LHS.getSignedMinValue().ssub_sat(RHS.getSignedMaxValue());
      MaxVal = LHS.getSignedMaxValue().ssub_sat(RHS.getSignedMinValue());
    }
    if (MinVal.isNonNegative()) {
      // If min is non-negative, result will always be non-neg (can't overflow
      // around).
      unsigned NumBits = MinVal.trunc(BitWidth - 1).countl_one();
      KnownOut.One.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      KnownOut.Zero.setSignBit();
    }
    if (MaxVal.isNegative()) {
      // If max is negative, result will always be neg (can't overflow around).
      unsigned NumBits = MaxVal.trunc(BitWidth - 1).countl_zero();
      KnownOut.Zero.setBits(BitWidth - 1 - NumBits, BitWidth - 1);
      KnownOut.One.setSignBit();
    }
  }

  // Just return 0 if the nsw/nuw is violated and we have poison.
  if (KnownOut.hasConflict())
    KnownOut.setAllZero();
  return KnownOut;
}

inline KnownBits KnownBits::computeForSubBorrow(const KnownBits &LHS,
                                                KnownBits RHS,
                                                const KnownBits &Borrow) {
  assert(Borrow.getBitWidth() == 1 && "Borrow must be 1-bit");

  // LHS - RHS = LHS + ~RHS + 1
  // Carry 1 - Borrow in computeForAddCarry
  std::swap(RHS.Zero, RHS.One);
  return computeForAddCarryImpl(LHS, RHS,
                                /*CarryZero=*/Borrow.One.getBoolValue(),
                                /*CarryOne=*/Borrow.Zero.getBoolValue());
}

inline KnownBits KnownBits::sextInReg(unsigned SrcBitWidth) const {
  unsigned BitWidth = getBitWidth();
  assert(0 < SrcBitWidth && SrcBitWidth <= BitWidth &&
         "Illegal sext-in-register");

  if (SrcBitWidth == BitWidth)
    return *this;

  unsigned ExtBits = BitWidth - SrcBitWidth;
  KnownBits Result;
  Result.One = One << ExtBits;
  Result.Zero = Zero << ExtBits;
  Result.One.ashrInPlace(ExtBits);
  Result.Zero.ashrInPlace(ExtBits);
  return Result;
}

inline KnownBits KnownBits::makeGE(const APInt &Val) const {
  // Count the number of leading bit positions where our underlying value is
  // known to be less than or equal to Val.
  unsigned N = (Zero | Val).countl_one();

  // For each of those bit positions, if Val has a 1 in that bit then our
  // underlying value must also have a 1.
  APInt MaskedVal(Val);
  MaskedVal.clearLowBits(getBitWidth() - N);
  return KnownBits(Zero, One | MaskedVal);
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

  // Compute the high known-0 bits by multiplying the unsigned max of each side.
  // Conservatively, M active bits * N active bits results in M + N bits in the
  // result. But if we know a value is a power-of-2 for example, then this
  // computes one more leading zero.
  // TODO: This could be generalized to number of sign bits (negative numbers).
  APInt UMaxLHS = LHS.getMaxValue();
  APInt UMaxRHS = RHS.getMaxValue();

  // For leading zeros in the result to be valid, the unsigned max product must
  // fit in the bitwidth (it must not overflow).
  bool HasOverflow;
  APInt UMaxResult = UMaxLHS.umul_ov(UMaxRHS, HasOverflow);
  unsigned LeadZ = HasOverflow ? 0 : UMaxResult.countl_zero();

  const APInt &Bottom0 = LHS.One;
  const APInt &Bottom1 = RHS.One;

  // How many times we'd be able to divide each argument by 2 (shr by 1).
  // This gives us the number of trailing zeros on the multiplication result.
  unsigned TrailBitsKnown0 = (LHS.Zero | LHS.One).countr_one();
  unsigned TrailBitsKnown1 = (RHS.Zero | RHS.One).countr_one();
  unsigned TrailZero0 = LHS.countMinTrailingZeros();
  unsigned TrailZero1 = RHS.countMinTrailingZeros();
  unsigned TrailZ = TrailZero0 + TrailZero1;

  // Figure out the fewest known-bits operand.
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

  // If LHS is Odd, the result is Odd no matter what.
  // Odd / Odd -> Odd
  // Odd / Even -> Impossible (because its exact division)
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
    // Result is either known Zero or UB. Return Zero either way.
    // Checking this earlier saves us a lot of special cases later on.
    Known.setAllZero();
    return Known;
  }

  // We can figure out the minimum number of upper zero bits by doing
  // MaxNumerator / MinDenominator. If the Numerator gets smaller or Denominator
  // gets larger, the number of upper zero bits increases.
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
    // rem X, Y where Y[0:N] is zero will preserve X[0:N] in the result.
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
    // NB: Low bits set in `remGetLowBits`.
    APInt HighBits = ~(RHS.getConstant() - 1);
    Known.Zero |= HighBits;
    return Known;
  }

  // Since the result is less than or equal to either operand, any leading
  // zero bits in either operand must also exist in the result.
  uint32_t Leaders =
      std::max(LHS.countMinLeadingZeros(), RHS.countMinLeadingZeros());
  Known.Zero.setHighBits(Leaders);
  return Known;
}

inline KnownBits KnownBits::srem(const KnownBits &LHS, const KnownBits &RHS) {
  KnownBits Known = remGetLowBits(LHS, RHS);
  if (RHS.isConstant() && RHS.getConstant().isPowerOf2()) {
    // NB: Low bits are set in `remGetLowBits`.
    APInt LowBits = RHS.getConstant() - 1;
    // If the first operand is non-negative or has all low bits zero, then
    // the upper bits are all zero.
    if (LHS.isNonNegative() || LowBits.isSubsetOf(LHS.Zero))
      Known.Zero |= ~LowBits;

    // If the first operand is negative and not all low bits are zero, then
    // the upper bits are all one.
    if (LHS.isNegative() && LowBits.intersects(LHS.One))
      Known.One |= ~LowBits;
    return Known;
  }

  // The sign bit is the LHS's sign bit, except when the result of the
  // remainder is zero. The magnitude of the result should be less than or
  // equal to the magnitude of either operand.
  if (LHS.isNegative() && Known.isNonZero())
    Known.One.setHighBits(
        std::max(LHS.countMinLeadingOnes(), RHS.countMinSignBits()));
  else if (LHS.isNonNegative())
    Known.Zero.setHighBits(
        std::max(LHS.countMinLeadingZeros(), RHS.countMinSignBits()));
  return Known;
}

inline KnownBits &KnownBits::operator&=(const KnownBits &RHS) {
  // Result bit is 0 if either operand bit is 0.
  Zero |= RHS.Zero;
  // Result bit is 1 if both operand bits are 1.
  One &= RHS.One;
  return *this;
}

inline KnownBits &KnownBits::operator|=(const KnownBits &RHS) {
  // Result bit is 0 if both operand bits are 0.
  Zero &= RHS.Zero;
  // Result bit is 1 if either operand bit is 1.
  One |= RHS.One;
  return *this;
}

inline KnownBits &KnownBits::operator^=(const KnownBits &RHS) {
  // Result bit is 0 if both operand bits are 0 or both are 1.
  APInt Z = (Zero & RHS.Zero) | (One & RHS.One);
  // Result bit is 1 if one operand bit is 0 and the other is 1.
  One = (Zero & RHS.One) | (One & RHS.Zero);
  Zero = std::move(Z);
  return *this;
}

} // end namespace llvm

#endif
