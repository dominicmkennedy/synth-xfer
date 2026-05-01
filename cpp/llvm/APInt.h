// Note: this code was taken from llvm 22.1.0 files:
// llvm-project/llvm/include/llvm/ADT/APInt.h
// llvm-project/llvm/lib/Support/APInt.cpp
// And combinded into a standalone header with codex

#ifndef LLVM_APINT_STANDALONE_H
#define LLVM_APINT_STANDALONE_H

#include <algorithm>
#include <bit>
#include <cassert>
#include <climits>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <optional>
#include <utility>

namespace llvm {

static inline bool isIntN(unsigned N, uint64_t x) {
  if (N == 0)
    return x == 0 || x == UINT64_MAX;
  if (N >= 64)
    return true;
  return static_cast<int64_t>(x) >= -(int64_t(1) << (N - 1)) &&
         static_cast<int64_t>(x) < (int64_t(1) << (N - 1));
}

static inline bool isUIntN(unsigned N, uint64_t x) {
  if (N >= 64)
    return true;
  return (x >> N) == 0;
}

template <typename T> static inline T maskTrailingOnes(unsigned N) {
  if (N == 0)
    return 0;
  constexpr unsigned W = sizeof(T) * CHAR_BIT;
  if (N >= W)
    return ~T(0);
  return (T(1) << N) - 1;
}

static inline unsigned countl_zero(uint64_t x) {
  return static_cast<unsigned>(std::countl_zero(x));
}
static inline unsigned countl_one(uint64_t x) {
  return static_cast<unsigned>(std::countl_one(x));
}
static inline unsigned countr_zero(uint64_t x) {
  return static_cast<unsigned>(std::countr_zero(x));
}
static inline unsigned countr_one(uint64_t x) {
  return static_cast<unsigned>(std::countr_one(x));
}
static inline unsigned popcount(uint64_t x) {
  return static_cast<unsigned>(std::popcount(x));
}
static inline bool isPowerOf2_64(uint64_t x) { return std::has_single_bit(x); }
static inline unsigned Log2_64(uint64_t x) {
  unsigned bw = static_cast<unsigned>(std::bit_width(x));
  return bw - 1U;
}
static inline uint64_t Make_64(uint32_t hi, uint32_t lo) {
  return (uint64_t(hi) << 32) | uint64_t(lo);
}
static inline uint32_t Lo_32(uint64_t x) { return static_cast<uint32_t>(x); }
static inline uint32_t Hi_32(uint64_t x) {
  return static_cast<uint32_t>(x >> 32);
}
static inline uint64_t SignExtend64(uint64_t x, unsigned B) {
  if (B == 0 || B >= 64)
    return x;
  uint64_t m = uint64_t(1) << (B - 1);
  return (x ^ m) - m;
}

class APInt;

inline APInt operator-(APInt);

class [[nodiscard]] APInt {
public:
  using WordType = uint64_t;
  static constexpr unsigned APINT_WORD_SIZE = sizeof(WordType);
  static constexpr unsigned APINT_BITS_PER_WORD = APINT_WORD_SIZE * CHAR_BIT;
  static constexpr WordType WORDTYPE_MAX = ~WordType(0);

  APInt(unsigned numBits, uint64_t val, bool isSigned = false,
        bool implicitTrunc = false)
      : BitWidth(numBits) {
    if (!implicitTrunc) {
      if (isSigned) {
        if (BitWidth == 0) {
          assert((val == 0 || val == uint64_t(-1)) &&
                 "Value must be 0 or -1 for signed 0-bit APInt");
        } else {
          assert(llvm::isIntN(BitWidth, val) &&
                 "Value is not an N-bit signed value");
        }
      } else {
        if (BitWidth == 0) {
          assert(val == 0 && "Value must be zero for unsigned 0-bit APInt");
        } else {
          assert(llvm::isUIntN(BitWidth, val) &&
                 "Value is not an N-bit unsigned value");
        }
      }
    }
    if (isSingleWord()) {
      U.VAL = val;
      if (implicitTrunc || isSigned)
        clearUnusedBits();
    } else {
      initSlowCase(val, isSigned);
    }
  }

  APInt(unsigned numBits, const uint64_t *bigVal, unsigned numWords)
      : BitWidth(numBits) {
    assert(bigVal && "Null pointer detected!");
    initFromArray(bigVal, numWords);
  }

  explicit APInt() { U.VAL = 0; }

  /// Copy Constructor.
  APInt(const APInt &that) : BitWidth(that.BitWidth) {
    if (isSingleWord())
      U.VAL = that.U.VAL;
    else
      initSlowCase(that);
  }

  /// Move Constructor.
  APInt(APInt &&that) : BitWidth(that.BitWidth) {
    memcpy(&U, &that.U, sizeof(U));
    that.BitWidth = 0;
  }

  /// Destructor.
  ~APInt() {
    if (needsCleanup())
      delete[] U.pVal;
  }

  static APInt getZero(unsigned numBits) { return APInt(numBits, 0); }
  static APInt getMaxValue(unsigned numBits) { return getAllOnes(numBits); }
  static APInt getSignedMaxValue(unsigned numBits) {
    APInt API = getAllOnes(numBits);
    API.clearBit(numBits - 1);
    return API;
  }
  static APInt getMinValue(unsigned numBits) { return APInt(numBits, 0); }
  static APInt getSignedMinValue(unsigned numBits) {
    APInt API(numBits, 0);
    API.setBit(numBits - 1);
    return API;
  }

  static APInt getSignMask(unsigned BitWidth) {
    return getSignedMinValue(BitWidth);
  }

  static APInt getAllOnes(unsigned numBits) {
    return APInt(numBits, WORDTYPE_MAX, true);
  }

  static APInt getOneBitSet(unsigned numBits, unsigned BitNo) {
    APInt Res(numBits, 0);
    Res.setBit(BitNo);
    return Res;
  }

  static APInt getBitsSet(unsigned numBits, unsigned loBit, unsigned hiBit) {
    APInt Res(numBits, 0);
    Res.setBits(loBit, hiBit);
    return Res;
  }

  static APInt getBitsSetWithWrap(unsigned numBits, unsigned loBit,
                                  unsigned hiBit) {
    APInt Res(numBits, 0);
    Res.setBitsWithWrap(loBit, hiBit);
    return Res;
  }

  static APInt getBitsSetFrom(unsigned numBits, unsigned loBit) {
    APInt Res(numBits, 0);
    Res.setBitsFrom(loBit);
    return Res;
  }

  static APInt getHighBitsSet(unsigned numBits, unsigned hiBitsSet) {
    APInt Res(numBits, 0);
    Res.setHighBits(hiBitsSet);
    return Res;
  }

  static APInt getLowBitsSet(unsigned numBits, unsigned loBitsSet) {
    APInt Res(numBits, 0);
    Res.setLowBits(loBitsSet);
    return Res;
  }

  bool isSingleWord() const { return BitWidth <= APINT_BITS_PER_WORD; }
  bool isNegative() const { return (*this)[BitWidth - 1]; }
  bool isNonNegative() const { return !isNegative(); }
  bool isSignBitSet() const { return (*this)[BitWidth - 1]; }
  bool isSignBitClear() const { return !isSignBitSet(); }
  bool isStrictlyPositive() const { return isNonNegative() && !isZero(); }
  bool isNonPositive() const { return !isStrictlyPositive(); }
  bool isOneBitSet(unsigned BitNo) const {
    return (*this)[BitNo] && popcount() == 1;
  }
  bool isAllOnes() const {
    if (BitWidth == 0)
      return true;
    if (isSingleWord())
      return U.VAL == WORDTYPE_MAX >> (APINT_BITS_PER_WORD - BitWidth);
    return countTrailingOnesSlowCase() == BitWidth;
  }

  bool isZero() const {
    if (isSingleWord())
      return U.VAL == 0;
    return countLeadingZerosSlowCase() == BitWidth;
  }

  bool isOne() const {
    if (isSingleWord())
      return U.VAL == 1;
    return countLeadingZerosSlowCase() == BitWidth - 1;
  }

  bool isMaxValue() const { return isAllOnes(); }

  bool isMaxSignedValue() const {
    if (isSingleWord()) {
      assert(BitWidth && "zero width values not allowed");
      return U.VAL == ((WordType(1) << (BitWidth - 1)) - 1);
    }
    return !isNegative() && countTrailingOnesSlowCase() == BitWidth - 1;
  }

  bool isMinValue() const { return isZero(); }

  bool isMinSignedValue() const {
    if (isSingleWord()) {
      assert(BitWidth && "zero width values not allowed");
      return U.VAL == (WordType(1) << (BitWidth - 1));
    }
    return isNegative() && countTrailingZerosSlowCase() == BitWidth - 1;
  }

  bool isIntN(unsigned N) const { return getActiveBits() <= N; }

  bool isPowerOf2() const {
    if (isSingleWord()) {
      assert(BitWidth && "zero width values not allowed");
      return isPowerOf2_64(U.VAL);
    }
    return countPopulationSlowCase() == 1;
  }

  bool isSignMask() const { return isMinSignedValue(); }
  bool getBoolValue() const { return !isZero(); }
  uint64_t getLimitedValue(uint64_t Limit = UINT64_MAX) const {
    return ugt(Limit) ? Limit : getZExtValue();
  }

  APInt getHiBits(unsigned numBits) const;
  APInt getLoBits(unsigned numBits) const;
  static bool isSameValue(const APInt &I1, const APInt &I2) {
    if (I1.getBitWidth() == I2.getBitWidth())
      return I1 == I2;

    if (I1.getBitWidth() > I2.getBitWidth())
      return I1 == I2.zext(I1.getBitWidth());

    return I1.zext(I2.getBitWidth()) == I2;
  }
  const uint64_t *getRawData() const {
    if (isSingleWord())
      return &U.VAL;
    return &U.pVal[0];
  }

  APInt operator++(int) {
    APInt API(*this);
    ++(*this);
    return API;
  }
  APInt &operator++();
  APInt operator--(int) {
    APInt API(*this);
    --(*this);
    return API;
  }
  APInt &operator--();
  bool operator!() const { return isZero(); }
  APInt &operator=(const APInt &RHS) {
    if (isSingleWord() && RHS.isSingleWord()) {
      U.VAL = RHS.U.VAL;
      BitWidth = RHS.BitWidth;
      return *this;
    }

    assignSlowCase(RHS);
    return *this;
  }

  APInt &operator=(APInt &&that) {
    assert(this != &that && "Self-move not supported");
    if (!isSingleWord())
      delete[] U.pVal;
    memcpy(&U, &that.U, sizeof(U));

    BitWidth = that.BitWidth;
    that.BitWidth = 0;
    return *this;
  }

