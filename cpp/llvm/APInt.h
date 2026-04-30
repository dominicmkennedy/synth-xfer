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
template <typename T> static inline T reverseBits(T v) {
  T out = 0;
  for (unsigned i = 0; i < sizeof(T) * CHAR_BIT; ++i) {
    out <<= 1;
    out |= (v & 1);
    v >>= 1;
  }
  return out;
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

  /// If this value is smaller than the specified limit, return it, otherwise
  /// return the limit value.  This causes the value to saturate to the limit.
  uint64_t getLimitedValue(uint64_t Limit = UINT64_MAX) const {
    return ugt(Limit) ? Limit : getZExtValue();
  }

  bool isSplat(unsigned SplatSizeInBits) const;
  APInt getHiBits(unsigned numBits) const;
  APInt getLoBits(unsigned numBits) const;

  /// Determine if two APInts have the same value, after zero-extending
  /// one of them (if needed!) to ensure that the bit-widths match.
  static bool isSameValue(const APInt &I1, const APInt &I2) {
    if (I1.getBitWidth() == I2.getBitWidth())
      return I1 == I2;

    if (I1.getBitWidth() > I2.getBitWidth())
      return I1 == I2.zext(I1.getBitWidth());

    return I1.zext(I2.getBitWidth()) == I2;
  }

  /// This function returns a pointer to the internal storage of the APInt.
  /// This is useful for writing out the APInt in binary form without any
  /// conversions.
  const uint64_t *getRawData() const {
    if (isSingleWord())
      return &U.VAL;
    return &U.pVal[0];
  }

  /// @}
  /// \name Unary Operators
  /// @{

  /// Postfix increment operator.  Increment *this by 1.
  ///
  /// \returns a new APInt value representing the original value of *this.
  APInt operator++(int) {
    APInt API(*this);
    ++(*this);
    return API;
  }

  /// Prefix increment operator.
  ///
  /// \returns *this incremented by one
  APInt &operator++();

  /// Postfix decrement operator. Decrement *this by 1.
  ///
  /// \returns a new APInt value representing the original value of *this.
  APInt operator--(int) {
    APInt API(*this);
    --(*this);
    return API;
  }

  /// Prefix decrement operator.
  ///
  /// \returns *this decremented by one.
  APInt &operator--();

  /// Logical negation operation on this APInt returns true if zero, like normal
  /// integers.
  bool operator!() const { return isZero(); }

  /// @}
  /// \name Assignment Operators
  /// @{

  /// Copy assignment operator.
  ///
  /// \returns *this after assignment of RHS.
  APInt &operator=(const APInt &RHS) {
    // The common case (both source or dest being inline) doesn't require
    // allocation or deallocation.
    if (isSingleWord() && RHS.isSingleWord()) {
      U.VAL = RHS.U.VAL;
      BitWidth = RHS.BitWidth;
      return *this;
    }

    assignSlowCase(RHS);
    return *this;
  }

  /// Move assignment operator.
  APInt &operator=(APInt &&that) {
    assert(this != &that && "Self-move not supported");
    if (!isSingleWord())
      delete[] U.pVal;

    // Use memcpy so that type based alias analysis sees both VAL and pVal
    // as modified.
    memcpy(&U, &that.U, sizeof(U));

    BitWidth = that.BitWidth;
    that.BitWidth = 0;
    return *this;
  }

  /// Assignment operator.
  ///
  /// The RHS value is assigned to *this. If the significant bits in RHS exceed
  /// the bit width, the excess bits are truncated. If the bit width is larger
  /// than 64, the value is zero filled in the unspecified high order bits.
  ///
  /// \returns *this after assignment of RHS value.
  APInt &operator=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL = RHS;
      return clearUnusedBits();
    }
    U.pVal[0] = RHS;
    memset(U.pVal + 1, 0, (getNumWords() - 1) * APINT_WORD_SIZE);
    return *this;
  }

  /// Bitwise AND assignment operator.
  ///
  /// Performs a bitwise AND operation on this APInt and RHS. The result is
  /// assigned to *this.
  ///
  /// \returns *this after ANDing with RHS.
  APInt &operator&=(const APInt &RHS) {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      U.VAL &= RHS.U.VAL;
    else
      andAssignSlowCase(RHS);
    return *this;
  }

  /// Bitwise AND assignment operator.
  ///
  /// Performs a bitwise AND operation on this APInt and RHS. RHS is
  /// logically zero-extended or truncated to match the bit-width of
  /// the LHS.
  APInt &operator&=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL &= RHS;
      return *this;
    }
    U.pVal[0] &= RHS;
    memset(U.pVal + 1, 0, (getNumWords() - 1) * APINT_WORD_SIZE);
    return *this;
  }

  /// Bitwise OR assignment operator.
  ///
  /// Performs a bitwise OR operation on this APInt and RHS. The result is
  /// assigned *this;
  ///
  /// \returns *this after ORing with RHS.
  APInt &operator|=(const APInt &RHS) {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      U.VAL |= RHS.U.VAL;
    else
      orAssignSlowCase(RHS);
    return *this;
  }

  /// Bitwise OR assignment operator.
  ///
  /// Performs a bitwise OR operation on this APInt and RHS. RHS is
  /// logically zero-extended or truncated to match the bit-width of
  /// the LHS.
  APInt &operator|=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL |= RHS;
      return clearUnusedBits();
    }
    U.pVal[0] |= RHS;
    return *this;
  }

  /// Bitwise XOR assignment operator.
  ///
  /// Performs a bitwise XOR operation on this APInt and RHS. The result is
  /// assigned to *this.
  ///
  /// \returns *this after XORing with RHS.
  APInt &operator^=(const APInt &RHS) {
    assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");
    if (isSingleWord())
      U.VAL ^= RHS.U.VAL;
    else
      xorAssignSlowCase(RHS);
    return *this;
  }

  /// Bitwise XOR assignment operator.
  ///
  /// Performs a bitwise XOR operation on this APInt and RHS. RHS is
  /// logically zero-extended or truncated to match the bit-width of
  /// the LHS.
  APInt &operator^=(uint64_t RHS) {
    if (isSingleWord()) {
      U.VAL ^= RHS;
      return clearUnusedBits();
    }
    U.pVal[0] ^= RHS;
    return *this;
  }

  /// Multiplication assignment operator.
  ///
  /// Multiplies this APInt by RHS and assigns the result to *this.
  ///
  /// \returns *this
  APInt &operator*=(const APInt &RHS);
  APInt &operator*=(uint64_t RHS);

  /// Addition assignment operator.
  ///
  /// Adds RHS to *this and assigns the result to *this.
  ///
  /// \returns *this
  APInt &operator+=(const APInt &RHS);
  APInt &operator+=(uint64_t RHS);

  /// Subtraction assignment operator.
  ///
  /// Subtracts RHS from *this and assigns the result to *this.
  ///
  /// \returns *this
  APInt &operator-=(const APInt &RHS);
  APInt &operator-=(uint64_t RHS);

  /// Left-shift assignment function.
  ///
  /// Shifts *this left by shiftAmt and assigns the result to *this.
  ///
  /// \returns *this after shifting left by ShiftAmt
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

  /// Left-shift assignment function.
  ///
  /// Shifts *this left by shiftAmt and assigns the result to *this.
  ///
  /// \returns *this after shifting left by ShiftAmt
  APInt &operator<<=(const APInt &ShiftAmt);

  /// @}
  /// \name Binary Operators
  /// @{

  /// Multiplication operator.
  ///
  /// Multiplies this APInt by RHS and returns the result.
  APInt operator*(const APInt &RHS) const;

  /// Left logical shift operator.
  ///
  /// Shifts this APInt left by \p Bits and returns the result.
  APInt operator<<(unsigned Bits) const { return shl(Bits); }

  /// Left logical shift operator.
  ///
  /// Shifts this APInt left by \p Bits and returns the result.
  APInt operator<<(const APInt &Bits) const { return shl(Bits); }

  /// Arithmetic right-shift function.
  ///
  /// Arithmetic right-shift this APInt by shiftAmt.
  APInt ashr(unsigned ShiftAmt) const {
    APInt R(*this);
    R.ashrInPlace(ShiftAmt);
    return R;
  }

  /// Arithmetic right-shift this APInt by ShiftAmt in place.
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

  /// Logical right-shift function.
  ///
  /// Logical right-shift this APInt by shiftAmt.
  APInt lshr(unsigned shiftAmt) const {
    APInt R(*this);
    R.lshrInPlace(shiftAmt);
    return R;
  }

  /// Logical right-shift this APInt by ShiftAmt in place.
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

  /// Left-shift function.
  ///
  /// Left-shift this APInt by shiftAmt.
  APInt shl(unsigned shiftAmt) const {
    APInt R(*this);
    R <<= shiftAmt;
    return R;
  }

  /// relative logical shift right
  APInt relativeLShr(int RelativeShift) const {
    return RelativeShift > 0 ? lshr(static_cast<unsigned>(RelativeShift))
                             : shl(static_cast<unsigned>(-RelativeShift));
  }

  /// relative logical shift left
  APInt relativeLShl(int RelativeShift) const {
    return relativeLShr(-RelativeShift);
  }

  /// relative arithmetic shift right
  APInt relativeAShr(int RelativeShift) const {
    return RelativeShift > 0 ? ashr(static_cast<unsigned>(RelativeShift))
                             : shl(static_cast<unsigned>(-RelativeShift));
  }

  /// relative arithmetic shift left
  APInt relativeAShl(int RelativeShift) const {
    return relativeAShr(-RelativeShift);
  }

  /// Rotate left by rotateAmt.
  APInt rotl(unsigned rotateAmt) const;

  /// Rotate right by rotateAmt.
  APInt rotr(unsigned rotateAmt) const;

  /// Arithmetic right-shift function.
  ///
  /// Arithmetic right-shift this APInt by shiftAmt.
  APInt ashr(const APInt &ShiftAmt) const {
    APInt R(*this);
    R.ashrInPlace(ShiftAmt);
    return R;
  }

  /// Arithmetic right-shift this APInt by shiftAmt in place.
  void ashrInPlace(const APInt &shiftAmt);

  /// Logical right-shift function.
  ///
  /// Logical right-shift this APInt by shiftAmt.
  APInt lshr(const APInt &ShiftAmt) const {
    APInt R(*this);
    R.lshrInPlace(ShiftAmt);
    return R;
  }

  /// Logical right-shift this APInt by ShiftAmt in place.
  void lshrInPlace(const APInt &ShiftAmt);

  /// Left-shift function.
  ///
  /// Left-shift this APInt by shiftAmt.
  APInt shl(const APInt &ShiftAmt) const {
    APInt R(*this);
    R <<= ShiftAmt;
    return R;
  }

  /// Rotate left by rotateAmt.
  APInt rotl(const APInt &rotateAmt) const;

  /// Rotate right by rotateAmt.
  APInt rotr(const APInt &rotateAmt) const;

  /// Unsigned division operation.
  ///
  /// Perform an unsigned divide operation on this APInt by RHS. Both this and
  /// RHS are treated as unsigned quantities for purposes of this division.
  ///
  /// \returns a new APInt value containing the division result, rounded towards
  /// zero.
  APInt udiv(const APInt &RHS) const;
  APInt udiv(uint64_t RHS) const;

  /// Signed division function for APInt.
  ///
  /// Signed divide this APInt by APInt RHS.
  ///
  /// The result is rounded towards zero.
  APInt sdiv(const APInt &RHS) const;
  APInt sdiv(int64_t RHS) const;

  /// Unsigned remainder operation.
  ///
  /// Perform an unsigned remainder operation on this APInt with RHS being the
  /// divisor. Both this and RHS are treated as unsigned quantities for purposes
  /// of this operation.
  ///
  /// \returns a new APInt value containing the remainder result
  APInt urem(const APInt &RHS) const;
  uint64_t urem(uint64_t RHS) const;

  /// Function for signed remainder operation.
  ///
  /// Signed remainder operation on APInt.
  ///
  /// Note that this is a true remainder operation and not a modulo operation
  /// because the sign follows the sign of the dividend which is *this.
  APInt srem(const APInt &RHS) const;
  int64_t srem(int64_t RHS) const;

  /// Dual division/remainder interface.
  ///
  /// Sometimes it is convenient to divide two APInt values and obtain both the
  /// quotient and remainder. This function does both operations in the same
  /// computation making it a little more efficient. The pair of input arguments
  /// may overlap with the pair of output arguments. It is safe to call
  /// udivrem(X, Y, X, Y), for example.
  static void udivrem(const APInt &LHS, const APInt &RHS, APInt &Quotient,
                      APInt &Remainder);
  static void udivrem(const APInt &LHS, uint64_t RHS, APInt &Quotient,
                      uint64_t &Remainder);

  static void sdivrem(const APInt &LHS, const APInt &RHS, APInt &Quotient,
                      APInt &Remainder);
  static void sdivrem(const APInt &LHS, int64_t RHS, APInt &Quotient,
                      int64_t &Remainder);

  // Operations that return overflow indicators.
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

  /// Signed integer floor division operation.
  ///
  /// Rounds towards negative infinity, i.e. 5 / -2 = -3. Iff minimum value
  /// divided by -1 set Overflow to true.
  APInt sfloordiv_ov(const APInt &RHS, bool &Overflow) const;

  // Operations that saturate
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

  /// Array-indexing support.
  ///
  /// \returns the bit value at bitPosition
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

  /// @}
  /// \name Bit Manipulation Operators
  /// @{

  /// Set every bit to 1.
  void setAllBits() {
    if (isSingleWord())
      U.VAL = WORDTYPE_MAX;
    else
      // Set all the bits in all the words.
      memset(U.pVal, -1, getNumWords() * APINT_WORD_SIZE);
    // Clear the unused ones
    clearUnusedBits();
  }

  /// Set the given bit to 1 whose position is given as "bitPosition".
  void setBit(unsigned BitPosition) {
    assert(BitPosition < BitWidth && "BitPosition out of range");
    WordType Mask = maskBit(BitPosition);
    if (isSingleWord())
      U.VAL |= Mask;
    else
      U.pVal[whichWord(BitPosition)] |= Mask;
  }

  /// Set the sign bit to 1.
  void setSignBit() { setBit(BitWidth - 1); }

  /// Set a given bit to a given value.
  void setBitVal(unsigned BitPosition, bool BitValue) {
    if (BitValue)
      setBit(BitPosition);
    else
      clearBit(BitPosition);
  }

  /// Set the bits from loBit (inclusive) to hiBit (exclusive) to 1.
  /// This function handles "wrap" case when \p loBit >= \p hiBit, and calls
  /// setBits when \p loBit < \p hiBit.
  /// For \p loBit == \p hiBit wrap case, set every bit to 1.
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

  /// Set the bits from loBit (inclusive) to hiBit (exclusive) to 1.
  /// This function handles case when \p loBit <= \p hiBit.
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

  /// Set the top bits starting from loBit.
  void setBitsFrom(unsigned loBit) { return setBits(loBit, BitWidth); }

  /// Set the bottom loBits bits.
  void setLowBits(unsigned loBits) { return setBits(0, loBits); }

  /// Set the top hiBits bits.
  void setHighBits(unsigned hiBits) {
    return setBits(BitWidth - hiBits, BitWidth);
  }

  /// Set every bit to 0.
  void clearAllBits() {
    if (isSingleWord())
      U.VAL = 0;
    else
      memset(U.pVal, 0, getNumWords() * APINT_WORD_SIZE);
  }

  /// Set a given bit to 0.
  ///
  /// Set the given bit to 0 whose position is given as "bitPosition".
  void clearBit(unsigned BitPosition) {
    assert(BitPosition < BitWidth && "BitPosition out of range");
    WordType Mask = ~maskBit(BitPosition);
    if (isSingleWord())
      U.VAL &= Mask;
    else
      U.pVal[whichWord(BitPosition)] &= Mask;
  }

  /// Clear the bits from LoBit (inclusive) to HiBit (exclusive) to 0.
  /// This function handles case when \p LoBit <= \p HiBit.
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

  /// Set bottom loBits bits to 0.
  void clearLowBits(unsigned loBits) {
    assert(loBits <= BitWidth && "More bits than bitwidth");
    APInt Keep = getHighBitsSet(BitWidth, BitWidth - loBits);
    *this &= Keep;
  }

  /// Set top hiBits bits to 0.
  void clearHighBits(unsigned hiBits) {
    assert(hiBits <= BitWidth && "More bits than bitwidth");
    APInt Keep = getLowBitsSet(BitWidth, BitWidth - hiBits);
    *this &= Keep;
  }

  /// Set the sign bit to 0.
  void clearSignBit() { clearBit(BitWidth - 1); }

  /// Toggle every bit to its opposite value.
  void flipAllBits() {
    if (isSingleWord()) {
      U.VAL ^= WORDTYPE_MAX;
      clearUnusedBits();
    } else {
      flipAllBitsSlowCase();
    }
  }

  /// Toggles a given bit to its opposite value.
  ///
  /// Toggle a given bit to its opposite value whose position is given
  /// as "bitPosition".
  void flipBit(unsigned bitPosition);

  /// Negate this APInt in place.
  void negate() {
    flipAllBits();
    ++(*this);
  }

  /// Insert the bits from a smaller APInt starting at bitPosition.
  void insertBits(const APInt &SubBits, unsigned bitPosition);
  void insertBits(uint64_t SubBits, unsigned bitPosition, unsigned numBits);

  /// Return an APInt with the extracted bits [bitPosition,bitPosition+numBits).
  APInt extractBits(unsigned numBits, unsigned bitPosition) const;
  uint64_t extractBitsAsZExtValue(unsigned numBits, unsigned bitPosition) const;

  /// @}
  /// \name Value Characterization Functions
  /// @{

  /// Return the number of bits in the APInt.
  unsigned getBitWidth() const { return BitWidth; }

  /// Get the number of words.
  ///
  /// Here one word's bitwidth equals to that of uint64_t.
  ///
  /// \returns the number of words to hold the integer value of this APInt.
  unsigned getNumWords() const { return getNumWords(BitWidth); }

  /// Get the number of words.
  ///
  /// *NOTE* Here one word's bitwidth equals to that of uint64_t.
  ///
  /// \returns the number of words to hold the integer value with a given bit
  /// width.
  static unsigned getNumWords(unsigned BitWidth) {
    return static_cast<unsigned>(
        (static_cast<uint64_t>(BitWidth) + APINT_BITS_PER_WORD - 1) /
        APINT_BITS_PER_WORD);
  }

  /// Compute the number of active bits in the value
  ///
  /// This function returns the number of active bits which is defined as the
  /// bit width minus the number of leading zeros. This is used in several
  /// computations to see how "wide" the value is.
  unsigned getActiveBits() const { return BitWidth - countl_zero(); }

  /// Compute the number of active words in the value of this APInt.
  ///
  /// This is used in conjunction with getActiveData to extract the raw value of
  /// the APInt.
  unsigned getActiveWords() const {
    unsigned numActiveBits = getActiveBits();
    return numActiveBits ? whichWord(numActiveBits - 1) + 1 : 1;
  }

  /// Get the minimum bit size for this signed APInt
  ///
  /// Computes the minimum bit width for this APInt while considering it to be a
  /// signed (and probably negative) value. If the value is not negative, this
  /// function returns the same value as getActiveBits()+1. Otherwise, it
  /// returns the smallest bit width that will retain the negative value. For
  /// example, -1 can be written as 0b1 or 0xFFFFFFFFFF. 0b1 is shorter and so
  /// for -1, this function will always return 1.
  unsigned getSignificantBits() const {
    return BitWidth - getNumSignBits() + 1;
  }

  /// Get zero extended value
  ///
  /// This method attempts to return the value of this APInt as a zero extended
  /// uint64_t. The bitwidth must be <= 64 or the value must fit within a
  /// uint64_t. Otherwise an assertion will result.
  uint64_t getZExtValue() const {
    if (isSingleWord())
      return U.VAL;
    assert(getActiveBits() <= 64 && "Too many bits for uint64_t");
    return U.pVal[0];
  }

  /// Get zero extended value if possible
  ///
  /// This method attempts to return the value of this APInt as a zero extended
  /// uint64_t. The bitwidth must be <= 64 or the value must fit within a
  /// uint64_t. Otherwise no value is returned.
  std::optional<uint64_t> tryZExtValue() const {
    return (getActiveBits() <= 64) ? std::optional<uint64_t>(getZExtValue())
                                   : std::nullopt;
  };

  /// Get sign extended value
  ///
  /// This method attempts to return the value of this APInt as a sign extended
  /// int64_t. The bit width must be <= 64 or the value must fit within an
  /// int64_t. Otherwise an assertion will result.
  int64_t getSExtValue() const {
    if (isSingleWord())
      return static_cast<int64_t>(SignExtend64(U.VAL, BitWidth));
    assert(getSignificantBits() <= 64 && "Too many bits for int64_t");
    return int64_t(U.pVal[0]);
  }

  /// Get sign extended value if possible
  ///
  /// This method attempts to return the value of this APInt as a sign extended
  /// int64_t. The bitwidth must be <= 64 or the value must fit within an
  /// int64_t. Otherwise no value is returned.
  std::optional<int64_t> trySExtValue() const {
    return (getSignificantBits() <= 64) ? std::optional<int64_t>(getSExtValue())
                                        : std::nullopt;
  };

  /// The APInt version of std::countl_zero.
  ///
  /// It counts the number of zeros from the most significant bit to the first
  /// one bit.
  ///
  /// \returns BitWidth if the value is zero, otherwise returns the number of
  ///   zeros from the most significant bit to the first one bits.
  unsigned countl_zero() const {
    if (isSingleWord()) {
      unsigned unusedBits = APINT_BITS_PER_WORD - BitWidth;
      return llvm::countl_zero(U.VAL) - unusedBits;
    }
    return countLeadingZerosSlowCase();
  }

  unsigned countLeadingZeros() const { return countl_zero(); }

  /// Count the number of leading one bits.
  ///
  /// This function is an APInt version of std::countl_one. It counts the number
  /// of ones from the most significant bit to the first zero bit.
  ///
  /// \returns 0 if the high order bit is not set, otherwise returns the number
  /// of 1 bits from the most significant to the least
  unsigned countl_one() const {
    if (isSingleWord()) {
      if (BitWidth == 0)
        return 0;
      return llvm::countl_one(U.VAL << (APINT_BITS_PER_WORD - BitWidth));
    }
    return countLeadingOnesSlowCase();
  }

  unsigned countLeadingOnes() const { return countl_one(); }

  /// Computes the number of leading bits of this APInt that are equal to its
  /// sign bit.
  unsigned getNumSignBits() const {
    return isNegative() ? countl_one() : countl_zero();
  }

  /// Count the number of trailing zero bits.
  ///
  /// This function is an APInt version of std::countr_zero. It counts the
  /// number of zeros from the least significant bit to the first set bit.
  ///
  /// \returns BitWidth if the value is zero, otherwise returns the number of
  /// zeros from the least significant bit to the first one bit.
  unsigned countr_zero() const {
    if (isSingleWord()) {
      unsigned TrailingZeros = llvm::countr_zero(U.VAL);
      return (TrailingZeros > BitWidth ? BitWidth : TrailingZeros);
    }
    return countTrailingZerosSlowCase();
  }

  unsigned countTrailingZeros() const { return countr_zero(); }

  /// Count the number of trailing one bits.
  ///
  /// This function is an APInt version of std::countr_one. It counts the number
  /// of ones from the least significant bit to the first zero bit.
  ///
  /// \returns BitWidth if the value is all ones, otherwise returns the number
  /// of ones from the least significant bit to the first zero bit.
  unsigned countr_one() const {
    if (isSingleWord())
      return llvm::countr_one(U.VAL);
    return countTrailingOnesSlowCase();
  }

  unsigned countTrailingOnes() const { return countr_one(); }

  /// Count the number of bits set.
  ///
  /// This function is an APInt version of std::popcount. It counts the number
  /// of 1 bits in the APInt value.
  ///
  /// \returns 0 if the value is zero, otherwise returns the number of set bits.
  unsigned popcount() const {
    if (isSingleWord())
      return llvm::popcount(U.VAL);
    return countPopulationSlowCase();
  }

  /// @}
  /// \name Conversion Functions
  /// @{

  /// \returns the value with the bit representation reversed of this APInt
  /// Value.
  APInt reverseBits() const;

  /// @}
  /// \name Mathematics Operations
  /// @{

  /// \returns the floor log base 2 of this APInt.
  unsigned logBase2() const { return getActiveBits() - 1; }

  /// \returns the ceil log base 2 of this APInt.
  unsigned ceilLogBase2() const {
    APInt temp(*this);
    --temp;
    return temp.getActiveBits();
  }

  /// \returns the nearest log base 2 of this APInt. Ties round up.
  ///
  /// NOTE: When we have a BitWidth of 1, we define:
  ///
  ///   log2(0) = UINT32_MAX
  ///   log2(1) = 0
  ///
  /// to get around any mathematical concerns resulting from
  /// referencing 2 in a space where 2 does no exist.
  unsigned nearestLogBase2() const;

  /// \returns the log base 2 of this APInt if its an exact power of two, -1
  /// otherwise
  int32_t exactLogBase2() const {
    if (!isPowerOf2())
      return -1;
    return static_cast<int32_t>(logBase2());
  }

  /// Get the absolute value.  If *this is < 0 then return -(*this), otherwise
  /// *this.  Note that the "most negative" signed number (e.g. -128 for 8 bit
  /// wide APInt) is unchanged due to how negation works.
  APInt abs() const {
    if (isNegative())
      return -(*this);
    return *this;
  }

  /// @}
  /// \name Building-block Operations for APInt and APFloat
  /// @{

  // These building block operations operate on a representation of arbitrary
  // precision, two's-complement, bignum integer values. They should be
  // sufficient to implement APInt and APFloat bignum requirements. Inputs are
  // generally a pointer to the base of an array of integer parts, representing
  // an unsigned bignum, and a count of how many parts there are.

  /// Sets the least significant part of a bignum to the input value, and zeroes
  /// out higher parts.
  static void tcSet(WordType *, WordType, unsigned);

  /// Assign one bignum to another.
  static void tcAssign(WordType *, const WordType *, unsigned);

  /// Returns true if a bignum is zero, false otherwise.
  static bool tcIsZero(const WordType *, unsigned);

  /// Extract the given bit of a bignum; returns 0 or 1.  Zero-based.
  static int tcExtractBit(const WordType *, unsigned bit);

  /// Copy the bit vector of width srcBITS from SRC, starting at bit srcLSB, to
  /// DST, of dstCOUNT parts, such that the bit srcLSB becomes the least
  /// significant bit of DST.  All high bits above srcBITS in DST are
  /// zero-filled.
  static void tcExtract(WordType *, unsigned dstCount, const WordType *,
                        unsigned srcBits, unsigned srcLSB);

  /// Set the given bit of a bignum.  Zero-based.
  static void tcSetBit(WordType *, unsigned bit);

  /// Clear the given bit of a bignum.  Zero-based.
  static void tcClearBit(WordType *, unsigned bit);

  /// Returns the bit number of the least or most significant set bit of a
  /// number.  If the input number has no bits set -1U is returned.
  static unsigned tcLSB(const WordType *, unsigned n);
  static unsigned tcMSB(const WordType *parts, unsigned n);

  /// Negate a bignum in-place.
  static void tcNegate(WordType *, unsigned);

  /// DST += RHS + CARRY where CARRY is zero or one.  Returns the carry flag.
  static WordType tcAdd(WordType *, const WordType *, WordType carry, unsigned);
  /// DST += RHS.  Returns the carry flag.
  static WordType tcAddPart(WordType *, WordType, unsigned);

  /// DST -= RHS + CARRY where CARRY is zero or one. Returns the carry flag.
  static WordType tcSubtract(WordType *, const WordType *, WordType carry,
                             unsigned);
  /// DST -= RHS.  Returns the carry flag.
  static WordType tcSubtractPart(WordType *, WordType, unsigned);

  /// DST += SRC * MULTIPLIER + PART   if add is true
  /// DST  = SRC * MULTIPLIER + PART   if add is false
  ///
  /// Requires 0 <= DSTPARTS <= SRCPARTS + 1.  If DST overlaps SRC they must
  /// start at the same point, i.e. DST == SRC.
  ///
  /// If DSTPARTS == SRC_PARTS + 1 no overflow occurs and zero is returned.
  /// Otherwise DST is filled with the least significant DSTPARTS parts of the
  /// result, and if all of the omitted higher parts were zero return zero,
  /// otherwise overflow occurred and return one.
  static int tcMultiplyPart(WordType *dst, const WordType *src,
                            WordType multiplier, WordType carry,
                            unsigned srcParts, unsigned dstParts, bool add);

  /// DST = LHS * RHS, where DST has the same width as the operands and is
  /// filled with the least significant parts of the result.  Returns one if
  /// overflow occurred, otherwise zero.  DST must be disjoint from both
  /// operands.
  static int tcMultiply(WordType *, const WordType *, const WordType *,
                        unsigned);

  /// DST = LHS * RHS, where DST has width the sum of the widths of the
  /// operands. No overflow occurs. DST must be disjoint from both operands.
  static void tcFullMultiply(WordType *, const WordType *, const WordType *,
                             unsigned, unsigned);

  /// If RHS is zero LHS and REMAINDER are left unchanged, return one.
  /// Otherwise set LHS to LHS / RHS with the fractional part discarded, set
  /// REMAINDER to the remainder, return zero.  i.e.
  ///
  ///  OLD_LHS = RHS * LHS + REMAINDER
  ///
  /// SCRATCH is a bignum of the same size as the operands and result for use by
  /// the routine; its contents need not be initialized and are destroyed.  LHS,
  /// REMAINDER and SCRATCH must be distinct.
  static int tcDivide(WordType *lhs, const WordType *rhs, WordType *remainder,
                      WordType *scratch, unsigned parts);

  /// Shift a bignum left Count bits. Shifted in bits are zero. There are no
  /// restrictions on Count.
  static void tcShiftLeft(WordType *, unsigned Words, unsigned Count);

  /// Shift a bignum right Count bits.  Shifted in bits are zero.  There are no
  /// restrictions on Count.
  static void tcShiftRight(WordType *, unsigned Words, unsigned Count);

  /// Comparison (unsigned) of two bignums.
  static int tcCompare(const WordType *, const WordType *, unsigned);

  /// Increment a bignum in-place.  Return the carry flag.
  static WordType tcIncrement(WordType *dst, unsigned parts) {
    return tcAddPart(dst, 1, parts);
  }

  /// Decrement a bignum in-place.  Return the borrow flag.
  static WordType tcDecrement(WordType *dst, unsigned parts) {
    return tcSubtractPart(dst, 1, parts);
  }

  /// Returns whether this instance allocated memory.
  bool needsCleanup() const { return !isSingleWord(); }