  APInt &operator=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL = RHS;
      return clearUnusedBits();
    }
    U.pVal[0] = RHS;
    memset(U.pVal + 1, 0, (getNumWords() - 1) * APINT_WORD_SIZE);
    return *this;
  }
  APInt &operator&=(const APInt &RHS) {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      U.VAL &= RHS.U.VAL;
    else
      andAssignSlowCase(RHS);
    return *this;
  }

  APInt &operator&=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL &= RHS;
      return *this;
    }
    U.pVal[0] &= RHS;
    memset(U.pVal + 1, 0, (getNumWords() - 1) * APINT_WORD_SIZE);
    return *this;
  }

  APInt &operator|=(const APInt &RHS) {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      U.VAL |= RHS.U.VAL;
    else
      orAssignSlowCase(RHS);
    return *this;
  }
  APInt &operator|=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL |= RHS;
      return clearUnusedBits();
    }
    U.pVal[0] |= RHS;
    return *this;
  }
  APInt &operator^=(const APInt &RHS) {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      U.VAL ^= RHS.U.VAL;
    else
      xorAssignSlowCase(RHS);
    return *this;
  }
  APInt &operator^=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL ^= RHS;
      return clearUnusedBits();
    }
    U.pVal[0] ^= RHS;
    return *this;
  }
  APInt &operator*=(const APInt &RHS);
  APInt &operator*=(uint64_t RHS);
  APInt &operator+=(const APInt &RHS);
  APInt &operator+=(uint64_t RHS);
  APInt &operator-=(const APInt &RHS);
  APInt &operator-=(uint64_t RHS);
  APInt &operator<<=(unsigned ShiftAmt) {
    assert(ShiftAmt <= BitWidth && "Invalid shift amount");
    if (isSingleWord()) {
      if (ShiftAmt == BitWidth)
        U.VAL = 0;
      else
        U.VAL <<= ShiftAmt;
      return clearUnusedBits();
    }
    shlSlowCase(ShiftAmt);
    return *this;
  }
  APInt &operator<<=(const APInt &ShiftAmt) {
    *this <<= static_cast<unsigned>(ShiftAmt.getLimitedValue(BitWidth));
    return *this;
  }
  APInt operator*(const APInt &RHS) const;
  APInt operator<<(unsigned Bits) const { return shl(Bits); }
  APInt operator<<(const APInt &Bits) const { return shl(Bits); }
  APInt ashr(unsigned ShiftAmt) const {
    APInt R(*this);
    R.ashrInPlace(ShiftAmt);
    return R;
  }
  void ashrInPlace(unsigned ShiftAmt) {
    assert(ShiftAmt <= BitWidth && "Invalid shift amount");
    if (isSingleWord()) {
      int64_t SExtVAL = static_cast<int64_t>(SignExtend64(U.VAL, BitWidth));
      if (ShiftAmt == BitWidth)
        U.VAL = static_cast<uint64_t>(
            SExtVAL >> (APINT_BITS_PER_WORD - 1)); // Fill with sign bit.
      else
        U.VAL = static_cast<uint64_t>(SExtVAL >> ShiftAmt);
      clearUnusedBits();
      return;
    }
    ashrSlowCase(ShiftAmt);
  }
  APInt lshr(unsigned shiftAmt) const {
    APInt R(*this);
    R.lshrInPlace(shiftAmt);
    return R;
  }
  void lshrInPlace(unsigned ShiftAmt) {
    assert(ShiftAmt <= BitWidth && "Invalid shift amount");
    if (isSingleWord()) {
      if (ShiftAmt == BitWidth)
        U.VAL = 0;
      else
        U.VAL >>= ShiftAmt;
      return;
    }
    lshrSlowCase(ShiftAmt);
  }

  APInt shl(unsigned shiftAmt) const {
    APInt R(*this);
    R <<= shiftAmt;
    return R;
  }
  APInt relativeLShr(int RelativeShift) const {
    return RelativeShift > 0 ? lshr(static_cast<unsigned>(RelativeShift))
                             : shl(static_cast<unsigned>(-RelativeShift));
  }
  APInt relativeLShl(int RelativeShift) const {
    return relativeLShr(-RelativeShift);
  }
  APInt relativeAShr(int RelativeShift) const {
    return RelativeShift > 0 ? ashr(static_cast<unsigned>(RelativeShift))
                             : shl(static_cast<unsigned>(-RelativeShift));
  }
  APInt relativeAShl(int RelativeShift) const {
    return relativeAShr(-RelativeShift);
  }
  APInt ashr(const APInt &ShiftAmt) const {
    APInt R(*this);
    R.ashrInPlace(ShiftAmt);
    return R;
  }
  void ashrInPlace(const APInt &shiftAmt) {
    ashrInPlace(static_cast<unsigned>(shiftAmt.getLimitedValue(BitWidth)));
  }
  APInt lshr(const APInt &ShiftAmt) const {
    APInt R(*this);
    R.lshrInPlace(ShiftAmt);
    return R;
  }
  void lshrInPlace(const APInt &ShiftAmt) {
    lshrInPlace(static_cast<unsigned>(ShiftAmt.getLimitedValue(BitWidth)));
  }
  APInt shl(const APInt &ShiftAmt) const {
    APInt R(*this);
    R <<= ShiftAmt;
    return R;
  }

  APInt udiv(const APInt &RHS) const;
  APInt udiv(uint64_t RHS) const;
  APInt sdiv(const APInt &RHS) const;
  APInt sdiv(int64_t RHS) const;
  APInt urem(const APInt &RHS) const;
  uint64_t urem(uint64_t RHS) const;
  APInt srem(const APInt &RHS) const;
  int64_t srem(int64_t RHS) const;
  static void udivrem(const APInt &LHS, const APInt &RHS, APInt &Quotient,
                      APInt &Remainder);
  static void udivrem(const APInt &LHS, uint64_t RHS, APInt &Quotient,
                      uint64_t &Remainder);

  static void sdivrem(const APInt &LHS, const APInt &RHS, APInt &Quotient,
                      APInt &Remainder);
  static void sdivrem(const APInt &LHS, int64_t RHS, APInt &Quotient,
                      int64_t &Remainder);

  APInt sadd_ov(const APInt &RHS, bool &Overflow) const;
  APInt uadd_ov(const APInt &RHS, bool &Overflow) const;
  APInt ssub_ov(const APInt &RHS, bool &Overflow) const;
  APInt usub_ov(const APInt &RHS, bool &Overflow) const;
  APInt sdiv_ov(const APInt &RHS, bool &Overflow) const;
  APInt smul_ov(const APInt &RHS, bool &Overflow) const;
  APInt umul_ov(const APInt &RHS, bool &Overflow) const;
  APInt sshl_ov(const APInt &Amt, bool &Overflow) const;
  APInt sshl_ov(unsigned Amt, bool &Overflow) const;
  APInt ushl_ov(const APInt &Amt, bool &Overflow) const;
  APInt ushl_ov(unsigned Amt, bool &Overflow) const;

  APInt sfloordiv_ov(const APInt &RHS, bool &Overflow) const;

  APInt sadd_sat(const APInt &RHS) const;
  APInt uadd_sat(const APInt &RHS) const;
  APInt ssub_sat(const APInt &RHS) const;
  APInt usub_sat(const APInt &RHS) const;
  APInt smul_sat(const APInt &RHS) const;
  APInt umul_sat(const APInt &RHS) const;
  APInt sshl_sat(const APInt &RHS) const;
  APInt sshl_sat(unsigned RHS) const;
  APInt ushl_sat(const APInt &RHS) const;
  APInt ushl_sat(unsigned RHS) const;

  bool operator[](unsigned bitPosition) const {
    assert(bitPosition < getBitWidth() && "Bit position out of bounds!");
    return (maskBit(bitPosition) & getWord(bitPosition)) != 0;
  }
  bool operator==(const APInt &RHS) const {
    assert(BitWidth == RHS.BitWidth && "Comparison requires equal bit widths");
    if (isSingleWord())
      return U.VAL == RHS.U.VAL;
    return equalSlowCase(RHS);
  }

  bool operator==(uint64_t Val) const {
    return (isSingleWord() || getActiveBits() <= 64) && getZExtValue() == Val;
  }

  bool eq(const APInt &RHS) const { return (*this) == RHS; }
  bool operator!=(const APInt &RHS) const { return !((*this) == RHS); }
  bool operator!=(uint64_t Val) const { return !((*this) == Val); }
  bool ne(const APInt &RHS) const { return !((*this) == RHS); }
  bool ult(const APInt &RHS) const { return compare(RHS) < 0; }
  bool ult(uint64_t RHS) const {
    return (isSingleWord() || getActiveBits() <= 64) && getZExtValue() < RHS;
  }
  bool slt(const APInt &RHS) const { return compareSigned(RHS) < 0; }
  bool slt(int64_t RHS) const {
    return (!isSingleWord() && getSignificantBits() > 64)
               ? isNegative()
               : getSExtValue() < RHS;
  }
  bool ule(const APInt &RHS) const { return compare(RHS) <= 0; }
  bool ule(uint64_t RHS) const { return !ugt(RHS); }
  bool sle(const APInt &RHS) const { return compareSigned(RHS) <= 0; }
  bool sle(uint64_t RHS) const { return !sgt(static_cast<int64_t>(RHS)); }
  bool ugt(const APInt &RHS) const { return !ule(RHS); }
  bool ugt(uint64_t RHS) const {
    return (!isSingleWord() && getActiveBits() > 64) || getZExtValue() > RHS;
  }
  bool sgt(const APInt &RHS) const { return !sle(RHS); }
  bool sgt(int64_t RHS) const {
    return (!isSingleWord() && getSignificantBits() > 64)
               ? !isNegative()
               : getSExtValue() > RHS;
  }
  bool uge(const APInt &RHS) const { return !ult(RHS); }
  bool uge(uint64_t RHS) const { return !ult(RHS); }
  bool sge(const APInt &RHS) const { return !slt(RHS); }
  bool sge(int64_t RHS) const { return !slt(RHS); }

  bool intersects(const APInt &RHS) const {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      return (U.VAL & RHS.U.VAL) != 0;
    return intersectsSlowCase(RHS);
  }

  bool isSubsetOf(const APInt &RHS) const {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      return (U.VAL & ~RHS.U.VAL) == 0;
    return isSubsetOfSlowCase(RHS);
  }

  APInt trunc(unsigned width) const;
  APInt sext(unsigned width) const;
  APInt zext(unsigned width) const;
  APInt sextOrTrunc(unsigned width) const;
  APInt zextOrTrunc(unsigned width) const;

  void setAllBits() {
    if (isSingleWord())
      U.VAL = WORDTYPE_MAX;
    else
      memset(U.pVal, -1, getNumWords() * APINT_WORD_SIZE);
    clearUnusedBits();
  }

  void setBit(unsigned BitPosition) {
    assert(BitPosition < BitWidth && "BitPosition out of range");
    WordType Mask = maskBit(BitPosition);
    if (isSingleWord())
      U.VAL |= Mask;
    else
      U.pVal[whichWord(BitPosition)] |= Mask;
  }
  void setSignBit() { setBit(BitWidth - 1); }
  void setBitVal(unsigned BitPosition, bool BitValue) {
    if (BitValue)
      setBit(BitPosition);
    else
      clearBit(BitPosition);
  }
  void setBitsWithWrap(unsigned loBit, unsigned hiBit) {
    assert(hiBit <= BitWidth && "hiBit out of range");
    assert(loBit <= BitWidth && "loBit out of range");
    if (loBit < hiBit) {
      setBits(loBit, hiBit);
      return;
    }
    setLowBits(hiBit);
    setHighBits(BitWidth - loBit);
  }
  void setBits(unsigned loBit, unsigned hiBit) {
    assert(hiBit <= BitWidth && "hiBit out of range");
    assert(loBit <= hiBit && "loBit greater than hiBit");
    if (loBit == hiBit)
      return;
    if (hiBit <= APINT_BITS_PER_WORD) {
      uint64_t mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - (hiBit - loBit));
      mask <<= loBit;
      if (isSingleWord())
        U.VAL |= mask;
      else
        U.pVal[0] |= mask;
    } else {
      setBitsSlowCase(loBit, hiBit);
    }
  }

  void setBitsFrom(unsigned loBit) { return setBits(loBit, BitWidth); }
  void setLowBits(unsigned loBits) { return setBits(0, loBits); }
  void setHighBits(unsigned hiBits) {
    return setBits(BitWidth - hiBits, BitWidth);
  }
  void clearAllBits() {
    if (isSingleWord())
      U.VAL = 0;
    else
      memset(U.pVal, 0, getNumWords() * APINT_WORD_SIZE);
  }
  void clearBit(unsigned BitPosition) {
    assert(BitPosition < BitWidth && "BitPosition out of range");
    WordType Mask = ~maskBit(BitPosition);
    if (isSingleWord())
      U.VAL &= Mask;
    else
      U.pVal[whichWord(BitPosition)] &= Mask;
  }
  void clearBits(unsigned LoBit, unsigned HiBit) {
    assert(HiBit <= BitWidth && "HiBit out of range");
    assert(LoBit <= HiBit && "LoBit greater than HiBit");
    if (LoBit == HiBit)
      return;
    if (HiBit <= APINT_BITS_PER_WORD) {
      uint64_t Mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - (HiBit - LoBit));
      Mask = ~(Mask << LoBit);
      if (isSingleWord())
        U.VAL &= Mask;
      else
        U.pVal[0] &= Mask;
    } else {
      clearBitsSlowCase(LoBit, HiBit);
    }
  }

  void clearLowBits(unsigned loBits) {
    assert(loBits <= BitWidth && "More bits than bitwidth");
    APInt Keep = getHighBitsSet(BitWidth, BitWidth - loBits);
    *this &= Keep;
  }

  void clearHighBits(unsigned hiBits) {
    assert(hiBits <= BitWidth && "More bits than bitwidth");
    APInt Keep = getLowBitsSet(BitWidth, BitWidth - hiBits);
    *this &= Keep;
  }

  void clearSignBit() { clearBit(BitWidth - 1); }

  void flipAllBits() {
    if (isSingleWord()) {
      U.VAL ^= WORDTYPE_MAX;
      clearUnusedBits();
    } else {
      flipAllBitsSlowCase();
    }
  }

  void negate() {
    flipAllBits();
    ++(*this);
  }

  uint64_t extractBitsAsZExtValue(unsigned numBits, unsigned bitPosition) const;
  unsigned getBitWidth() const { return BitWidth; }
  unsigned getNumWords() const { return getNumWords(BitWidth); }
  static unsigned getNumWords(unsigned BitWidth) {
    return static_cast<unsigned>(
        (static_cast<uint64_t>(BitWidth) + APINT_BITS_PER_WORD - 1) /
        APINT_BITS_PER_WORD);
  }
  unsigned getActiveBits() const { return BitWidth - countl_zero(); }
  unsigned getActiveWords() const {
    unsigned numActiveBits = getActiveBits();
    return numActiveBits ? whichWord(numActiveBits - 1) + 1 : 1;
  }
  unsigned getSignificantBits() const {
    return BitWidth - getNumSignBits() + 1;
  }
  uint64_t getZExtValue() const {
    if (isSingleWord())
      return U.VAL;
    assert(getActiveBits() <= 64 && "Too many bits for uint64_t");
    return U.pVal[0];
  }
  std::optional<uint64_t> tryZExtValue() const {
    return (getActiveBits() <= 64) ? std::optional<uint64_t>(getZExtValue())
                                   : std::nullopt;
  };
  int64_t getSExtValue() const {
    if (isSingleWord())
      return static_cast<int64_t>(SignExtend64(U.VAL, BitWidth));
    assert(getSignificantBits() <= 64 && "Too many bits for int64_t");
    return int64_t(U.pVal[0]);
  }
  std::optional<int64_t> trySExtValue() const {
    return (getSignificantBits() <= 64) ? std::optional<int64_t>(getSExtValue())
                                        : std::nullopt;
  };
  unsigned countl_zero() const {
    if (isSingleWord()) {
      unsigned unusedBits = APINT_BITS_PER_WORD - BitWidth;
      return llvm::countl_zero(U.VAL) - unusedBits;
    }
    return countLeadingZerosSlowCase();
  }
  unsigned countLeadingZeros() const { return countl_zero(); }
  unsigned countl_one() const {
    if (isSingleWord()) {
      if (BitWidth == 0)
        return 0;
      return llvm::countl_one(U.VAL << (APINT_BITS_PER_WORD - BitWidth));
    }
    return countLeadingOnesSlowCase();
  }
  unsigned countLeadingOnes() const { return countl_one(); }
  unsigned getNumSignBits() const {
    return isNegative() ? countl_one() : countl_zero();
  }
  unsigned countr_zero() const {
    if (isSingleWord()) {
      unsigned TrailingZeros = llvm::countr_zero(U.VAL);
      return (TrailingZeros > BitWidth ? BitWidth : TrailingZeros);
    }
    return countTrailingZerosSlowCase();
  }

  unsigned countTrailingZeros() const { return countr_zero(); }
  unsigned countr_one() const {
    if (isSingleWord())
      return llvm::countr_one(U.VAL);
    return countTrailingOnesSlowCase();
  }

  unsigned countTrailingOnes() const { return countr_one(); }
  unsigned popcount() const {
    if (isSingleWord())
      return llvm::popcount(U.VAL);
    return countPopulationSlowCase();
  }

  unsigned logBase2() const { return getActiveBits() - 1; }

  APInt abs() const {
    if (isNegative())
      return -(*this);
    return *this;
  }

  static void tcSet(WordType *, WordType, unsigned);
  static void tcAssign(WordType *, const WordType *, unsigned);
  static unsigned tcMSB(const WordType *parts, unsigned n);
  static WordType tcAdd(WordType *, const WordType *, WordType carry, unsigned);
  static WordType tcAddPart(WordType *, WordType, unsigned);
  static WordType tcSubtract(WordType *, const WordType *, WordType carry,
                             unsigned);
  static WordType tcSubtractPart(WordType *, WordType, unsigned);
  static int tcMultiplyPart(WordType *dst, const WordType *src,
                            WordType multiplier, WordType carry,
                            unsigned srcParts, unsigned dstParts, bool add);
  static int tcMultiply(WordType *, const WordType *, const WordType *,
                        unsigned);
  static int tcDivide(WordType *lhs, const WordType *rhs, WordType *remainder,
                      WordType *scratch, unsigned parts);
  static void tcShiftLeft(WordType *, unsigned Words, unsigned Count);
  static void tcShiftRight(WordType *, unsigned Words, unsigned Count);
  static int tcCompare(const WordType *, const WordType *, unsigned);
  static WordType tcIncrement(WordType *dst, unsigned parts) {
    return tcAddPart(dst, 1, parts);
  }
  static WordType tcDecrement(WordType *dst, unsigned parts) {
    return tcSubtractPart(dst, 1, parts);
  }
  bool needsCleanup() const { return !isSingleWord(); }

private:
  union {
    uint64_t VAL;   ///< Used to store the <= 64 bits integer value.
    uint64_t *pVal; ///< Used to store the >64 bits integer value.
  } U;

  unsigned BitWidth = 1; ///< The number of bits in this APInt.
  APInt(uint64_t *val, unsigned bits) : BitWidth(bits) { U.pVal = val; }
  static unsigned whichWord(unsigned bitPosition) {
    return bitPosition / APINT_BITS_PER_WORD;
  }
  static unsigned whichBit(unsigned bitPosition) {
    return bitPosition % APINT_BITS_PER_WORD;
  }
  static uint64_t maskBit(unsigned bitPosition) {
    return 1ULL << whichBit(bitPosition);
  }
  APInt &clearUnusedBits() {
    unsigned WordBits = ((BitWidth - 1) % APINT_BITS_PER_WORD) + 1;
    uint64_t mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - WordBits);
    if (BitWidth == 0)
      mask = 0;

    if (isSingleWord())
      U.VAL &= mask;
    else
      U.pVal[getNumWords() - 1] &= mask;
    return *this;
  }
  uint64_t getWord(unsigned bitPosition) const {
    return isSingleWord() ? U.VAL : U.pVal[whichWord(bitPosition)];
  }
  void reallocate(unsigned NewBitWidth);
  static void divide(const WordType *LHS, unsigned lhsWords,
                     const WordType *RHS, unsigned rhsWords, WordType *Quotient,
                     WordType *Remainder);

  void initSlowCase(uint64_t val, bool isSigned);
  void initFromArray(const uint64_t *array, unsigned count);
  void initSlowCase(const APInt &that);
  void shlSlowCase(unsigned ShiftAmt);
  void lshrSlowCase(unsigned ShiftAmt);
  void ashrSlowCase(unsigned ShiftAmt);
  void assignSlowCase(const APInt &RHS);
  bool equalSlowCase(const APInt &RHS) const;
  unsigned countLeadingZerosSlowCase() const;
  unsigned countLeadingOnesSlowCase() const;
  unsigned countTrailingZerosSlowCase() const;
  unsigned countTrailingOnesSlowCase() const;
  unsigned countPopulationSlowCase() const;
  bool intersectsSlowCase(const APInt &RHS) const;
  bool isSubsetOfSlowCase(const APInt &RHS) const;
  void setBitsSlowCase(unsigned loBit, unsigned hiBit);
  void clearBitsSlowCase(unsigned LoBit, unsigned HiBit);
  void flipAllBitsSlowCase();
  void andAssignSlowCase(const APInt &RHS);
  void orAssignSlowCase(const APInt &RHS);
  void xorAssignSlowCase(const APInt &RHS);
  int compare(const APInt &RHS) const;
  int compareSigned(const APInt &RHS) const;
};