private:
  /// This union is used to store the integer value. When the
  /// integer bit-width <= 64, it uses VAL, otherwise it uses pVal.
  union {
    uint64_t VAL;   ///< Used to store the <= 64 bits integer value.
    uint64_t *pVal; ///< Used to store the >64 bits integer value.
  } U;

  unsigned BitWidth = 1; ///< The number of bits in this APInt.

  /// This constructor is used only internally for speed of construction of
  /// temporaries. It is unsafe since it takes ownership of the pointer, so it
  /// is not public.
  APInt(uint64_t *val, unsigned bits) : BitWidth(bits) { U.pVal = val; }

  /// Determine which word a bit is in.
  ///
  /// \returns the word position for the specified bit position.
  static unsigned whichWord(unsigned bitPosition) {
    return bitPosition / APINT_BITS_PER_WORD;
  }

  /// Determine which bit in a word the specified bit position is in.
  static unsigned whichBit(unsigned bitPosition) {
    return bitPosition % APINT_BITS_PER_WORD;
  }

  /// Get a single bit mask.
  ///
  /// \returns a uint64_t with only bit at "whichBit(bitPosition)" set
  /// This method generates and returns a uint64_t (word) mask for a single
  /// bit at a specific bit position. This is used to mask the bit in the
  /// corresponding word.
  static uint64_t maskBit(unsigned bitPosition) {
    return 1ULL << whichBit(bitPosition);
  }

  /// Clear unused high order bits
  ///
  /// This method is used internally to clear the top "N" bits in the high order
  /// word that are not used by the APInt. This is needed after the most
  /// significant word is assigned a value to ensure that those bits are
  /// zero'd out.
  APInt &clearUnusedBits() {
    // Compute how many bits are used in the final word.
    unsigned WordBits = ((BitWidth - 1) % APINT_BITS_PER_WORD) + 1;

    // Mask out the high bits.
    uint64_t mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - WordBits);
    if (BitWidth == 0)
      mask = 0;

    if (isSingleWord())
      U.VAL &= mask;
    else
      U.pVal[getNumWords() - 1] &= mask;
    return *this;
  }

  /// Get the word corresponding to a bit position
  /// \returns the corresponding word for the specified bit position.
  uint64_t getWord(unsigned bitPosition) const {
    return isSingleWord() ? U.VAL : U.pVal[whichWord(bitPosition)];
  }

  /// Utility method to change the bit width of this APInt to new bit width,
  /// allocating and/or deallocating as necessary. There is no guarantee on the
  /// value of any bits upon return. Caller should populate the bits after.
  void reallocate(unsigned NewBitWidth);

  /// An internal division function for dividing APInts.
  ///
  /// This is used by the toString method to divide by the radix. It simply
  /// provides a more convenient form of divide for internal use since KnuthDiv
  /// has specific constraints on its inputs. If those constraints are not met
  /// then it provides a simpler form of divide.
  static void divide(const WordType *LHS, unsigned lhsWords,
                     const WordType *RHS, unsigned rhsWords, WordType *Quotient,
                     WordType *Remainder);

  /// out-of-line slow case for inline constructor
  void initSlowCase(uint64_t val, bool isSigned);

  /// shared code between two array constructors
  void initFromArray(const uint64_t *array, unsigned count);

  /// out-of-line slow case for inline copy constructor
  void initSlowCase(const APInt &that);

  /// out-of-line slow case for shl
  void shlSlowCase(unsigned ShiftAmt);

  /// out-of-line slow case for lshr.
  void lshrSlowCase(unsigned ShiftAmt);

  /// out-of-line slow case for ashr.
  void ashrSlowCase(unsigned ShiftAmt);

  /// out-of-line slow case for operator=
  void assignSlowCase(const APInt &RHS);

  /// out-of-line slow case for operator==
  bool equalSlowCase(const APInt &RHS) const;

  /// out-of-line slow case for countLeadingZeros
  unsigned countLeadingZerosSlowCase() const;

  /// out-of-line slow case for countLeadingOnes.
  unsigned countLeadingOnesSlowCase() const;

  /// out-of-line slow case for countTrailingZeros.
  unsigned countTrailingZerosSlowCase() const;

  /// out-of-line slow case for countTrailingOnes
  unsigned countTrailingOnesSlowCase() const;

  /// out-of-line slow case for countPopulation
  unsigned countPopulationSlowCase() const;

  /// out-of-line slow case for intersects.
  bool intersectsSlowCase(const APInt &RHS) const;

  /// out-of-line slow case for isSubsetOf.
  bool isSubsetOfSlowCase(const APInt &RHS) const;

  /// out-of-line slow case for setBits.
  void setBitsSlowCase(unsigned loBit, unsigned hiBit);

  /// out-of-line slow case for clearBits.
  void clearBitsSlowCase(unsigned LoBit, unsigned HiBit);

  /// out-of-line slow case for flipAllBits.
  void flipAllBitsSlowCase();

  /// out-of-line slow case for operator&=.
  void andAssignSlowCase(const APInt &RHS);

  /// out-of-line slow case for operator|=.
  void orAssignSlowCase(const APInt &RHS);

  /// out-of-line slow case for operator^=.
  void xorAssignSlowCase(const APInt &RHS);

  /// Unsigned comparison. Returns -1, 0, or 1 if this APInt is less than, equal
  /// to, or greater than RHS.
  int compare(const APInt &RHS) const;

  /// Signed comparison. Returns -1, 0, or 1 if this APInt is less than, equal
  /// to, or greater than RHS.
  int compareSigned(const APInt &RHS) const;

  /// @}
};