inline bool operator==(uint64_t V1, const APInt &V2) { return V2 == V1; }

inline bool operator!=(uint64_t V1, const APInt &V2) { return V2 != V1; }

inline APInt operator~(APInt v) {
  v.flipAllBits();
  return v;
}

inline APInt operator&(APInt a, const APInt &b) {
  a &= b;
  return a;
}

inline APInt operator&(const APInt &a, APInt &&b) {
  b &= a;
  return std::move(b);
}

inline APInt operator&(APInt a, uint64_t RHS) {
  a &= RHS;
  return a;
}

inline APInt operator&(uint64_t LHS, APInt b) {
  b &= LHS;
  return b;
}

inline APInt operator|(APInt a, const APInt &b) {
  a |= b;
  return a;
}

inline APInt operator|(const APInt &a, APInt &&b) {
  b |= a;
  return std::move(b);
}

inline APInt operator|(APInt a, uint64_t RHS) {
  a |= RHS;
  return a;
}

inline APInt operator|(uint64_t LHS, APInt b) {
  b |= LHS;
  return b;
}

inline APInt operator^(APInt a, const APInt &b) {
  a ^= b;
  return a;
}

inline APInt operator^(const APInt &a, APInt &&b) {
  b ^= a;
  return std::move(b);
}

inline APInt operator^(APInt a, uint64_t RHS) {
  a ^= RHS;
  return a;
}

inline APInt operator^(uint64_t LHS, APInt b) {
  b ^= LHS;
  return b;
}

inline APInt operator-(APInt v) {
  v.negate();
  return v;
}

inline APInt operator+(APInt a, const APInt &b) {
  a += b;
  return a;
}

inline APInt operator+(const APInt &a, APInt &&b) {
  b += a;
  return std::move(b);
}

inline APInt operator+(APInt a, uint64_t RHS) {
  a += RHS;
  return a;
}

inline APInt operator+(uint64_t LHS, APInt b) {
  b += LHS;
  return b;
}

inline APInt operator-(APInt a, const APInt &b) {
  a -= b;
  return a;
}

inline APInt operator-(const APInt &a, APInt &&b) {
  b.negate();
  b += a;
  return std::move(b);
}

inline APInt operator-(APInt a, uint64_t RHS) {
  a -= RHS;
  return a;
}

inline APInt operator-(uint64_t LHS, APInt b) {
  b.negate();
  b += LHS;
  return b;
}

inline APInt operator*(APInt a, uint64_t RHS) {
  a *= RHS;
  return a;
}

inline APInt operator*(uint64_t LHS, APInt b) {
  b *= LHS;
  return b;
}

namespace APIntOps {
inline const APInt &smin(const APInt &A, const APInt &B) {
  return A.slt(B) ? A : B;
}
inline const APInt &smax(const APInt &A, const APInt &B) {
  return A.sgt(B) ? A : B;
}
inline const APInt &umin(const APInt &A, const APInt &B) {
  return A.ult(B) ? A : B;
}
inline const APInt &umax(const APInt &A, const APInt &B) {
  return A.ugt(B) ? A : B;
}
std::optional<unsigned> GetMostSignificantDifferentBit(const APInt &A,
                                                       const APInt &B);

} // namespace APIntOps

inline static uint64_t *getClearedMemory(unsigned numWords) {
  return new uint64_t[numWords]();
}
inline static uint64_t *getMemory(unsigned numWords) {
  return new uint64_t[numWords];
}
inline static unsigned getDigit(char cdigit, uint8_t radix) {
  unsigned r;

  if (radix == 16 || radix == 36) {
    r = static_cast<unsigned>(cdigit - '0');
    if (r <= 9)
      return r;

    r = static_cast<unsigned>(cdigit - 'A');
    if (r <= radix - 11U)
      return r + 10;

    r = static_cast<unsigned>(cdigit - 'a');
    if (r <= radix - 11U)
      return r + 10;

    radix = 10;
  }

  r = static_cast<unsigned>(cdigit - '0');
  if (r < radix)
    return r;

  return UINT_MAX;
}

inline void APInt::initSlowCase(uint64_t val, bool isSigned) {
  if (isSigned && int64_t(val) < 0) {
    U.pVal = getMemory(getNumWords());
    U.pVal[0] = val;
    memset(&U.pVal[1], 0xFF, APINT_WORD_SIZE * (getNumWords() - 1));
    clearUnusedBits();
  } else {
    U.pVal = getClearedMemory(getNumWords());
    U.pVal[0] = val;
  }
}

inline void APInt::initSlowCase(const APInt &that) {
  U.pVal = getMemory(getNumWords());
  memcpy(U.pVal, that.U.pVal, getNumWords() * APINT_WORD_SIZE);
}

inline void APInt::initFromArray(const uint64_t *bigVal, unsigned count) {
  assert(bigVal && "Null pointer detected!");
  if (isSingleWord())
    U.VAL = bigVal[0];
  else {
    U.pVal = getClearedMemory(getNumWords());
    unsigned words = std::min<unsigned>(count, getNumWords());
    memcpy(U.pVal, bigVal, words * APINT_WORD_SIZE);
  }
  clearUnusedBits();
}

inline void APInt::reallocate(unsigned NewBitWidth) {
  if (getNumWords() == getNumWords(NewBitWidth)) {
    BitWidth = NewBitWidth;
    return;
  }
  if (!isSingleWord())
    delete[] U.pVal;
  BitWidth = NewBitWidth;
  if (!isSingleWord())
    U.pVal = getMemory(getNumWords());
}

inline void APInt::assignSlowCase(const APInt &RHS) {
  if (this == &RHS)
    return;

  reallocate(RHS.getBitWidth());

  if (isSingleWord())
    U.VAL = RHS.U.VAL;
  else
    memcpy(U.pVal, RHS.U.pVal, getNumWords() * APINT_WORD_SIZE);
}
inline APInt &APInt::operator++() {
  if (isSingleWord())
    ++U.VAL;
  else
    tcIncrement(U.pVal, getNumWords());
  return clearUnusedBits();
}

inline APInt &APInt::operator--() {
  if (isSingleWord())
    --U.VAL;
  else
    tcDecrement(U.pVal, getNumWords());
  return clearUnusedBits();
}

inline APInt &APInt::operator+=(const APInt &RHS) {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
  if (isSingleWord())
    U.VAL += RHS.U.VAL;
  else
    tcAdd(U.pVal, RHS.U.pVal, 0, getNumWords());
  return clearUnusedBits();
}

inline APInt &APInt::operator+=(uint64_t RHS) {
  if (isSingleWord())
    U.VAL += RHS;
  else
    tcAddPart(U.pVal, RHS, getNumWords());
  return clearUnusedBits();
}

inline APInt &APInt::operator-=(const APInt &RHS) {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
  if (isSingleWord())
    U.VAL -= RHS.U.VAL;
  else
    tcSubtract(U.pVal, RHS.U.pVal, 0, getNumWords());
  return clearUnusedBits();
}

inline APInt &APInt::operator-=(uint64_t RHS) {
  if (isSingleWord())
    U.VAL -= RHS;
  else
    tcSubtractPart(U.pVal, RHS, getNumWords());
  return clearUnusedBits();
}

inline APInt APInt::operator*(const APInt &RHS) const {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
  if (isSingleWord())
    return APInt(BitWidth, U.VAL * RHS.U.VAL, /*isSigned=*/false,
                 /*implicitTrunc=*/true);

  APInt Result(getMemory(getNumWords()), getBitWidth());
  tcMultiply(Result.U.pVal, U.pVal, RHS.U.pVal, getNumWords());
  Result.clearUnusedBits();
  return Result;
}

inline void APInt::andAssignSlowCase(const APInt &RHS) {
  WordType *dst = U.pVal, *rhs = RHS.U.pVal;
  for (size_t i = 0, e = getNumWords(); i != e; ++i)
    dst[i] &= rhs[i];
}

inline void APInt::orAssignSlowCase(const APInt &RHS) {
  WordType *dst = U.pVal, *rhs = RHS.U.pVal;
  for (size_t i = 0, e = getNumWords(); i != e; ++i)
    dst[i] |= rhs[i];
}

inline void APInt::xorAssignSlowCase(const APInt &RHS) {
  WordType *dst = U.pVal, *rhs = RHS.U.pVal;
  for (size_t i = 0, e = getNumWords(); i != e; ++i)
    dst[i] ^= rhs[i];
}

inline APInt &APInt::operator*=(const APInt &RHS) {
  *this = *this * RHS;
  return *this;
}

inline APInt &APInt::operator*=(uint64_t RHS) {
  if (isSingleWord()) {
    U.VAL *= RHS;
  } else {
    unsigned NumWords = getNumWords();
    tcMultiplyPart(U.pVal, U.pVal, RHS, 0, NumWords, NumWords, false);
  }
  return clearUnusedBits();
}

inline bool APInt::equalSlowCase(const APInt &RHS) const {
  return std::equal(U.pVal, U.pVal + getNumWords(), RHS.U.pVal);
}

inline int APInt::compare(const APInt &RHS) const {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be same for comparison");
  if (isSingleWord())
    return U.VAL < RHS.U.VAL ? -1 : U.VAL > RHS.U.VAL;

  return tcCompare(U.pVal, RHS.U.pVal, getNumWords());
}

inline int APInt::compareSigned(const APInt &RHS) const {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be same for comparison");
  if (isSingleWord()) {
    int64_t lhsSext = static_cast<int64_t>(SignExtend64(U.VAL, BitWidth));
    int64_t rhsSext = static_cast<int64_t>(SignExtend64(RHS.U.VAL, BitWidth));
    return lhsSext < rhsSext ? -1 : lhsSext > rhsSext;
  }

  bool lhsNeg = isNegative();
  bool rhsNeg = RHS.isNegative();

  if (lhsNeg != rhsNeg)
    return lhsNeg ? -1 : 1;

  return tcCompare(U.pVal, RHS.U.pVal, getNumWords());
}

inline void APInt::setBitsSlowCase(unsigned loBit, unsigned hiBit) {
  unsigned loWord = whichWord(loBit);
  unsigned hiWord = whichWord(hiBit);
  uint64_t loMask = WORDTYPE_MAX << whichBit(loBit);
  unsigned hiShiftAmt = whichBit(hiBit);
  if (hiShiftAmt != 0) {
    uint64_t hiMask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - hiShiftAmt);
    if (hiWord == loWord)
      loMask &= hiMask;
    else
      U.pVal[hiWord] |= hiMask;
  }
  U.pVal[loWord] |= loMask;

  for (unsigned word = loWord + 1; word < hiWord; ++word)
    U.pVal[word] = WORDTYPE_MAX;
}

inline void APInt::clearBitsSlowCase(unsigned LoBit, unsigned HiBit) {
  unsigned LoWord = whichWord(LoBit);
  unsigned HiWord = whichWord(HiBit);
  uint64_t LoMask = ~(WORDTYPE_MAX << whichBit(LoBit));
  unsigned HiShiftAmt = whichBit(HiBit);
  if (HiShiftAmt != 0) {
    uint64_t HiMask = ~(WORDTYPE_MAX >> (APINT_BITS_PER_WORD - HiShiftAmt));
    if (HiWord == LoWord)
      LoMask |= HiMask;
    else
      U.pVal[HiWord] &= HiMask;
  }
  U.pVal[LoWord] &= LoMask;
  for (unsigned Word = LoWord + 1; Word < HiWord; ++Word)
    U.pVal[Word] = 0;
}

static void tcComplement(APInt::WordType *dst, unsigned parts) {
  for (unsigned i = 0; i < parts; i++)
    dst[i] = ~dst[i];
}

inline void APInt::flipAllBitsSlowCase() {
  tcComplement(U.pVal, getNumWords());
  clearUnusedBits();
}

inline uint64_t APInt::extractBitsAsZExtValue(unsigned numBits,
                                              unsigned bitPosition) const {
  assert(bitPosition < BitWidth && (numBits + bitPosition) <= BitWidth &&
         "Illegal bit extraction");
  assert(numBits <= 64 && "Illegal bit extraction");

  uint64_t maskBits = maskTrailingOnes<uint64_t>(numBits);
  if (isSingleWord())
    return (U.VAL >> bitPosition) & maskBits;

  static_assert(APINT_BITS_PER_WORD >= 64,
                "This code assumes only two words affected");
  unsigned loBit = whichBit(bitPosition);
  unsigned loWord = whichWord(bitPosition);
  unsigned hiWord = whichWord(bitPosition + numBits - 1);
  if (loWord == hiWord)
    return (U.pVal[loWord] >> loBit) & maskBits;

  uint64_t retBits = U.pVal[loWord] >> loBit;
  retBits |= U.pVal[hiWord] << (APINT_BITS_PER_WORD - loBit);
  retBits &= maskBits;
  return retBits;
}

inline APInt APInt::getHiBits(unsigned numBits) const {
  return this->lshr(BitWidth - numBits);
}

inline APInt APInt::getLoBits(unsigned numBits) const {
  APInt Result(getLowBitsSet(BitWidth, numBits));
  Result &= *this;
  return Result;
}

inline unsigned APInt::countLeadingZerosSlowCase() const {
  unsigned Count = 0;
  for (int i = static_cast<int>(getNumWords()) - 1; i >= 0; --i) {
    uint64_t V = U.pVal[i];
    if (V == 0)
      Count += APINT_BITS_PER_WORD;
    else {
      Count += ::llvm::countl_zero(V);
      break;
    }
  }
  unsigned Mod = BitWidth % APINT_BITS_PER_WORD;
  Count -= Mod > 0 ? APINT_BITS_PER_WORD - Mod : 0;
  return Count;
}

inline unsigned APInt::countLeadingOnesSlowCase() const {
  unsigned highWordBits = BitWidth % APINT_BITS_PER_WORD;
  unsigned shift;
  if (!highWordBits) {
    highWordBits = APINT_BITS_PER_WORD;
    shift = 0;
  } else {
    shift = APINT_BITS_PER_WORD - highWordBits;
  }
  int i = static_cast<int>(getNumWords()) - 1;
  unsigned Count = ::llvm::countl_one(U.pVal[i] << shift);
  if (Count == highWordBits) {
    for (i--; i >= 0; --i) {
      if (U.pVal[i] == WORDTYPE_MAX)
        Count += APINT_BITS_PER_WORD;
      else {
        Count += ::llvm::countl_one(U.pVal[i]);
        break;
      }
    }
  }
  return Count;
}

inline unsigned APInt::countTrailingZerosSlowCase() const {
  unsigned Count = 0;
  unsigned i = 0;
  for (; i < getNumWords() && U.pVal[i] == 0; ++i)
    Count += APINT_BITS_PER_WORD;
  if (i < getNumWords())
    Count += ::llvm::countr_zero(U.pVal[i]);
  return std::min(Count, BitWidth);
}

inline unsigned APInt::countTrailingOnesSlowCase() const {
  unsigned Count = 0;
  unsigned i = 0;
  for (; i < getNumWords() && U.pVal[i] == WORDTYPE_MAX; ++i)
    Count += APINT_BITS_PER_WORD;
  if (i < getNumWords())
    Count += ::llvm::countr_one(U.pVal[i]);
  assert(Count <= BitWidth);
  return Count;
}

inline unsigned APInt::countPopulationSlowCase() const {
  unsigned Count = 0;
  for (unsigned i = 0; i < getNumWords(); ++i)
    Count += ::llvm::popcount(U.pVal[i]);
  return Count;
}

inline bool APInt::intersectsSlowCase(const APInt &RHS) const {
  for (unsigned i = 0, e = getNumWords(); i != e; ++i)
    if ((U.pVal[i] & RHS.U.pVal[i]) != 0)
      return true;

  return false;
}

inline bool APInt::isSubsetOfSlowCase(const APInt &RHS) const {
  for (unsigned i = 0, e = getNumWords(); i != e; ++i)
    if ((U.pVal[i] & ~RHS.U.pVal[i]) != 0)
      return false;

  return true;
}

inline APInt APInt::trunc(unsigned width) const {
  assert(width <= BitWidth && "Invalid APInt Truncate request");

  if (width <= APINT_BITS_PER_WORD)
    return APInt(width, getRawData()[0], /*isSigned=*/false,
                 /*implicitTrunc=*/true);

  if (width == BitWidth)
    return *this;

  APInt Result(getMemory(getNumWords(width)), width);

  // Copy full words.
  unsigned i;
  for (i = 0; i != width / APINT_BITS_PER_WORD; i++)
    Result.U.pVal[i] = U.pVal[i];

  // Truncate and copy any partial word.
  unsigned bits = (0 - width) % APINT_BITS_PER_WORD;
  if (bits != 0)
    Result.U.pVal[i] = U.pVal[i] << bits >> bits;

  return Result;
}

// Sign extend to a new width.
inline APInt APInt::sext(unsigned Width) const {
  assert(Width >= BitWidth && "Invalid APInt SignExtend request");

  if (Width <= APINT_BITS_PER_WORD)
    return APInt(Width, static_cast<uint64_t>(SignExtend64(U.VAL, BitWidth)),
                 /*isSigned=*/true);

  if (Width == BitWidth)
    return *this;

  APInt Result(getMemory(getNumWords(Width)), Width);
  std::memcpy(Result.U.pVal, getRawData(), getNumWords() * APINT_WORD_SIZE);
  Result.U.pVal[getNumWords() - 1] = static_cast<uint64_t>(
      SignExtend64(Result.U.pVal[getNumWords() - 1],
                   ((BitWidth - 1) % APINT_BITS_PER_WORD) + 1));
  std::memset(Result.U.pVal + getNumWords(), isNegative() ? -1 : 0,
              (Result.getNumWords() - getNumWords()) * APINT_WORD_SIZE);
  Result.clearUnusedBits();
  return Result;
}
inline APInt APInt::zext(unsigned width) const {
  assert(width >= BitWidth && "Invalid APInt ZeroExtend request");

  if (width <= APINT_BITS_PER_WORD)
    return APInt(width, U.VAL);

  if (width == BitWidth)
    return *this;

  APInt Result(getMemory(getNumWords(width)), width);
  std::memcpy(Result.U.pVal, getRawData(), getNumWords() * APINT_WORD_SIZE);
  std::memset(Result.U.pVal + getNumWords(), 0,
              (Result.getNumWords() - getNumWords()) * APINT_WORD_SIZE);

  return Result;
}

inline APInt APInt::zextOrTrunc(unsigned width) const {
  if (BitWidth < width)
    return zext(width);
  if (BitWidth > width)
    return trunc(width);
  return *this;
}

inline APInt APInt::sextOrTrunc(unsigned width) const {
  if (BitWidth < width)
    return sext(width);
  if (BitWidth > width)
    return trunc(width);
  return *this;
}

inline void APInt::ashrSlowCase(unsigned ShiftAmt) {
  if (!ShiftAmt)
    return;

  bool Negative = isNegative();
  unsigned WordShift = ShiftAmt / APINT_BITS_PER_WORD;
  unsigned BitShift = ShiftAmt % APINT_BITS_PER_WORD;
  unsigned WordsToMove = getNumWords() - WordShift;
  if (WordsToMove != 0) {
    U.pVal[getNumWords() - 1] = static_cast<uint64_t>(SignExtend64(
        U.pVal[getNumWords() - 1], ((BitWidth - 1) % APINT_BITS_PER_WORD) + 1));
    if (BitShift == 0) {
      std::memmove(U.pVal, U.pVal + WordShift, WordsToMove * APINT_WORD_SIZE);
    } else {
      for (unsigned i = 0; i != WordsToMove - 1; ++i)
        U.pVal[i] =
            (U.pVal[i + WordShift] >> BitShift) |
            (U.pVal[i + WordShift + 1] << (APINT_BITS_PER_WORD - BitShift));

      U.pVal[WordsToMove - 1] = static_cast<uint64_t>(
          static_cast<int64_t>(U.pVal[WordShift + WordsToMove - 1]) >>
          BitShift);
    }
  }

  std::memset(U.pVal + WordsToMove, Negative ? -1 : 0,
              WordShift * APINT_WORD_SIZE);
  clearUnusedBits();
}

inline void APInt::lshrSlowCase(unsigned ShiftAmt) {
  tcShiftRight(U.pVal, getNumWords(), ShiftAmt);
}

inline void APInt::shlSlowCase(unsigned ShiftAmt) {
  tcShiftLeft(U.pVal, getNumWords(), ShiftAmt);
  clearUnusedBits();
}