inline bool operator==(uint64_t V1, const APInt &V2) { return V2 == V1; }

inline bool operator!=(uint64_t V1, const APInt &V2) { return V2 != V1; }

/// Unary bitwise complement operator.
///
/// \returns an APInt that is the bitwise complement of \p v.
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

/// Determine the smaller of two APInts considered to be signed.
inline const APInt &smin(const APInt &A, const APInt &B) {
  return A.slt(B) ? A : B;
}

/// Determine the larger of two APInts considered to be signed.
inline const APInt &smax(const APInt &A, const APInt &B) {
  return A.sgt(B) ? A : B;
}

/// Determine the smaller of two APInts considered to be unsigned.
inline const APInt &umin(const APInt &A, const APInt &B) {
  return A.ult(B) ? A : B;
}

/// Determine the larger of two APInts considered to be unsigned.
inline const APInt &umax(const APInt &A, const APInt &B) {
  return A.ugt(B) ? A : B;
}

/// Converts the given APInt to a double value.
///
/// Treats the APInt as an unsigned value for conversion purposes.
/// Return A unsign-divided by B, rounded by the given rounding mode.
/// Let q(n) = An^2 + Bn + C, and BW = bit width of the value range
/// (e.g. 32 for i32).
/// This function finds the smallest number n, such that
/// (a) n >= 0 and q(n) = 0, or
/// (b) n >= 1 and q(n-1) and q(n), when evaluated in the set of all
///     integers, belong to two different intervals [Rk, Rk+R),
///     where R = 2^BW, and k is an integer.
/// The idea here is to find when q(n) "overflows" 2^BW, while at the
/// same time "allowing" subtraction. In unsigned modulo arithmetic a
/// subtraction (treated as addition of negated numbers) would always
/// count as an overflow, but here we want to allow values to decrease
/// and increase as long as they are within the same interval.
/// Specifically, adding of two negative numbers should not cause an
/// overflow (as long as the magnitude does not exceed the bit width).
/// On the other hand, given a positive number, adding a negative
/// number to it can give a negative result, which would cause the
/// value to go from [-2^BW, 0) to [0, 2^BW). In that sense, zero is
/// treated as a special case of an overflow.
///
/// This function returns std::nullopt if after finding k that minimizes the
/// positive solution to q(n) = kR, both solutions are contained between
/// two consecutive integers.
///
/// There are cases where q(n) > T, and q(n+1) < T (assuming evaluation
/// in arithmetic modulo 2^BW, and treating the values as signed) by the
/// virtue of *signed* overflow. This function will *not* find such an n,
/// however it may find a value of n satisfying the inequalities due to
/// an *unsigned* overflow (if the values are treated as unsigned).
/// To find a solution for a signed overflow, treat it as a problem of
/// finding an unsigned overflow with a range with of BW-1.
///
/// The returned value may have a different bit width from the input
/// coefficients.

/// Compare two values, and if they are different, return the position of the
/// most significant bit that is different in the values.
std::optional<unsigned> GetMostSignificantDifferentBit(const APInt &A,
                                                       const APInt &B);

} // namespace APIntOps

#define DEBUG_TYPE "apint"

/// A utility function for allocating memory, checking for allocation failures,
/// and ensuring the contents are zeroed.
inline static uint64_t *getClearedMemory(unsigned numWords) {
  return new uint64_t[numWords]();
}

/// A utility function for allocating memory and checking for allocation
/// failure.  The content is not zeroed.
inline static uint64_t *getMemory(unsigned numWords) {
  return new uint64_t[numWords];
}

/// A utility function that converts a character to a digit.
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
  // If the number of words is the same we can just change the width and stop.
  if (getNumWords() == getNumWords(NewBitWidth)) {
    BitWidth = NewBitWidth;
    return;
  }

  // If we have an allocation, delete it.
  if (!isSingleWord())
    delete[] U.pVal;

  // Update BitWidth.
  BitWidth = NewBitWidth;

  // If we are supposed to have an allocation, create it.
  if (!isSingleWord())
    U.pVal = getMemory(getNumWords());
}

inline void APInt::assignSlowCase(const APInt &RHS) {
  // Don't do anything for X = X
  if (this == &RHS)
    return;

  // Adjust the bit width and handle allocations as necessary.
  reallocate(RHS.getBitWidth());

  // Copy the data.
  if (isSingleWord())
    U.VAL = RHS.U.VAL;
  else
    memcpy(U.pVal, RHS.U.pVal, getNumWords() * APINT_WORD_SIZE);
}
/// Prefix increment operator. Increments the APInt by one.
inline APInt &APInt::operator++() {
  if (isSingleWord())
    ++U.VAL;
  else
    tcIncrement(U.pVal, getNumWords());
  return clearUnusedBits();
}

/// Prefix decrement operator. Decrements the APInt by one.
inline APInt &APInt::operator--() {
  if (isSingleWord())
    --U.VAL;
  else
    tcDecrement(U.pVal, getNumWords());
  return clearUnusedBits();
}