static void KnuthDiv(uint32_t *u, uint32_t *v, uint32_t *q, uint32_t *r,
                     unsigned m, unsigned n) {
  assert(u && "Must provide dividend");
  assert(v && "Must provide divisor");
  assert(q && "Must provide quotient");
  assert(u != v && u != q && v != q && "Must use different memory");
  assert(n > 1 && "n must be > 1");

  // b denotes the base of the number system. In our case b is 2^32.
  const uint64_t b = uint64_t(1) << 32;

  unsigned shift = ::llvm::countl_zero(v[n - 1]);
  uint32_t v_carry = 0;
  uint32_t u_carry = 0;
  if (shift) {
    for (unsigned i = 0; i < m + n; ++i) {
      uint32_t u_tmp = u[i] >> (32 - shift);
      u[i] = (u[i] << shift) | u_carry;
      u_carry = u_tmp;
    }
    for (unsigned i = 0; i < n; ++i) {
      uint32_t v_tmp = v[i] >> (32 - shift);
      v[i] = (v[i] << shift) | v_carry;
      v_carry = v_tmp;
    }
  }
  u[m + n] = u_carry;

  int j = static_cast<int>(m);
  do {
    uint64_t dividend =
        Make_64(u[static_cast<unsigned>(j + static_cast<int>(n))],
                u[static_cast<unsigned>(j + static_cast<int>(n) - 1)]);
    uint64_t qp = dividend / v[n - 1];
    uint64_t rp = dividend % v[n - 1];
    if (qp == b ||
        qp * v[n - 2] >
            b * rp + u[static_cast<unsigned>(j + static_cast<int>(n) - 2)]) {
      qp--;
      rp += v[n - 1];
      if (rp < b &&
          (qp == b ||
           qp * v[n - 2] >
               b * rp + u[static_cast<unsigned>(j + static_cast<int>(n) - 2)]))
        qp--;
    }
    int64_t borrow = 0;
    for (unsigned i = 0; i < n; ++i) {
      uint64_t p = qp * uint64_t(v[i]);
      int64_t subres =
          int64_t(u[static_cast<unsigned>(j + static_cast<int>(i))]) - borrow -
          Lo_32(p);
      u[static_cast<unsigned>(j + static_cast<int>(i))] =
          Lo_32(static_cast<uint64_t>(subres));
      borrow = static_cast<int64_t>(Hi_32(p)) -
               static_cast<int64_t>(Hi_32(static_cast<uint64_t>(subres)));
    }
    bool isNeg = u[static_cast<unsigned>(j + static_cast<int>(n))] <
                 static_cast<uint64_t>(borrow);
    u[static_cast<unsigned>(j + static_cast<int>(n))] -=
        Lo_32(static_cast<uint64_t>(borrow));

    q[j] = Lo_32(qp);
    if (isNeg) {
      q[j]--;
      bool carry = false;
      for (unsigned i = 0; i < n; i++) {
        uint32_t limit =
            std::min(u[static_cast<unsigned>(j + static_cast<int>(i))], v[i]);
        u[static_cast<unsigned>(j + static_cast<int>(i))] += v[i] + carry;
        carry = u[static_cast<unsigned>(j + static_cast<int>(i))] < limit ||
                (carry &&
                 u[static_cast<unsigned>(j + static_cast<int>(i))] == limit);
      }
      u[static_cast<unsigned>(j + static_cast<int>(n))] += carry;
    }
  } while (--j >= 0);

  if (r) {
    if (shift) {
      uint32_t carry = 0;
      for (int i = static_cast<int>(n) - 1; i >= 0; i--) {
        r[i] = (u[i] >> shift) | carry;
        carry = u[i] << (32 - shift);
      }
    } else {
      for (int i = static_cast<int>(n) - 1; i >= 0; i--) {
        r[i] = u[i];
      }
    }
  }
}

inline void APInt::divide(const WordType *LHS, unsigned lhsWords,
                          const WordType *RHS, unsigned rhsWords,
                          WordType *Quotient, WordType *Remainder) {
  assert(lhsWords >= rhsWords && "Fractional result");

  unsigned n = rhsWords * 2;
  unsigned m = (lhsWords * 2) - n;

  uint32_t SPACE[128];
  uint32_t *U = nullptr;
  uint32_t *V = nullptr;
  uint32_t *Q = nullptr;
  uint32_t *R = nullptr;
  if ((Remainder ? 4 : 3) * n + 2 * m + 1 <= 128) {
    U = &SPACE[0];
    V = &SPACE[m + n + 1];
    Q = &SPACE[(m + n + 1) + n];
    if (Remainder)
      R = &SPACE[(m + n + 1) + n + (m + n)];
  } else {
    U = new uint32_t[m + n + 1];
    V = new uint32_t[n];
    Q = new uint32_t[m + n];
    if (Remainder)
      R = new uint32_t[n];
  }

  memset(U, 0, (m + n + 1) * sizeof(uint32_t));
  for (unsigned i = 0; i < lhsWords; ++i) {
    uint64_t tmp = LHS[i];
    U[i * 2] = Lo_32(tmp);
    U[i * 2 + 1] = Hi_32(tmp);
  }
  U[m + n] = 0; // this extra word is for "spill" in the Knuth algorithm.

  memset(V, 0, (n) * sizeof(uint32_t));
  for (unsigned i = 0; i < rhsWords; ++i) {
    uint64_t tmp = RHS[i];
    V[i * 2] = Lo_32(tmp);
    V[i * 2 + 1] = Hi_32(tmp);
  }

  memset(Q, 0, (m + n) * sizeof(uint32_t));
  if (Remainder)
    memset(R, 0, n * sizeof(uint32_t));

  for (unsigned i = n; i > 0 && V[i - 1] == 0; i--) {
    n--;
    m++;
  }
  for (unsigned i = m + n; i > 0 && U[i - 1] == 0; i--)
    m--;

  assert(n != 0 && "Divide by zero?");
  if (n == 1) {
    uint32_t divisor = V[0];
    uint32_t remainder = 0;
    for (int i = static_cast<int>(m); i >= 0; i--) {
      uint64_t partial_dividend = Make_64(remainder, U[i]);
      if (partial_dividend == 0) {
        Q[i] = 0;
        remainder = 0;
      } else if (partial_dividend < divisor) {
        Q[i] = 0;
        remainder = Lo_32(partial_dividend);
      } else if (partial_dividend == divisor) {
        Q[i] = 1;
        remainder = 0;
      } else {
        Q[i] = Lo_32(partial_dividend / divisor);
        remainder = Lo_32(partial_dividend - (Q[i] * divisor));
      }
    }
    if (R)
      R[0] = remainder;
  } else {
    KnuthDiv(U, V, Q, R, m, n);
  }

  if (Quotient) {
    for (unsigned i = 0; i < lhsWords; ++i)
      Quotient[i] = Make_64(Q[i * 2 + 1], Q[i * 2]);
  }

  if (Remainder) {
    for (unsigned i = 0; i < rhsWords; ++i)
      Remainder[i] = Make_64(R[i * 2 + 1], R[i * 2]);
  }

  if (U != &SPACE[0]) {
    delete[] U;
    delete[] V;
    delete[] Q;
    delete[] R;
  }
}

inline APInt APInt::udiv(const APInt &RHS) const {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");

  if (isSingleWord()) {
    assert(RHS.U.VAL != 0 && "Divide by zero?");
    return APInt(BitWidth, U.VAL / RHS.U.VAL);
  }

  unsigned lhsWords = getNumWords(getActiveBits());
  unsigned rhsBits = RHS.getActiveBits();
  unsigned rhsWords = getNumWords(rhsBits);
  assert(rhsWords && "Divided by zero???");

  if (!lhsWords)
    return APInt(BitWidth, 0);
  if (rhsBits == 1)
    return *this;
  if (lhsWords < rhsWords || this->ult(RHS))
    return APInt(BitWidth, 0);
  if (*this == RHS)
    return APInt(BitWidth, 1);
  if (lhsWords == 1) // rhsWords is 1 if lhsWords is 1.
    return APInt(BitWidth, this->U.pVal[0] / RHS.U.pVal[0]);

  APInt Quotient(BitWidth, 0); // to hold result.
  divide(U.pVal, lhsWords, RHS.U.pVal, rhsWords, Quotient.U.pVal, nullptr);
  return Quotient;
}

inline APInt APInt::udiv(uint64_t RHS) const {
  assert(RHS != 0 && "Divide by zero?");

  if (isSingleWord())
    return APInt(BitWidth, U.VAL / RHS);

  unsigned lhsWords = getNumWords(getActiveBits());

  if (!lhsWords)
    return APInt(BitWidth, 0);
  if (RHS == 1)
    return *this;
  if (this->ult(RHS))
    return APInt(BitWidth, 0);
  if (*this == RHS)
    return APInt(BitWidth, 1);
  if (lhsWords == 1) // rhsWords is 1 if lhsWords is 1.
    return APInt(BitWidth, this->U.pVal[0] / RHS);

  APInt Quotient(BitWidth, 0); // to hold result.
  divide(U.pVal, lhsWords, &RHS, 1, Quotient.U.pVal, nullptr);
  return Quotient;
}

inline APInt APInt::sdiv(const APInt &RHS) const {
  if (isNegative()) {
    if (RHS.isNegative())
      return (-(*this)).udiv(-RHS);
    return -((-(*this)).udiv(RHS));
  }
  if (RHS.isNegative())
    return -(this->udiv(-RHS));
  return this->udiv(RHS);
}

inline APInt APInt::sdiv(int64_t RHS) const {
  if (isNegative()) {
    if (RHS < 0)
      return (-(*this)).udiv(static_cast<uint64_t>(-RHS));
    return -((-(*this)).udiv(static_cast<uint64_t>(RHS)));
  }
  if (RHS < 0)
    return -(this->udiv(static_cast<uint64_t>(-RHS)));
  return this->udiv(static_cast<uint64_t>(RHS));
}

inline APInt APInt::urem(const APInt &RHS) const {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
  if (isSingleWord()) {
    assert(RHS.U.VAL != 0 && "Remainder by zero?");
    return APInt(BitWidth, U.VAL % RHS.U.VAL);
  }

  unsigned lhsWords = getNumWords(getActiveBits());
  unsigned rhsBits = RHS.getActiveBits();
  unsigned rhsWords = getNumWords(rhsBits);
  assert(rhsWords && "Performing remainder operation by zero ???");

  if (lhsWords == 0)
    return APInt(BitWidth, 0);
  if (rhsBits == 1)
    return APInt(BitWidth, 0);
  if (lhsWords < rhsWords || this->ult(RHS))
    return *this;
  if (*this == RHS)
    return APInt(BitWidth, 0);
  if (lhsWords == 1)
    return APInt(BitWidth, U.pVal[0] % RHS.U.pVal[0]);

  APInt Remainder(BitWidth, 0);
  divide(U.pVal, lhsWords, RHS.U.pVal, rhsWords, nullptr, Remainder.U.pVal);
  return Remainder;
}

inline uint64_t APInt::urem(uint64_t RHS) const {
  assert(RHS != 0 && "Remainder by zero?");

  if (isSingleWord())
    return U.VAL % RHS;

  unsigned lhsWords = getNumWords(getActiveBits());
  if (lhsWords == 0)
    return 0;
  if (RHS == 1)
    return 0;
  if (this->ult(RHS))
    return getZExtValue();
  if (*this == RHS)
    return 0;
  if (lhsWords == 1)
    return U.pVal[0] % RHS;

  uint64_t Remainder;
  divide(U.pVal, lhsWords, &RHS, 1, nullptr, &Remainder);
  return Remainder;
}

inline APInt APInt::srem(const APInt &RHS) const {
  if (isNegative()) {
    if (RHS.isNegative())
      return -(-(*this)).urem(-RHS);
    return -(-(*this)).urem(RHS);
  }
  if (RHS.isNegative())
    return this->urem(-RHS);
  return this->urem(RHS);
}