/// Adds the RHS APInt to this APInt.
/// @returns this, after addition of RHS.
/// Addition assignment operator.
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

/// Subtracts the RHS APInt from this APInt
/// @returns this, after subtraction
/// Subtraction assignment operator.
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

  // If the sign bits don't match, then (LHS < RHS) if LHS is negative
  if (lhsNeg != rhsNeg)
    return lhsNeg ? -1 : 1;

  // Otherwise we can just use an unsigned comparison, because even negative
  // numbers compare correctly this way if both have the same signed-ness.
  return tcCompare(U.pVal, RHS.U.pVal, getNumWords());
}

inline void APInt::setBitsSlowCase(unsigned loBit, unsigned hiBit) {
  unsigned loWord = whichWord(loBit);
  unsigned hiWord = whichWord(hiBit);

  // Create an initial mask for the low word with zeros below loBit.
  uint64_t loMask = WORDTYPE_MAX << whichBit(loBit);

  // If hiBit is not aligned, we need a high mask.
  unsigned hiShiftAmt = whichBit(hiBit);
  if (hiShiftAmt != 0) {
    // Create a high mask with zeros above hiBit.
    uint64_t hiMask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - hiShiftAmt);
    // If loWord and hiWord are equal, then we combine the masks. Otherwise,
    // set the bits in hiWord.
    if (hiWord == loWord)
      loMask &= hiMask;
    else
      U.pVal[hiWord] |= hiMask;
  }
  // Apply the mask to the low word.
  U.pVal[loWord] |= loMask;

  // Fill any words between loWord and hiWord with all ones.
  for (unsigned word = loWord + 1; word < hiWord; ++word)
    U.pVal[word] = WORDTYPE_MAX;
}

inline void APInt::clearBitsSlowCase(unsigned LoBit, unsigned HiBit) {
  unsigned LoWord = whichWord(LoBit);
  unsigned HiWord = whichWord(HiBit);

  // Create an initial mask for the low word with ones below loBit.
  uint64_t LoMask = ~(WORDTYPE_MAX << whichBit(LoBit));

  // If HiBit is not aligned, we need a high mask.
  unsigned HiShiftAmt = whichBit(HiBit);
  if (HiShiftAmt != 0) {
    // Create a high mask with ones above HiBit.
    uint64_t HiMask = ~(WORDTYPE_MAX >> (APINT_BITS_PER_WORD - HiShiftAmt));
    // If LoWord and HiWord are equal, then we combine the masks. Otherwise,
    // clear the bits in HiWord.
    if (HiWord == LoWord)
      LoMask |= HiMask;
    else
      U.pVal[HiWord] &= HiMask;
  }
  // Apply the mask to the low word.
  U.pVal[LoWord] &= LoMask;

  // Fill any words between LoWord and HiWord with all zeros.
  for (unsigned Word = LoWord + 1; Word < HiWord; ++Word)
    U.pVal[Word] = 0;
}

// Complement a bignum in-place.
static void tcComplement(APInt::WordType *dst, unsigned parts) {
  for (unsigned i = 0; i < parts; i++)
    dst[i] = ~dst[i];
}

/// Toggle every bit to its opposite value.
inline void APInt::flipAllBitsSlowCase() {
  tcComplement(U.pVal, getNumWords());
  clearUnusedBits();
}

/// Toggle a given bit to its opposite value whose position is given
/// as "bitPosition".
/// Toggles a given bit to its opposite value.
inline void APInt::flipBit(unsigned bitPosition) {
  assert(bitPosition < BitWidth && "Out of the bit-width range!");
  setBitVal(bitPosition, !(*this)[bitPosition]);
}

inline void APInt::insertBits(const APInt &subBits, unsigned bitPosition) {
  unsigned subBitWidth = subBits.getBitWidth();
  assert((subBitWidth + bitPosition) <= BitWidth && "Illegal bit insertion");

  // inserting no bits is a noop.
  if (subBitWidth == 0)
    return;

  // Insertion is a direct copy.
  if (subBitWidth == BitWidth) {
    *this = subBits;
    return;
  }

  // Single word result can be done as a direct bitmask.
  if (isSingleWord()) {
    uint64_t mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - subBitWidth);
    U.VAL &= ~(mask << bitPosition);
    U.VAL |= (subBits.U.VAL << bitPosition);
    return;
  }

  unsigned loBit = whichBit(bitPosition);
  unsigned loWord = whichWord(bitPosition);
  unsigned hi1Word = whichWord(bitPosition + subBitWidth - 1);

  // Insertion within a single word can be done as a direct bitmask.
  if (loWord == hi1Word) {
    uint64_t mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - subBitWidth);
    U.pVal[loWord] &= ~(mask << loBit);
    U.pVal[loWord] |= (subBits.U.VAL << loBit);
    return;
  }

  // Insert on word boundaries.
  if (loBit == 0) {
    // Direct copy whole words.
    unsigned numWholeSubWords = subBitWidth / APINT_BITS_PER_WORD;
    memcpy(U.pVal + loWord, subBits.getRawData(),
           numWholeSubWords * APINT_WORD_SIZE);

    // Mask+insert remaining bits.
    unsigned remainingBits = subBitWidth % APINT_BITS_PER_WORD;
    if (remainingBits != 0) {
      uint64_t mask = WORDTYPE_MAX >> (APINT_BITS_PER_WORD - remainingBits);
      U.pVal[hi1Word] &= ~mask;
      U.pVal[hi1Word] |= subBits.getWord(subBitWidth - 1);
    }
    return;
  }

  // General case - set/clear individual bits in dst based on src.
  // TODO - there is scope for optimization here, but at the moment this code
  // path is barely used so prefer readability over performance.
  for (unsigned i = 0; i != subBitWidth; ++i)
    setBitVal(bitPosition + i, subBits[i]);
}