inline int64_t APInt::srem(int64_t RHS) const {
  if (isNegative()) {
    if (RHS < 0)
      return -static_cast<int64_t>(
          (-(*this)).urem(static_cast<uint64_t>(-RHS)));
    return -static_cast<int64_t>((-(*this)).urem(static_cast<uint64_t>(RHS)));
  }
  if (RHS < 0)
    return static_cast<int64_t>(this->urem(static_cast<uint64_t>(-RHS)));
  return static_cast<int64_t>(this->urem(static_cast<uint64_t>(RHS)));
}

inline void APInt::udivrem(const APInt &LHS, const APInt &RHS, APInt &Quotient,
                           APInt &Remainder) {
  assert(LHS.BitWidth == RHS.BitWidth && "Bit widths must be the same");
  unsigned BitWidth = LHS.BitWidth;

  if (LHS.isSingleWord()) {
    assert(RHS.U.VAL != 0 && "Divide by zero?");
    uint64_t QuotVal = LHS.U.VAL / RHS.U.VAL;
    uint64_t RemVal = LHS.U.VAL % RHS.U.VAL;
    Quotient = APInt(BitWidth, QuotVal);
    Remainder = APInt(BitWidth, RemVal);
    return;
  }

  unsigned lhsWords = getNumWords(LHS.getActiveBits());
  unsigned rhsBits = RHS.getActiveBits();
  unsigned rhsWords = getNumWords(rhsBits);
  assert(rhsWords && "Performing divrem operation by zero ???");

  if (lhsWords == 0) {
    Quotient = APInt(BitWidth, 0);  // 0 / Y ===> 0
    Remainder = APInt(BitWidth, 0); // 0 % Y ===> 0
    return;
  }

  if (rhsBits == 1) {
    Quotient = LHS;                 // X / 1 ===> X
    Remainder = APInt(BitWidth, 0); // X % 1 ===> 0
  }

  if (lhsWords < rhsWords || LHS.ult(RHS)) {
    Remainder = LHS;               // X % Y ===> X, iff X < Y
    Quotient = APInt(BitWidth, 0); // X / Y ===> 0, iff X < Y
    return;
  }

  if (LHS == RHS) {
    Quotient = APInt(BitWidth, 1);  // X / X ===> 1
    Remainder = APInt(BitWidth, 0); // X % X ===> 0;
    return;
  }

  Quotient.reallocate(BitWidth);
  Remainder.reallocate(BitWidth);

  if (lhsWords == 1) { // rhsWords is 1 if lhsWords is 1.
    uint64_t lhsValue = LHS.U.pVal[0];
    uint64_t rhsValue = RHS.U.pVal[0];
    Quotient = lhsValue / rhsValue;
    Remainder = lhsValue % rhsValue;
    return;
  }

  divide(LHS.U.pVal, lhsWords, RHS.U.pVal, rhsWords, Quotient.U.pVal,
         Remainder.U.pVal);
  std::memset(Quotient.U.pVal + lhsWords, 0,
              (getNumWords(BitWidth) - lhsWords) * APINT_WORD_SIZE);
  std::memset(Remainder.U.pVal + rhsWords, 0,
              (getNumWords(BitWidth) - rhsWords) * APINT_WORD_SIZE);
}

inline void APInt::udivrem(const APInt &LHS, uint64_t RHS, APInt &Quotient,
                           uint64_t &Remainder) {
  assert(RHS != 0 && "Divide by zero?");
  unsigned BitWidth = LHS.BitWidth;

  if (LHS.isSingleWord()) {
    uint64_t QuotVal = LHS.U.VAL / RHS;
    Remainder = LHS.U.VAL % RHS;
    Quotient = APInt(BitWidth, QuotVal);
    return;
  }

  unsigned lhsWords = getNumWords(LHS.getActiveBits());
  if (lhsWords == 0) {
    Quotient = APInt(BitWidth, 0); // 0 / Y ===> 0
    Remainder = 0;                 // 0 % Y ===> 0
    return;
  }

  if (RHS == 1) {
    Quotient = LHS; // X / 1 ===> X
    Remainder = 0;  // X % 1 ===> 0
    return;
  }

  if (LHS.ult(RHS)) {
    Remainder = LHS.getZExtValue(); // X % Y ===> X, iff X < Y
    Quotient = APInt(BitWidth, 0);  // X / Y ===> 0, iff X < Y
    return;
  }

  if (LHS == RHS) {
    Quotient = APInt(BitWidth, 1); // X / X ===> 1
    Remainder = 0;                 // X % X ===> 0;
    return;
  }

  Quotient.reallocate(BitWidth);

  if (lhsWords == 1) { // rhsWords is 1 if lhsWords is 1.
    uint64_t lhsValue = LHS.U.pVal[0];
    Quotient = lhsValue / RHS;
    Remainder = lhsValue % RHS;
    return;
  }

  divide(LHS.U.pVal, lhsWords, &RHS, 1, Quotient.U.pVal, &Remainder);
  std::memset(Quotient.U.pVal + lhsWords, 0,
              (getNumWords(BitWidth) - lhsWords) * APINT_WORD_SIZE);
}

inline void APInt::sdivrem(const APInt &LHS, const APInt &RHS, APInt &Quotient,
                           APInt &Remainder) {
  if (LHS.isNegative()) {
    if (RHS.isNegative())
      APInt::udivrem(-LHS, -RHS, Quotient, Remainder);
    else {
      APInt::udivrem(-LHS, RHS, Quotient, Remainder);
      Quotient.negate();
    }
    Remainder.negate();
  } else if (RHS.isNegative()) {
    APInt::udivrem(LHS, -RHS, Quotient, Remainder);
    Quotient.negate();
  } else {
    APInt::udivrem(LHS, RHS, Quotient, Remainder);
  }
}

inline void APInt::sdivrem(const APInt &LHS, int64_t RHS, APInt &Quotient,
                           int64_t &Remainder) {
  uint64_t R = static_cast<uint64_t>(Remainder);
  if (LHS.isNegative()) {
    if (RHS < 0)
      APInt::udivrem(-LHS, static_cast<uint64_t>(-RHS), Quotient, R);
    else {
      APInt::udivrem(-LHS, static_cast<uint64_t>(RHS), Quotient, R);
      Quotient.negate();
    }
    R = -R;
  } else if (RHS < 0) {
    APInt::udivrem(LHS, static_cast<uint64_t>(-RHS), Quotient, R);
    Quotient.negate();
  } else {
    APInt::udivrem(LHS, static_cast<uint64_t>(RHS), Quotient, R);
  }
  Remainder = static_cast<int64_t>(R);
}

inline APInt APInt::sadd_ov(const APInt &RHS, bool &Overflow) const {
  APInt Res = *this + RHS;
  Overflow = isNonNegative() == RHS.isNonNegative() &&
             Res.isNonNegative() != isNonNegative();
  return Res;
}

inline APInt APInt::uadd_ov(const APInt &RHS, bool &Overflow) const {
  APInt Res = *this + RHS;
  Overflow = Res.ult(RHS);
  return Res;
}

inline APInt APInt::ssub_ov(const APInt &RHS, bool &Overflow) const {
  APInt Res = *this - RHS;
  Overflow = isNonNegative() != RHS.isNonNegative() &&
             Res.isNonNegative() != isNonNegative();
  return Res;
}

inline APInt APInt::usub_ov(const APInt &RHS, bool &Overflow) const {
  APInt Res = *this - RHS;
  Overflow = Res.ugt(*this);
  return Res;
}

inline APInt APInt::sdiv_ov(const APInt &RHS, bool &Overflow) const {
  // MININT/-1  -->  overflow.
  Overflow = isMinSignedValue() && RHS.isAllOnes();
  return sdiv(RHS);
}

inline APInt APInt::smul_ov(const APInt &RHS, bool &Overflow) const {
  APInt Res = *this * RHS;

  if (RHS != 0)
    Overflow =
        Res.sdiv(RHS) != *this || (isMinSignedValue() && RHS.isAllOnes());
  else
    Overflow = false;
  return Res;
}

inline APInt APInt::umul_ov(const APInt &RHS, bool &Overflow) const {
  if (countl_zero() + RHS.countl_zero() + 2 <= BitWidth) {
    Overflow = true;
    return *this * RHS;
  }

  APInt Res = lshr(1) * RHS;
  Overflow = Res.isNegative();
  Res <<= 1;
  if ((*this)[0]) {
    Res += RHS;
    if (Res.ult(RHS))
      Overflow = true;
  }
  return Res;
}

inline APInt APInt::sshl_ov(const APInt &ShAmt, bool &Overflow) const {
  return sshl_ov(static_cast<unsigned>(ShAmt.getLimitedValue(getBitWidth())),
                 Overflow);
}

inline APInt APInt::sshl_ov(unsigned ShAmt, bool &Overflow) const {
  Overflow = ShAmt >= getBitWidth();
  if (Overflow)
    return APInt(BitWidth, 0);

  if (isNonNegative()) // Don't allow sign change.
    Overflow = ShAmt >= countl_zero();
  else
    Overflow = ShAmt >= countl_one();

  return *this << ShAmt;
}

inline APInt APInt::ushl_ov(const APInt &ShAmt, bool &Overflow) const {
  return ushl_ov(static_cast<unsigned>(ShAmt.getLimitedValue(getBitWidth())),
                 Overflow);
}

inline APInt APInt::ushl_ov(unsigned ShAmt, bool &Overflow) const {
  Overflow = ShAmt >= getBitWidth();
  if (Overflow)
    return APInt(BitWidth, 0);

  Overflow = ShAmt > countl_zero();

  return *this << ShAmt;
}

inline APInt APInt::sfloordiv_ov(const APInt &RHS, bool &Overflow) const {
  APInt quotient = sdiv_ov(RHS, Overflow);
  if ((quotient * RHS != *this) && (isNegative() != RHS.isNegative()))
    return quotient - 1;
  return quotient;
}

inline APInt APInt::sadd_sat(const APInt &RHS) const {
  bool Overflow;
  APInt Res = sadd_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return isNegative() ? APInt::getSignedMinValue(BitWidth)
                      : APInt::getSignedMaxValue(BitWidth);
}

inline APInt APInt::uadd_sat(const APInt &RHS) const {
  bool Overflow;
  APInt Res = uadd_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return APInt::getMaxValue(BitWidth);
}

inline APInt APInt::ssub_sat(const APInt &RHS) const {
  bool Overflow;
  APInt Res = ssub_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return isNegative() ? APInt::getSignedMinValue(BitWidth)
                      : APInt::getSignedMaxValue(BitWidth);
}

inline APInt APInt::usub_sat(const APInt &RHS) const {
  bool Overflow;
  APInt Res = usub_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return APInt(BitWidth, 0);
}

inline APInt APInt::smul_sat(const APInt &RHS) const {
  bool Overflow;
  APInt Res = smul_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  // The result is negative if one and only one of inputs is negative.
  bool ResIsNegative = isNegative() ^ RHS.isNegative();

  return ResIsNegative ? APInt::getSignedMinValue(BitWidth)
                       : APInt::getSignedMaxValue(BitWidth);
}

inline APInt APInt::umul_sat(const APInt &RHS) const {
  bool Overflow;
  APInt Res = umul_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return APInt::getMaxValue(BitWidth);
}

inline APInt APInt::sshl_sat(const APInt &RHS) const {
  return sshl_sat(static_cast<unsigned>(RHS.getLimitedValue(getBitWidth())));
}

inline APInt APInt::sshl_sat(unsigned RHS) const {
  bool Overflow;
  APInt Res = sshl_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return isNegative() ? APInt::getSignedMinValue(BitWidth)
                      : APInt::getSignedMaxValue(BitWidth);
}

inline APInt APInt::ushl_sat(const APInt &RHS) const {
  return ushl_sat(static_cast<unsigned>(RHS.getLimitedValue(getBitWidth())));
}

inline APInt APInt::ushl_sat(unsigned RHS) const {
  bool Overflow;
  APInt Res = ushl_ov(RHS, Overflow);
  if (!Overflow)
    return Res;

  return APInt::getMaxValue(BitWidth);
}

static_assert(APInt::APINT_BITS_PER_WORD % 2 == 0,
              "Part width must be divisible by 2!");

static inline APInt::WordType lowBitMask(unsigned bits) {
  assert(bits != 0 && bits <= APInt::APINT_BITS_PER_WORD);
  return ~static_cast<APInt::WordType>(0) >>
         (APInt::APINT_BITS_PER_WORD - bits);
}
static inline APInt::WordType lowHalf(APInt::WordType part) {
  return part & lowBitMask(APInt::APINT_BITS_PER_WORD / 2);
}
static inline APInt::WordType highHalf(APInt::WordType part) {
  return part >> (APInt::APINT_BITS_PER_WORD / 2);
}
inline void APInt::tcSet(WordType *dst, WordType part, unsigned parts) {
  assert(parts > 0);
  dst[0] = part;
  for (unsigned i = 1; i < parts; i++)
    dst[i] = 0;
}
inline void APInt::tcAssign(WordType *dst, const WordType *src,
                            unsigned parts) {
  for (unsigned i = 0; i < parts; i++)
    dst[i] = src[i];
}
inline unsigned APInt::tcMSB(const WordType *parts, unsigned n) {
  do {
    --n;

    if (parts[n] != 0) {
      static_assert(sizeof(parts[n]) <= sizeof(uint64_t));
      unsigned msb = Log2_64(parts[n]);

      return msb + n * APINT_BITS_PER_WORD;
    }
  } while (n);

  return UINT_MAX;
}
inline APInt::WordType APInt::tcAdd(WordType *dst, const WordType *rhs,
                                    WordType c, unsigned parts) {
  assert(c <= 1);

  for (unsigned i = 0; i < parts; i++) {
    WordType l = dst[i];
    if (c) {
      dst[i] += rhs[i] + 1;
      c = (dst[i] <= l);
    } else {
      dst[i] += rhs[i];
      c = (dst[i] < l);
    }
  }

  return c;
}

inline APInt::WordType APInt::tcAddPart(WordType *dst, WordType src,
                                        unsigned parts) {
  for (unsigned i = 0; i < parts; ++i) {
    dst[i] += src;
    if (dst[i] >= src)
      return 0; // No need to carry so exit early.
    src = 1;    // Carry one to next digit.
  }

  return 1;
}

inline APInt::WordType APInt::tcSubtract(WordType *dst, const WordType *rhs,
                                         WordType c, unsigned parts) {
  assert(c <= 1);

  for (unsigned i = 0; i < parts; i++) {
    WordType l = dst[i];
    if (c) {
      dst[i] -= rhs[i] + 1;
      c = (dst[i] >= l);
    } else {
      dst[i] -= rhs[i];
      c = (dst[i] > l);
    }
  }

  return c;
}

inline APInt::WordType APInt::tcSubtractPart(WordType *dst, WordType src,
                                             unsigned parts) {
  for (unsigned i = 0; i < parts; ++i) {
    WordType Dst = dst[i];
    dst[i] -= src;
    if (src <= Dst)
      return 0; // No need to borrow so exit early.
    src = 1;    // We have to "borrow 1" from next "word"
  }

  return 1;
}

inline int APInt::tcMultiplyPart(WordType *dst, const WordType *src,
                                 WordType multiplier, WordType carry,
                                 unsigned srcParts, unsigned dstParts,
                                 bool add) {
  // Otherwise our writes of DST kill our later reads of SRC.
  assert(dst <= src || dst >= src + srcParts);
  assert(dstParts <= srcParts + 1);
  unsigned n = std::min(dstParts, srcParts);

  for (unsigned i = 0; i < n; i++) {
    WordType srcPart = src[i];
    WordType low, mid, high;
    if (multiplier == 0 || srcPart == 0) {
      low = carry;
      high = 0;
    } else {
      low = lowHalf(srcPart) * lowHalf(multiplier);
      high = highHalf(srcPart) * highHalf(multiplier);

      mid = lowHalf(srcPart) * highHalf(multiplier);
      high += highHalf(mid);
      mid <<= APINT_BITS_PER_WORD / 2;
      if (low + mid < low)
        high++;
      low += mid;

      mid = highHalf(srcPart) * lowHalf(multiplier);
      high += highHalf(mid);
      mid <<= APINT_BITS_PER_WORD / 2;
      if (low + mid < low)
        high++;
      low += mid;

      // Now add carry.
      if (low + carry < low)
        high++;
      low += carry;
    }

    if (add) {
      // And now DST[i], and store the new low part there.
      if (low + dst[i] < low)
        high++;
      dst[i] += low;
    } else {
      dst[i] = low;
    }

    carry = high;
  }

  if (srcParts < dstParts) {
    assert(srcParts + 1 == dstParts);
    dst[srcParts] = carry;
    return 0;
  }
  if (carry)
    return 1;

  if (multiplier)
    for (unsigned i = dstParts; i < srcParts; i++)
      if (src[i])
        return 1;

  return 0;
}

inline int APInt::tcMultiply(WordType *dst, const WordType *lhs,
                             const WordType *rhs, unsigned parts) {
  assert(dst != lhs && dst != rhs);

  int overflow = 0;

  for (unsigned i = 0; i < parts; i++) {
    overflow |=
        tcMultiplyPart(&dst[i], lhs, rhs[i], 0, parts, parts - i, i != 0);
  }

  return overflow;
}

inline int APInt::tcDivide(WordType *lhs, const WordType *rhs,
                           WordType *remainder, WordType *srhs,
                           unsigned parts) {
  assert(lhs != remainder && lhs != srhs && remainder != srhs);

  unsigned shiftCount = tcMSB(rhs, parts) + 1;
  if (shiftCount == 0)
    return true;

  shiftCount = parts * APINT_BITS_PER_WORD - shiftCount;
  unsigned n = shiftCount / APINT_BITS_PER_WORD;
  WordType mask = static_cast<WordType>(1)
                  << (shiftCount % APINT_BITS_PER_WORD);

  tcAssign(srhs, rhs, parts);
  tcShiftLeft(srhs, parts, shiftCount);
  tcAssign(remainder, lhs, parts);
  tcSet(lhs, 0, parts);

  for (;;) {
    int compare = tcCompare(remainder, srhs, parts);
    if (compare >= 0) {
      tcSubtract(remainder, srhs, 0, parts);
      lhs[n] |= mask;
    }

    if (shiftCount == 0)
      break;
    shiftCount--;
    tcShiftRight(srhs, parts, 1);
    if ((mask >>= 1) == 0) {
      mask = static_cast<WordType>(1) << (APINT_BITS_PER_WORD - 1);
      n--;
    }
  }

  return false;
}

inline void APInt::tcShiftLeft(WordType *Dst, unsigned Words, unsigned Count) {
  if (!Count)
    return;

  // WordShift is the inter-part shift; BitShift is the intra-part shift.
  unsigned WordShift = std::min(Count / APINT_BITS_PER_WORD, Words);
  unsigned BitShift = Count % APINT_BITS_PER_WORD;

  // Fastpath for moving by whole words.
  if (BitShift == 0) {
    std::memmove(Dst + WordShift, Dst, (Words - WordShift) * APINT_WORD_SIZE);
  } else {
    while (Words-- > WordShift) {
      Dst[Words] = Dst[Words - WordShift] << BitShift;
      if (Words > WordShift)
        Dst[Words] |=
            Dst[Words - WordShift - 1] >> (APINT_BITS_PER_WORD - BitShift);
    }
  }

  // Fill in the remainder with 0s.
  std::memset(Dst, 0, WordShift * APINT_WORD_SIZE);
}

/// Shift a bignum right Count bits in-place. Shifted in bits are zero. There
/// are no restrictions on Count.
inline void APInt::tcShiftRight(WordType *Dst, unsigned Words, unsigned Count) {
  // Don't bother performing a no-op shift.
  if (!Count)
    return;

  // WordShift is the inter-part shift; BitShift is the intra-part shift.
  unsigned WordShift = std::min(Count / APINT_BITS_PER_WORD, Words);
  unsigned BitShift = Count % APINT_BITS_PER_WORD;

  unsigned WordsToMove = Words - WordShift;
  // Fastpath for moving by whole words.
  if (BitShift == 0) {
    std::memmove(Dst, Dst + WordShift, WordsToMove * APINT_WORD_SIZE);
  } else {
    for (unsigned i = 0; i != WordsToMove; ++i) {
      Dst[i] = Dst[i + WordShift] >> BitShift;
      if (i + 1 != WordsToMove)
        Dst[i] |= Dst[i + WordShift + 1] << (APINT_BITS_PER_WORD - BitShift);
    }
  }

  // Fill in the remainder with 0s.
  std::memset(Dst + WordsToMove, 0, WordShift * APINT_WORD_SIZE);
}

// Comparison (unsigned) of two bignums.
inline int APInt::tcCompare(const WordType *lhs, const WordType *rhs,
                            unsigned parts) {
  while (parts) {
    parts--;
    if (lhs[parts] != rhs[parts])
      return (lhs[parts] > rhs[parts]) ? 1 : -1;
  }

  return 0;
}

inline std::optional<unsigned>
llvm::APIntOps::GetMostSignificantDifferentBit(const APInt &A, const APInt &B) {
  assert(A.getBitWidth() == B.getBitWidth() && "Bitwidth mismatch");
  if (A == B)
    return std::nullopt;
  return A.getBitWidth() - ((A ^ B).countl_zero() + 1);
}

} // namespace llvm

#endif