inline void APInt::insertBits(uint64_t subBits, unsigned bitPosition,
                              unsigned numBits) {
  uint64_t maskBits = maskTrailingOnes<uint64_t>(numBits);
  subBits &= maskBits;
  if (isSingleWord()) {
    U.VAL &= ~(maskBits << bitPosition);
    U.VAL |= subBits << bitPosition;
    return;
  }

  unsigned loBit = whichBit(bitPosition);
  unsigned loWord = whichWord(bitPosition);
  unsigned hiWord = whichWord(bitPosition + numBits - 1);
  if (loWord == hiWord) {
    U.pVal[loWord] &= ~(maskBits << loBit);
    U.pVal[loWord] |= subBits << loBit;
    return;
  }

  static_assert(8 * sizeof(WordType) <= 64,
                "This code assumes only two words affected");
  unsigned wordBits = 8 * sizeof(WordType);
  U.pVal[loWord] &= ~(maskBits << loBit);
  U.pVal[loWord] |= subBits << loBit;

  U.pVal[hiWord] &= ~(maskBits >> (wordBits - loBit));
  U.pVal[hiWord] |= subBits >> (wordBits - loBit);
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

/// This function returns the high "numBits" bits of this APInt.
inline APInt APInt::getHiBits(unsigned numBits) const {
  return this->lshr(BitWidth - numBits);
}

/// This function returns the low "numBits" bits of this APInt.
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
  // Adjust for unused bits in the most significant word (they are zero).
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

inline APInt APInt::reverseBits() const {
  switch (BitWidth) {
  case 64:
    return APInt(BitWidth, llvm::reverseBits<uint64_t>(U.VAL));
  case 32:
    return APInt(BitWidth,
                 llvm::reverseBits<uint32_t>(static_cast<uint32_t>(U.VAL)));
  case 16:
    return APInt(BitWidth,
                 llvm::reverseBits<uint16_t>(static_cast<uint16_t>(U.VAL)));
  case 8:
    return APInt(BitWidth,
                 llvm::reverseBits<uint8_t>(static_cast<uint8_t>(U.VAL)));
  case 0:
    return *this;
  default:
    break;
  }

  APInt Val(*this);
  APInt Reversed(BitWidth, 0);
  unsigned S = BitWidth;

  for (; Val != 0; Val.lshrInPlace(1)) {
    Reversed <<= 1;
    Reversed |= Val[0];
    --S;
  }

  Reversed <<= S;
  return Reversed;
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

  // Copy words.
  std::memcpy(Result.U.pVal, getRawData(), getNumWords() * APINT_WORD_SIZE);

  // Sign extend the last word since there may be unused bits in the input.
  Result.U.pVal[getNumWords() - 1] = static_cast<uint64_t>(
      SignExtend64(Result.U.pVal[getNumWords() - 1],
                   ((BitWidth - 1) % APINT_BITS_PER_WORD) + 1));

  // Fill with sign bits.
  std::memset(Result.U.pVal + getNumWords(), isNegative() ? -1 : 0,
              (Result.getNumWords() - getNumWords()) * APINT_WORD_SIZE);
  Result.clearUnusedBits();
  return Result;
}

//  Zero extend to a new width.
inline APInt APInt::zext(unsigned width) const {
  assert(width >= BitWidth && "Invalid APInt ZeroExtend request");

  if (width <= APINT_BITS_PER_WORD)
    return APInt(width, U.VAL);

  if (width == BitWidth)
    return *this;

  APInt Result(getMemory(getNumWords(width)), width);

  // Copy words.
  std::memcpy(Result.U.pVal, getRawData(), getNumWords() * APINT_WORD_SIZE);

  // Zero remaining words.
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

/// Arithmetic right-shift this APInt by shiftAmt.
/// Arithmetic right-shift function.
inline void APInt::ashrInPlace(const APInt &shiftAmt) {
  ashrInPlace(static_cast<unsigned>(shiftAmt.getLimitedValue(BitWidth)));
}

/// Arithmetic right-shift this APInt by shiftAmt.
/// Arithmetic right-shift function.
inline void APInt::ashrSlowCase(unsigned ShiftAmt) {
  // Don't bother performing a no-op shift.
  if (!ShiftAmt)
    return;

  // Save the original sign bit for later.
  bool Negative = isNegative();

  // WordShift is the inter-part shift; BitShift is intra-part shift.
  unsigned WordShift = ShiftAmt / APINT_BITS_PER_WORD;
  unsigned BitShift = ShiftAmt % APINT_BITS_PER_WORD;

  unsigned WordsToMove = getNumWords() - WordShift;
  if (WordsToMove != 0) {
    // Sign extend the last word to fill in the unused bits.
    U.pVal[getNumWords() - 1] = static_cast<uint64_t>(SignExtend64(
        U.pVal[getNumWords() - 1], ((BitWidth - 1) % APINT_BITS_PER_WORD) + 1));

    // Fastpath for moving by whole words.
    if (BitShift == 0) {
      std::memmove(U.pVal, U.pVal + WordShift, WordsToMove * APINT_WORD_SIZE);
    } else {
      // Move the words containing significant bits.
      for (unsigned i = 0; i != WordsToMove - 1; ++i)
        U.pVal[i] =
            (U.pVal[i + WordShift] >> BitShift) |
            (U.pVal[i + WordShift + 1] << (APINT_BITS_PER_WORD - BitShift));

      // Handle the last word which has no high bits to copy. Use an arithmetic
      // shift to preserve the sign bit.
      U.pVal[WordsToMove - 1] = static_cast<uint64_t>(
          static_cast<int64_t>(U.pVal[WordShift + WordsToMove - 1]) >>
          BitShift);
    }
  }

  // Fill in the remainder based on the original sign.
  std::memset(U.pVal + WordsToMove, Negative ? -1 : 0,
              WordShift * APINT_WORD_SIZE);
  clearUnusedBits();
}

/// Logical right-shift this APInt by shiftAmt.
/// Logical right-shift function.
inline void APInt::lshrInPlace(const APInt &shiftAmt) {
  lshrInPlace(static_cast<unsigned>(shiftAmt.getLimitedValue(BitWidth)));
}

/// Logical right-shift this APInt by shiftAmt.
/// Logical right-shift function.
inline void APInt::lshrSlowCase(unsigned ShiftAmt) {
  tcShiftRight(U.pVal, getNumWords(), ShiftAmt);
}

/// Left-shift this APInt by shiftAmt.
/// Left-shift function.
inline APInt &APInt::operator<<=(const APInt &shiftAmt) {
  // It's undefined behavior in C to shift by BitWidth or greater.
  *this <<= static_cast<unsigned>(shiftAmt.getLimitedValue(BitWidth));
  return *this;
}

inline void APInt::shlSlowCase(unsigned ShiftAmt) {
  tcShiftLeft(U.pVal, getNumWords(), ShiftAmt);
  clearUnusedBits();
}

// Calculate the rotate amount modulo the bit width.
static unsigned rotateModulo(unsigned BitWidth, const APInt &rotateAmt) {
  if (BitWidth == 0)
    return 0;
  unsigned rotBitWidth = rotateAmt.getBitWidth();
  APInt rot = rotateAmt;
  if (rotBitWidth < BitWidth) {
    // Extend the rotate APInt, so that the urem doesn't divide by 0.
    // e.g. APInt(1, 32) would give APInt(1, 0).
    rot = rotateAmt.zext(BitWidth);
  }
  rot = rot.urem(APInt(rot.getBitWidth(), BitWidth));
  return static_cast<unsigned>(rot.getLimitedValue(BitWidth));
}

inline APInt APInt::rotl(const APInt &rotateAmt) const {
  return rotl(rotateModulo(BitWidth, rotateAmt));
}

inline APInt APInt::rotl(unsigned rotateAmt) const {
  if (BitWidth == 0)
    return *this;
  rotateAmt %= BitWidth;
  if (rotateAmt == 0)
    return *this;
  return shl(rotateAmt) | lshr(BitWidth - rotateAmt);
}

inline APInt APInt::rotr(const APInt &rotateAmt) const {
  return rotr(rotateModulo(BitWidth, rotateAmt));
}

inline APInt APInt::rotr(unsigned rotateAmt) const {
  if (BitWidth == 0)
    return *this;
  rotateAmt %= BitWidth;
  if (rotateAmt == 0)
    return *this;
  return lshr(rotateAmt) | shl(BitWidth - rotateAmt);
}

/// \returns the nearest log base 2 of this APInt. Ties round up.
///
/// NOTE: When we have a BitWidth of 1, we define:
///
///   log2(0) = UINT32_MAX
///   log2(1) = 0
///
/// to get around any mathematical concerns resulting from
/// referencing 2 in a space where 2 does no exist.
inline unsigned APInt::nearestLogBase2() const {
  // Special case when we have a bitwidth of 1. If VAL is 1, then we
  // get 0. If VAL is 0, we get WORDTYPE_MAX which gets truncated to
  // UINT32_MAX.
  if (BitWidth == 1)
    return static_cast<unsigned>(U.VAL - 1);

  // Handle the zero case.
  if (isZero())
    return UINT32_MAX;

  // The non-zero case is handled by computing:
  //
  //   nearestLogBase2(x) = logBase2(x) + x[logBase2(x)-1].
  //
  // where x[i] is referring to the value of the ith bit of x.
  unsigned lg = logBase2();
  return lg + unsigned((*this)[lg - 1]);
}

/// Implementation of Knuth's Algorithm D (Division of nonnegative integers)
/// from "Art of Computer Programming, Volume 2", section 4.3.1, p. 272. The
/// variables here have the same names as in the algorithm. Comments explain
/// the algorithm and any deviation from it.
static void KnuthDiv(uint32_t *u, uint32_t *v, uint32_t *q, uint32_t *r,
                     unsigned m, unsigned n) {
  assert(u && "Must provide dividend");
  assert(v && "Must provide divisor");
  assert(q && "Must provide quotient");
  assert(u != v && u != q && v != q && "Must use different memory");
  assert(n > 1 && "n must be > 1");

  // b denotes the base of the number system. In our case b is 2^32.
  const uint64_t b = uint64_t(1) << 32;

  // The DEBUG macros here tend to be spam in the debug output if you're not
  // debugging this code. Disable them unless KNUTH_DEBUG is defined.

  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // D1. [Normalize.] Set d = b / (v[n-1] + 1) and multiply all the digits of
  // u and v by d. Note that we have taken Knuth's advice here to use a power
  // of 2 value for d such that d * v[n-1] >= b/2 (b is the base). A power of
  // 2 allows us to shift instead of multiply and it is easy to determine the
  // shift amount from the leading zeros.  We are basically normalizing the u
  // and v so that its high bits are shifted to the top of v's range without
  // overflow. Note that this can require an extra word in u so that u must
  // be of length m+n+1.
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

  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed

  // D2. [Initialize j.]  Set j to m. This is the loop counter over the places.
  int j = static_cast<int>(m);
  do {
    // DEBUG_KNUTH removed
    // D3. [Calculate q'.].
    //     Set qp = (u[j+n]*b + u[j+n-1]) / v[n-1]. (qp=qprime=q')
    //     Set rp = (u[j+n]*b + u[j+n-1]) % v[n-1]. (rp=rprime=r')
    // Now test if qp == b or qp*v[n-2] > b*rp + u[j+n-2]; if so, decrease
    // qp by 1, increase rp by v[n-1], and repeat this test if rp < b. The test
    // on v[n-2] determines at high speed most of the cases in which the trial
    // value qp is one too large, and it eliminates all cases where qp is two
    // too large.
    uint64_t dividend =
        Make_64(u[static_cast<unsigned>(j + static_cast<int>(n))],
                u[static_cast<unsigned>(j + static_cast<int>(n) - 1)]);
    // DEBUG_KNUTH removed
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
    // DEBUG_KNUTH removed

    // D4. [Multiply and subtract.] Replace (u[j+n]u[j+n-1]...u[j]) with
    // (u[j+n]u[j+n-1]..u[j]) - qp * (v[n-1]...v[1]v[0]). This computation
    // consists of a simple multiplication by a one-place number, combined with
    // a subtraction.
    // The digits (u[j+n]...u[j]) should be kept positive; if the result of
    // this step is actually negative, (u[j+n]...u[j]) should be left as the
    // true value plus b**(n+1), namely as the b's complement of
    // the true value, and a "borrow" to the left should be remembered.
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
      // DEBUG_KNUTH removed
    }
    bool isNeg = u[static_cast<unsigned>(j + static_cast<int>(n))] <
                 static_cast<uint64_t>(borrow);
    u[static_cast<unsigned>(j + static_cast<int>(n))] -=
        Lo_32(static_cast<uint64_t>(borrow));

    // DEBUG_KNUTH removed
    // DEBUG_KNUTH removed
    // DEBUG_KNUTH removed

    // D5. [Test remainder.] Set q[j] = qp. If the result of step D4 was
    // negative, go to step D6; otherwise go on to step D7.
    q[j] = Lo_32(qp);
    if (isNeg) {
      // D6. [Add back]. The probability that this step is necessary is very
      // small, on the order of only 2/b. Make sure that test data accounts for
      // this possibility. Decrease q[j] by 1
      q[j]--;
      // and add (0v[n-1]...v[1]v[0]) to (u[j+n]u[j+n-1]...u[j+1]u[j]).
      // A carry will occur to the left of u[j+n], and it should be ignored
      // since it cancels with the borrow that occurred in D4.
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
    // DEBUG_KNUTH removed
    // DEBUG_KNUTH removed
    // DEBUG_KNUTH removed

    // D7. [Loop on j.]  Decrease j by one. Now if j >= 0, go back to D3.
  } while (--j >= 0);

  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed
  // DEBUG_KNUTH removed

  // D8. [Unnormalize]. Now q[...] is the desired quotient, and the desired
  // remainder may be obtained by dividing u[...] by d. If r is non-null we
  // compute the remainder (urem uses this).
  if (r) {
    // The value d is expressed by the "shift" value above since we avoided
    // multiplication by d by using a shift left. So, all we have to do is
    // shift right here.
    if (shift) {
      uint32_t carry = 0;
      // DEBUG_KNUTH removed
      for (int i = static_cast<int>(n) - 1; i >= 0; i--) {
        r[i] = (u[i] >> shift) | carry;
        carry = u[i] << (32 - shift);
        // DEBUG_KNUTH removed
      }
    } else {
      for (int i = static_cast<int>(n) - 1; i >= 0; i--) {
        r[i] = u[i];
        // DEBUG_KNUTH removed
      }
    }
    // DEBUG_KNUTH removed
  }
  // DEBUG_KNUTH removed
}

inline void APInt::divide(const WordType *LHS, unsigned lhsWords,
                          const WordType *RHS, unsigned rhsWords,
                          WordType *Quotient, WordType *Remainder) {
  assert(lhsWords >= rhsWords && "Fractional result");

  // First, compose the values into an array of 32-bit words instead of
  // 64-bit words. This is a necessity of both the "short division" algorithm
  // and the Knuth "classical algorithm" which requires there to be native
  // operations for +, -, and * on an m bit value with an m*2 bit result. We
  // can't use 64-bit operands here because we don't have native results of
  // 128-bits. Furthermore, casting the 64-bit values to 32-bit values won't
  // work on large-endian machines.
  unsigned n = rhsWords * 2;
  unsigned m = (lhsWords * 2) - n;

  // Allocate space for the temporary values we need either on the stack, if
  // it will fit, or on the heap if it won't.
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

  // Initialize the dividend
  memset(U, 0, (m + n + 1) * sizeof(uint32_t));
  for (unsigned i = 0; i < lhsWords; ++i) {
    uint64_t tmp = LHS[i];
    U[i * 2] = Lo_32(tmp);
    U[i * 2 + 1] = Hi_32(tmp);
  }
  U[m + n] = 0; // this extra word is for "spill" in the Knuth algorithm.

  // Initialize the divisor
  memset(V, 0, (n) * sizeof(uint32_t));
  for (unsigned i = 0; i < rhsWords; ++i) {
    uint64_t tmp = RHS[i];
    V[i * 2] = Lo_32(tmp);
    V[i * 2 + 1] = Hi_32(tmp);
  }

  // initialize the quotient and remainder
  memset(Q, 0, (m + n) * sizeof(uint32_t));
  if (Remainder)
    memset(R, 0, n * sizeof(uint32_t));

  // Now, adjust m and n for the Knuth division. n is the number of words in
  // the divisor. m is the number of words by which the dividend exceeds the
  // divisor (i.e. m+n is the length of the dividend). These sizes must not
  // contain any zero words or the Knuth algorithm fails.
  for (unsigned i = n; i > 0 && V[i - 1] == 0; i--) {
    n--;
    m++;
  }
  for (unsigned i = m + n; i > 0 && U[i - 1] == 0; i--)
    m--;

  // If we're left with only a single word for the divisor, Knuth doesn't work
  // so we implement the short division algorithm here. This is much simpler
  // and faster because we are certain that we can divide a 64-bit quantity
  // by a 32-bit quantity at hardware speed and short division is simply a
  // series of such operations. This is just like doing short division but we
  // are using base 2^32 instead of base 10.
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
    // Now we're ready to invoke the Knuth classical divide algorithm. In this
    // case n > 1.
    KnuthDiv(U, V, Q, R, m, n);
  }

  // If the caller wants the quotient
  if (Quotient) {
    for (unsigned i = 0; i < lhsWords; ++i)
      Quotient[i] = Make_64(Q[i * 2 + 1], Q[i * 2]);
  }

  // If the caller wants the remainder
  if (Remainder) {
    for (unsigned i = 0; i < rhsWords; ++i)
      Remainder[i] = Make_64(R[i * 2 + 1], R[i * 2]);
  }

  // Clean up the memory we allocated.
  if (U != &SPACE[0]) {
    delete[] U;
    delete[] V;
    delete[] Q;
    delete[] R;
  }
}

inline APInt APInt::udiv(const APInt &RHS) const {
  assert(BitWidth == RHS.BitWidth && "Bit widths must be the same");

  // First, deal with the easy case
  if (isSingleWord()) {
    assert(RHS.U.VAL != 0 && "Divide by zero?");
    return APInt(BitWidth, U.VAL / RHS.U.VAL);
  }

  // Get some facts about the LHS and RHS number of bits and words
  unsigned lhsWords = getNumWords(getActiveBits());
  unsigned rhsBits = RHS.getActiveBits();
  unsigned rhsWords = getNumWords(rhsBits);
  assert(rhsWords && "Divided by zero???");

  // Deal with some degenerate cases
  if (!lhsWords)
    // 0 / X ===> 0
    return APInt(BitWidth, 0);
  if (rhsBits == 1)
    // X / 1 ===> X
    return *this;
  if (lhsWords < rhsWords || this->ult(RHS))
    // X / Y ===> 0, iff X < Y
    return APInt(BitWidth, 0);
  if (*this == RHS)
    // X / X ===> 1
    return APInt(BitWidth, 1);
  if (lhsWords == 1) // rhsWords is 1 if lhsWords is 1.
    // All high words are zero, just use native divide
    return APInt(BitWidth, this->U.pVal[0] / RHS.U.pVal[0]);

  // We have to compute it the hard way. Invoke the Knuth divide algorithm.
  APInt Quotient(BitWidth, 0); // to hold result.
  divide(U.pVal, lhsWords, RHS.U.pVal, rhsWords, Quotient.U.pVal, nullptr);
  return Quotient;
}

inline APInt APInt::udiv(uint64_t RHS) const {
  assert(RHS != 0 && "Divide by zero?");

  // First, deal with the easy case
  if (isSingleWord())
    return APInt(BitWidth, U.VAL / RHS);

  // Get some facts about the LHS words.
  unsigned lhsWords = getNumWords(getActiveBits());

  // Deal with some degenerate cases
  if (!lhsWords)
    // 0 / X ===> 0
    return APInt(BitWidth, 0);
  if (RHS == 1)
    // X / 1 ===> X
    return *this;
  if (this->ult(RHS))
    // X / Y ===> 0, iff X < Y
    return APInt(BitWidth, 0);
  if (*this == RHS)
    // X / X ===> 1
    return APInt(BitWidth, 1);
  if (lhsWords == 1) // rhsWords is 1 if lhsWords is 1.
    // All high words are zero, just use native divide
    return APInt(BitWidth, this->U.pVal[0] / RHS);

  // We have to compute it the hard way. Invoke the Knuth divide algorithm.
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

  // Get some facts about the LHS
  unsigned lhsWords = getNumWords(getActiveBits());

  // Get some facts about the RHS
  unsigned rhsBits = RHS.getActiveBits();
  unsigned rhsWords = getNumWords(rhsBits);
  assert(rhsWords && "Performing remainder operation by zero ???");

  // Check the degenerate cases
  if (lhsWords == 0)
    // 0 % Y ===> 0
    return APInt(BitWidth, 0);
  if (rhsBits == 1)
    // X % 1 ===> 0
    return APInt(BitWidth, 0);
  if (lhsWords < rhsWords || this->ult(RHS))
    // X % Y ===> X, iff X < Y
    return *this;
  if (*this == RHS)
    // X % X == 0;
    return APInt(BitWidth, 0);
  if (lhsWords == 1)
    // All high words are zero, just use native remainder
    return APInt(BitWidth, U.pVal[0] % RHS.U.pVal[0]);

  // We have to compute it the hard way. Invoke the Knuth divide algorithm.
  APInt Remainder(BitWidth, 0);
  divide(U.pVal, lhsWords, RHS.U.pVal, rhsWords, nullptr, Remainder.U.pVal);
  return Remainder;
}

inline uint64_t APInt::urem(uint64_t RHS) const {
  assert(RHS != 0 && "Remainder by zero?");

  if (isSingleWord())
    return U.VAL % RHS;

  // Get some facts about the LHS
  unsigned lhsWords = getNumWords(getActiveBits());

  // Check the degenerate cases
  if (lhsWords == 0)
    // 0 % Y ===> 0
    return 0;
  if (RHS == 1)
    // X % 1 ===> 0
    return 0;
  if (this->ult(RHS))
    // X % Y ===> X, iff X < Y
    return getZExtValue();
  if (*this == RHS)
    // X % X == 0;
    return 0;
  if (lhsWords == 1)
    // All high words are zero, just use native remainder
    return U.pVal[0] % RHS;

  // We have to compute it the hard way. Invoke the Knuth divide algorithm.
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

  // First, deal with the easy case
  if (LHS.isSingleWord()) {
    assert(RHS.U.VAL != 0 && "Divide by zero?");
    uint64_t QuotVal = LHS.U.VAL / RHS.U.VAL;
    uint64_t RemVal = LHS.U.VAL % RHS.U.VAL;
    Quotient = APInt(BitWidth, QuotVal);
    Remainder = APInt(BitWidth, RemVal);
    return;
  }

  // Get some size facts about the dividend and divisor
  unsigned lhsWords = getNumWords(LHS.getActiveBits());
  unsigned rhsBits = RHS.getActiveBits();
  unsigned rhsWords = getNumWords(rhsBits);
  assert(rhsWords && "Performing divrem operation by zero ???");

  // Check the degenerate cases
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

  // Make sure there is enough space to hold the results.
  // NOTE: This assumes that reallocate won't affect any bits if it doesn't
  // change the size. This is necessary if Quotient or Remainder is aliased
  // with LHS or RHS.
  Quotient.reallocate(BitWidth);
  Remainder.reallocate(BitWidth);

  if (lhsWords == 1) { // rhsWords is 1 if lhsWords is 1.
    // There is only one word to consider so use the native versions.
    uint64_t lhsValue = LHS.U.pVal[0];
    uint64_t rhsValue = RHS.U.pVal[0];
    Quotient = lhsValue / rhsValue;
    Remainder = lhsValue % rhsValue;
    return;
  }

  // Okay, lets do it the long way
  divide(LHS.U.pVal, lhsWords, RHS.U.pVal, rhsWords, Quotient.U.pVal,
         Remainder.U.pVal);
  // Clear the rest of the Quotient and Remainder.
  std::memset(Quotient.U.pVal + lhsWords, 0,
              (getNumWords(BitWidth) - lhsWords) * APINT_WORD_SIZE);
  std::memset(Remainder.U.pVal + rhsWords, 0,
              (getNumWords(BitWidth) - rhsWords) * APINT_WORD_SIZE);
}

inline void APInt::udivrem(const APInt &LHS, uint64_t RHS, APInt &Quotient,
                           uint64_t &Remainder) {
  assert(RHS != 0 && "Divide by zero?");
  unsigned BitWidth = LHS.BitWidth;

  // First, deal with the easy case
  if (LHS.isSingleWord()) {
    uint64_t QuotVal = LHS.U.VAL / RHS;
    Remainder = LHS.U.VAL % RHS;
    Quotient = APInt(BitWidth, QuotVal);
    return;
  }

  // Get some size facts about the dividend and divisor
  unsigned lhsWords = getNumWords(LHS.getActiveBits());

  // Check the degenerate cases
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

  // Make sure there is enough space to hold the results.
  // NOTE: This assumes that reallocate won't affect any bits if it doesn't
  // change the size. This is necessary if Quotient is aliased with LHS.
  Quotient.reallocate(BitWidth);

  if (lhsWords == 1) { // rhsWords is 1 if lhsWords is 1.
    // There is only one word to consider so use the native versions.
    uint64_t lhsValue = LHS.U.pVal[0];
    Quotient = lhsValue / RHS;
    Remainder = lhsValue % RHS;
    return;
  }

  // Okay, lets do it the long way
  divide(LHS.U.pVal, lhsWords, &RHS, 1, Quotient.U.pVal, &Remainder);
  // Clear the rest of the Quotient.
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

// This implements a variety of operations on a representation of
// arbitrary precision, two's-complement, bignum integer values.

// Assumed by lowHalf, highHalf, partMSB and partLSB.  A fairly safe
// and unrestricting assumption.
static_assert(APInt::APINT_BITS_PER_WORD % 2 == 0,
              "Part width must be divisible by 2!");

// Returns the integer part with the least significant BITS set.
// BITS cannot be zero.
static inline APInt::WordType lowBitMask(unsigned bits) {
  assert(bits != 0 && bits <= APInt::APINT_BITS_PER_WORD);
  return ~static_cast<APInt::WordType>(0) >>
         (APInt::APINT_BITS_PER_WORD - bits);
}

/// Returns the value of the lower half of PART.
static inline APInt::WordType lowHalf(APInt::WordType part) {
  return part & lowBitMask(APInt::APINT_BITS_PER_WORD / 2);
}

/// Returns the value of the upper half of PART.
static inline APInt::WordType highHalf(APInt::WordType part) {
  return part >> (APInt::APINT_BITS_PER_WORD / 2);
}

/// Sets the least significant part of a bignum to the input value, and zeroes
/// out higher parts.
inline void APInt::tcSet(WordType *dst, WordType part, unsigned parts) {
  assert(parts > 0);
  dst[0] = part;
  for (unsigned i = 1; i < parts; i++)
    dst[i] = 0;
}

/// Assign one bignum to another.
inline void APInt::tcAssign(WordType *dst, const WordType *src,
                            unsigned parts) {
  for (unsigned i = 0; i < parts; i++)
    dst[i] = src[i];
}

/// Returns true if a bignum is zero, false otherwise.
inline bool APInt::tcIsZero(const WordType *src, unsigned parts) {
  for (unsigned i = 0; i < parts; i++)
    if (src[i])
      return false;

  return true;
}

/// Extract the given bit of a bignum; returns 0 or 1.
inline int APInt::tcExtractBit(const WordType *parts, unsigned bit) {
  return (parts[whichWord(bit)] & maskBit(bit)) != 0;
}

/// Set the given bit of a bignum.
inline void APInt::tcSetBit(WordType *parts, unsigned bit) {
  parts[whichWord(bit)] |= maskBit(bit);
}

/// Clears the given bit of a bignum.
inline void APInt::tcClearBit(WordType *parts, unsigned bit) {
  parts[whichWord(bit)] &= ~maskBit(bit);
}

/// Returns the bit number of the least significant set bit of a number.  If the
/// input number has no bits set UINT_MAX is returned.
inline unsigned APInt::tcLSB(const WordType *parts, unsigned n) {
  for (unsigned i = 0; i < n; i++) {
    if (parts[i] != 0) {
      unsigned lsb = ::llvm::countr_zero(parts[i]);
      return lsb + i * APINT_BITS_PER_WORD;
    }
  }

  return UINT_MAX;
}

/// Returns the bit number of the most significant set bit of a number.
/// If the input number has no bits set UINT_MAX is returned.
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

/// Copy the bit vector of width srcBITS from SRC, starting at bit srcLSB, to
/// DST, of dstCOUNT parts, such that the bit srcLSB becomes the least
/// significant bit of DST.  All high bits above srcBITS in DST are zero-filled.
/// */
inline void APInt::tcExtract(WordType *dst, unsigned dstCount,
                             const WordType *src, unsigned srcBits,
                             unsigned srcLSB) {
  unsigned dstParts = (srcBits + APINT_BITS_PER_WORD - 1) / APINT_BITS_PER_WORD;
  assert(dstParts <= dstCount);

  unsigned firstSrcPart = srcLSB / APINT_BITS_PER_WORD;
  tcAssign(dst, src + firstSrcPart, dstParts);

  unsigned shift = srcLSB % APINT_BITS_PER_WORD;
  tcShiftRight(dst, dstParts, shift);

  // We now have (dstParts * APINT_BITS_PER_WORD - shift) bits from SRC
  // in DST.  If this is less that srcBits, append the rest, else
  // clear the high bits.
  unsigned n = dstParts * APINT_BITS_PER_WORD - shift;
  if (n < srcBits) {
    WordType mask = lowBitMask(srcBits - n);
    dst[dstParts - 1] |=
        ((src[firstSrcPart + dstParts] & mask) << n % APINT_BITS_PER_WORD);
  } else if (n > srcBits) {
    if (srcBits % APINT_BITS_PER_WORD)
      dst[dstParts - 1] &= lowBitMask(srcBits % APINT_BITS_PER_WORD);
  }

  // Clear high parts.
  while (dstParts < dstCount)
    dst[dstParts++] = 0;
}

//// DST += RHS + C where C is zero or one.  Returns the carry flag.
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

/// This function adds a single "word" integer, src, to the multiple
/// "word" integer array, dst[]. dst[] is modified to reflect the addition and
/// 1 is returned if there is a carry out, otherwise 0 is returned.
/// @returns the carry of the addition.
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

/// DST -= RHS + C where C is zero or one.  Returns the carry flag.
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

/// This function subtracts a single "word" (64-bit word), src, from
/// the multi-word integer array, dst[], propagating the borrowed 1 value until
/// no further borrowing is needed or it runs out of "words" in dst.  The result
/// is 1 if "borrowing" exhausted the digits in dst, or 0 if dst was not
/// exhausted. In other words, if src > dst then this function returns 1,
/// otherwise 0.
/// @returns the borrow out of the subtraction
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

/// Negate a bignum in-place.
inline void APInt::tcNegate(WordType *dst, unsigned parts) {
  tcComplement(dst, parts);
  tcIncrement(dst, parts);
}

/// DST += SRC * MULTIPLIER + CARRY   if add is true
/// DST  = SRC * MULTIPLIER + CARRY   if add is false
/// Requires 0 <= DSTPARTS <= SRCPARTS + 1.  If DST overlaps SRC
/// they must start at the same point, i.e. DST == SRC.
/// If DSTPARTS == SRCPARTS + 1 no overflow occurs and zero is
/// returned.  Otherwise DST is filled with the least significant
/// DSTPARTS parts of the result, and if all of the omitted higher
/// parts were zero return zero, otherwise overflow occurred and
/// return one.
inline int APInt::tcMultiplyPart(WordType *dst, const WordType *src,
                                 WordType multiplier, WordType carry,
                                 unsigned srcParts, unsigned dstParts,
                                 bool add) {
  // Otherwise our writes of DST kill our later reads of SRC.
  assert(dst <= src || dst >= src + srcParts);
  assert(dstParts <= srcParts + 1);

  // N loops; minimum of dstParts and srcParts.
  unsigned n = std::min(dstParts, srcParts);

  for (unsigned i = 0; i < n; i++) {
    // [LOW, HIGH] = MULTIPLIER * SRC[i] + DST[i] + CARRY.
    // This cannot overflow, because:
    //   (n - 1) * (n - 1) + 2 (n - 1) = (n - 1) * (n + 1)
    // which is less than n^2.
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
    // Full multiplication, there is no overflow.
    assert(srcParts + 1 == dstParts);
    dst[srcParts] = carry;
    return 0;
  }

  // We overflowed if there is carry.
  if (carry)
    return 1;

  // We would overflow if any significant unwritten parts would be
  // non-zero.  This is true if any remaining src parts are non-zero
  // and the multiplier is non-zero.
  if (multiplier)
    for (unsigned i = dstParts; i < srcParts; i++)
      if (src[i])
        return 1;

  // We fitted in the narrow destination.
  return 0;
}

/// DST = LHS * RHS, where DST has the same width as the operands and
/// is filled with the least significant parts of the result.  Returns
/// one if overflow occurred, otherwise zero.  DST must be disjoint
/// from both operands.
inline int APInt::tcMultiply(WordType *dst, const WordType *lhs,
                             const WordType *rhs, unsigned parts) {
  assert(dst != lhs && dst != rhs);

  int overflow = 0;

  for (unsigned i = 0; i < parts; i++) {
    // Don't accumulate on the first iteration so we don't need to initalize
    // dst to 0.
    overflow |=
        tcMultiplyPart(&dst[i], lhs, rhs[i], 0, parts, parts - i, i != 0);
  }

  return overflow;
}

/// DST = LHS * RHS, where DST has width the sum of the widths of the
/// operands. No overflow occurs. DST must be disjoint from both operands.
inline void APInt::tcFullMultiply(WordType *dst, const WordType *lhs,
                                  const WordType *rhs, unsigned lhsParts,
                                  unsigned rhsParts) {
  // Put the narrower number on the LHS for less loops below.
  if (lhsParts > rhsParts)
    return tcFullMultiply(dst, rhs, lhs, rhsParts, lhsParts);

  assert(dst != lhs && dst != rhs);

  for (unsigned i = 0; i < lhsParts; i++) {
    // Don't accumulate on the first iteration so we don't need to initalize
    // dst to 0.
    tcMultiplyPart(&dst[i], rhs, lhs[i], 0, rhsParts, rhsParts + 1, i != 0);
  }
}

// If RHS is zero LHS and REMAINDER are left unchanged, return one.
// Otherwise set LHS to LHS / RHS with the fractional part discarded,
// set REMAINDER to the remainder, return zero.  i.e.
//
//   OLD_LHS = RHS * LHS + REMAINDER
//
// SCRATCH is a bignum of the same size as the operands and result for
// use by the routine; its contents need not be initialized and are
// destroyed.  LHS, REMAINDER and SCRATCH must be distinct.
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

  // Loop, subtracting SRHS if REMAINDER is greater and adding that to the
  // total.
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

/// Shift a bignum left Count bits in-place. Shifted in bits are zero. There are
/// no restrictions on Count.
inline void APInt::tcShiftLeft(WordType *Dst, unsigned Words, unsigned Count) {
  // Don't bother performing a no-op shift.
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
