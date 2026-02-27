#pragma once

template <unsigned int N> class [[nodiscard]] APInt {
  static_assert(N >= 1 && N <= 64, "N must be in [1,64]");

public:
  // ctors
  constexpr APInt() noexcept = default;
  explicit constexpr APInt(unsigned long val) noexcept : VAL(val) {
    clearUnusedBits();
  }
  constexpr APInt(const APInt &) noexcept = default;
  constexpr APInt(APInt &&) noexcept = default;

  constexpr APInt &operator=(const APInt &) noexcept = default;
  constexpr APInt &operator=(APInt &&) noexcept = default;
  constexpr APInt &operator=(unsigned long rhs) noexcept {
    VAL = rhs;
    clearUnusedBits();
    return *this;
  }

  // factories
  [[nodiscard]] static constexpr APInt<N> getZero() noexcept {
    return APInt<N>(0);
  }
  [[nodiscard]] static constexpr APInt<N> getMaxValue() noexcept {
    return getAllOnes();
  }
  [[nodiscard]] static constexpr APInt<N> getMinValue() noexcept {
    return APInt<N>(0);
  }
  [[nodiscard]] static constexpr APInt<N> getSignedMaxValue() noexcept {
    APInt<N> API = getAllOnes();
    API.clearBit(N - 1);
    return API;
  }
  [[nodiscard]] static constexpr APInt<N> getSignedMinValue() noexcept {
    APInt<N> API(0);
    API.setBit(N - 1);
    return API;
  }
  [[nodiscard]] static constexpr APInt<N> getAllOnes() noexcept {
    return APInt(WORDTYPE_MAX);
  }
  [[nodiscard]] static constexpr APInt<N>
  getOneBitSet(unsigned BitNo) noexcept {
    APInt<N> Res(0);
    Res.setBit(BitNo);
    return Res;
  }
  [[nodiscard]] static constexpr APInt<N>
  getHighBitsSet(unsigned hiBitsSet) noexcept {
    APInt<N> Res(0);
    Res.setHighBits(hiBitsSet);
    return Res;
  }
  [[nodiscard]] static constexpr APInt<N>
  getLowBitsSet(unsigned loBitsSet) noexcept {
    APInt<N> Res(0);
    Res.setLowBits(loBitsSet);
    return Res;
  }

  // predicates
  [[nodiscard]] constexpr bool isNegative() const noexcept {
    return (*this)[N - 1];
  }
  [[nodiscard]] constexpr bool isNonNegative() const noexcept {
    return !isNegative();
  }
  [[nodiscard]] constexpr bool isSignBitSet() const noexcept {
    return (*this)[N - 1];
  }
  [[nodiscard]] constexpr bool isSignBitClear() const noexcept {
    return !isSignBitSet();
  }
  [[nodiscard]] constexpr bool isStrictlyPositive() const noexcept {
    return isNonNegative() && !isZero();
  }
  [[nodiscard]] constexpr bool isNonPositive() const noexcept {
    return !isStrictlyPositive();
  }
  [[nodiscard]] constexpr bool isZero() const noexcept { return VAL == 0; }
  [[nodiscard]] constexpr bool isOne() const noexcept { return VAL == 1; }
  [[nodiscard]] constexpr bool isMaxValue() const noexcept {
    return isAllOnes();
  }
  [[nodiscard]] constexpr bool isMinValue() const noexcept { return isZero(); }
  [[nodiscard]] constexpr bool isIntN(unsigned n) const noexcept {
    return getActiveBits() <= n;
  }
  [[nodiscard]] constexpr bool isSignedIntN(unsigned n) const noexcept {
    return getSignificantBits() <= n;
  }
  [[nodiscard]] constexpr bool isSignMask() const noexcept {
    return isMinSignedValue();
  }
  [[nodiscard]] constexpr bool getBoolValue() const noexcept {
    return !isZero();
  }
  [[nodiscard]] constexpr bool
  isSplat(unsigned SplatSizeInBits) const noexcept {
    return *this == rotl(SplatSizeInBits);
  }
  [[nodiscard]] constexpr bool isOneBitSet(unsigned BitNo) const noexcept {
    return (*this)[BitNo] && popcount() == 1;
  }
  [[nodiscard]] constexpr bool isAllOnes() const noexcept {
    return VAL == (WORDTYPE_MAX >> (APINT_BITS_PER_WORD - N));
  }
  [[nodiscard]] constexpr bool isMaxSignedValue() const noexcept {
    return VAL == ((1ULL << (N - 1)) - 1);
  }
  [[nodiscard]] constexpr bool isMinSignedValue() const noexcept {
    return VAL == (1ULL << (N - 1));
  }
  [[nodiscard]] constexpr bool isNegatedPowerOf2() const noexcept {
    if (isNonNegative())
      return false;
    unsigned LO = countl_one();
    unsigned TZ = countr_zero();
    return (LO + TZ) == N;
  }
  [[nodiscard]] constexpr bool isMask() const noexcept {
    return VAL == (WORDTYPE_MAX >> (APINT_BITS_PER_WORD - N));
  }

  // increments/decrements
  constexpr const APInt operator++(int) noexcept {
    APInt<N> t(*this);
    ++(*this);
    return t;
  }
  constexpr const APInt &operator++() noexcept {
    ++VAL;
    return clearUnusedBits();
  }
  constexpr const APInt operator--(int) noexcept {
    APInt<N> t(*this);
    --(*this);
    return t;
  }
  constexpr const APInt &operator--() noexcept {
    --VAL;
    return clearUnusedBits();
  }
  [[nodiscard]] constexpr bool operator!() const noexcept { return isZero(); }

  // compound ops
  constexpr const APInt &operator&=(const APInt &RHS) noexcept {
    VAL &= RHS.VAL;
    return *this;
  }
  constexpr const APInt &operator&=(unsigned long RHS) noexcept {
    VAL &= RHS;
    return *this;
  }
  constexpr const APInt &operator|=(const APInt &RHS) noexcept {
    VAL |= RHS.VAL;
    return *this;
  }
  constexpr const APInt &operator|=(unsigned long RHS) noexcept {
    VAL |= RHS;
    return clearUnusedBits();
  }
  constexpr const APInt &operator^=(const APInt &RHS) noexcept {
    VAL ^= RHS.VAL;
    return *this;
  }
  constexpr const APInt &operator^=(unsigned long RHS) noexcept {
    VAL ^= RHS;
    return clearUnusedBits();
  }
  constexpr const APInt &operator*=(const APInt &RHS) noexcept {
    *this = *this * RHS;
    return *this;
  }
  constexpr const APInt &operator*=(unsigned long RHS) noexcept {
    VAL *= RHS;
    return clearUnusedBits();
  }
  constexpr const APInt &operator+=(const APInt &RHS) noexcept {
    VAL += RHS.VAL;
    return clearUnusedBits();
  }
  constexpr const APInt &operator+=(unsigned long RHS) noexcept {
    VAL += RHS;
    return clearUnusedBits();
  }
  constexpr const APInt &operator-=(const APInt &RHS) noexcept {
    VAL -= RHS.VAL;
    return clearUnusedBits();
  }
  constexpr const APInt &operator-=(unsigned long RHS) noexcept {
    VAL -= RHS;
    return clearUnusedBits();
  }

  // shifts / rotates
  constexpr const APInt &operator<<=(unsigned ShiftAmt) noexcept {
    if (ShiftAmt == N)
      VAL = 0;
    else
      VAL <<= ShiftAmt;
    return clearUnusedBits();
  }
  constexpr const APInt &operator<<=(const APInt &ShiftAmt) noexcept {
    *this <<= static_cast<unsigned>(ShiftAmt.getLimitedValue(N));
    return *this;
  }

  [[nodiscard]] constexpr const APInt
  operator*(const APInt &RHS) const noexcept {
    return APInt<N>(VAL * RHS.VAL);
  }
  [[nodiscard]] constexpr const APInt operator<<(unsigned Bits) const noexcept {
    return shl(Bits);
  }
  [[nodiscard]] constexpr const APInt
  operator<<(const APInt &Bits) const noexcept {
    return shl(Bits);
  }

  [[nodiscard]] constexpr const APInt ashr(unsigned ShiftAmt) const noexcept {
    APInt<N> R(*this);
    R.ashrInPlace(ShiftAmt);
    return R;
  }
  void constexpr ashrInPlace(unsigned ShiftAmt) noexcept {
    long s = SignExtend64(VAL);
    if (ShiftAmt == N)
      VAL = static_cast<unsigned long>(s >> (APINT_BITS_PER_WORD - 1));
    else
      VAL = static_cast<unsigned long>(s >> ShiftAmt);
    clearUnusedBits();
  }
  [[nodiscard]] constexpr const APInt lshr(unsigned ShiftAmt) const noexcept {
    APInt<N> R(*this);
    R.lshrInPlace(ShiftAmt);
    return R;
  }
  void constexpr lshrInPlace(unsigned ShiftAmt) noexcept {
    if (ShiftAmt == N)
      VAL = 0;
    else
      VAL >>= ShiftAmt;
  }
  [[nodiscard]] constexpr const APInt shl(unsigned ShiftAmt) const noexcept {
    APInt<N> R(*this);
    R <<= ShiftAmt;
    return R;
  }

  [[nodiscard]] constexpr const APInt relativeLShr(int s) const noexcept {
    return s > 0 ? lshr(static_cast<unsigned>(s))
                 : shl(static_cast<unsigned>(-s));
  }
  [[nodiscard]] constexpr const APInt relativeLShl(int s) const noexcept {
    return relativeLShr(-s);
  }
  [[nodiscard]] constexpr const APInt relativeAShr(int s) const noexcept {
    return s > 0 ? ashr(static_cast<unsigned>(s))
                 : shl(static_cast<unsigned>(-s));
  }
  [[nodiscard]] constexpr const APInt relativeAShl(int s) const noexcept {
    return relativeAShr(-s);
  }

  [[nodiscard]] constexpr const APInt rotl(unsigned rotateAmt) const noexcept {
    if (N == 0)
      return *this;
    rotateAmt %= N;
    if (rotateAmt == 0)
      return *this;
    return shl(rotateAmt) | lshr(N - rotateAmt);
  }
  [[nodiscard]] constexpr const APInt rotr(unsigned rotateAmt) const noexcept {
    if (N == 0)
      return *this;
    rotateAmt %= N;
    if (rotateAmt == 0)
      return *this;
    return lshr(rotateAmt) | shl(N - rotateAmt);
  }

  [[nodiscard]] constexpr const APInt ashr(const APInt &S) const noexcept {
    APInt<N> R(*this);
    R.ashrInPlace(S);
    return R;
  }
  void constexpr ashrInPlace(const APInt &S) noexcept {
    ashrInPlace(static_cast<unsigned>(S.getLimitedValue(N)));
  }
  [[nodiscard]] constexpr const APInt lshr(const APInt &S) const noexcept {
    APInt<N> R(*this);
    R.lshrInPlace(S);
    return R;
  }
  void constexpr lshrInPlace(const APInt &S) noexcept {
    lshrInPlace(static_cast<unsigned>(S.getLimitedValue(N)));
  }
  [[nodiscard]] constexpr const APInt shl(const APInt &S) const noexcept {
    APInt<N> R(*this);
    R <<= S;
    return R;
  }

  [[nodiscard]] constexpr const APInt rotl(const APInt &A) const noexcept {
    return rotl(rotateModulo(A));
  }
  [[nodiscard]] constexpr const APInt rotr(const APInt &A) const noexcept {
    return rotr(rotateModulo(A));
  }

  // div/mod
  [[nodiscard]] constexpr const APInt udiv(const APInt &RHS) const noexcept {
    return APInt(VAL / RHS.VAL);
  }
  [[nodiscard]] constexpr const APInt udiv(unsigned long RHS) const noexcept {
    return APInt(VAL / RHS);
  }
  [[nodiscard]] constexpr const APInt sdiv(const APInt &RHS) const noexcept {
    if (isNegative()) {
      if (RHS.isNegative())
        return (-(*this)).udiv(-RHS);
      return -((-(*this)).udiv(RHS));
    }
    if (RHS.isNegative())
      return -(this->udiv(-RHS));
    return this->udiv(RHS);
  }
  [[nodiscard]] constexpr const APInt sdiv(long RHS) const noexcept {
    if (isNegative()) {
      if (RHS < 0)
        return (-(*this)).udiv(static_cast<unsigned long>(-RHS));
      return -((-(*this)).udiv(static_cast<unsigned long>(RHS)));
    }
    if (RHS < 0)
      return -(this->udiv(static_cast<unsigned long>(-RHS)));
    return this->udiv(static_cast<unsigned long>(RHS));
  }

  [[nodiscard]] constexpr const APInt urem(const APInt &RHS) const noexcept {
    return APInt<N>(VAL % RHS.VAL);
  }
  [[nodiscard]] constexpr unsigned long urem(unsigned long RHS) const noexcept {
    return VAL % RHS;
  }
  [[nodiscard]] constexpr const APInt srem(const APInt &RHS) const noexcept {
    if (isNegative()) {
      if (RHS.isNegative())
        return -((-(*this)).urem(-RHS));
      return -((-(*this)).urem(RHS));
    }
    if (RHS.isNegative())
      return this->urem(-RHS);
    return this->urem(RHS);
  }
  [[nodiscard]] constexpr long srem(long RHS) const noexcept {
    if (isNegative()) {
      if (RHS < 0)
        return -static_cast<long>(
            (-(*this)).urem(static_cast<unsigned long>(-RHS)));
      return -static_cast<long>(
          (-(*this)).urem(static_cast<unsigned long>(RHS)));
    }
    if (RHS < 0)
      return static_cast<long>(this->urem(static_cast<unsigned long>(-RHS)));
    return static_cast<long>(this->urem(static_cast<unsigned long>(RHS)));
  }

  static constexpr void udivrem(const APInt &LHS, const APInt &RHS, APInt &Q,
                                APInt &R) noexcept {
    unsigned long q = LHS.VAL / RHS.VAL;
    unsigned long r = LHS.VAL % RHS.VAL;
    Q = APInt<N>(q);
    R = APInt<N>(r);
  }
  static constexpr void udivrem(const APInt &LHS, unsigned long RHS, APInt &Q,
                                unsigned long &R) noexcept {
    unsigned long q = LHS.VAL / RHS;
    R = LHS.VAL % RHS;
    Q = APInt<N>(q);
  }
  static constexpr void sdivrem(const APInt &LHS, const APInt &RHS, APInt &Q,
                                APInt &R) noexcept {
    if (LHS.isNegative()) {
      if (RHS.isNegative()) {
        APInt<N>::udivrem(-LHS, -RHS, Q, R);
      } else {
        APInt<N>::udivrem(-LHS, RHS, Q, R);
        Q.negate();
      }
      R.negate();
    } else if (RHS.isNegative()) {
      APInt<N>::udivrem(LHS, -RHS, Q, R);
      Q.negate();
    } else {
      APInt<N>::udivrem(LHS, RHS, Q, R);
    }
  }
  static constexpr void sdivrem(const APInt &LHS, long RHS, APInt &Q,
                                long &R) noexcept {
    unsigned long Rtmp = static_cast<unsigned long>(R);
    if (LHS.isNegative()) {
      if (RHS < 0)
        APInt<N>::udivrem(-LHS, static_cast<unsigned long>(-RHS), Q, Rtmp);
      else {
        APInt<N>::udivrem(-LHS, static_cast<unsigned long>(RHS), Q, Rtmp);
        Q.negate();
      }
      Rtmp = static_cast<unsigned long>(-static_cast<long>(Rtmp));
    } else if (RHS < 0) {
      APInt<N>::udivrem(LHS, static_cast<unsigned long>(-RHS), Q, Rtmp);
      Q.negate();
    } else {
      APInt<N>::udivrem(LHS, static_cast<unsigned long>(RHS), Q, Rtmp);
    }
    R = static_cast<long>(Rtmp);
  }

  // overflow / saturation helpers
  [[nodiscard]] const constexpr APInt sadd_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    APInt<N> Res = *this + RHS;
    Overflow = (isNonNegative() == RHS.isNonNegative()) &&
               (Res.isNonNegative() != isNonNegative());
    return Res;
  }
  [[nodiscard]] const constexpr APInt uadd_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    APInt<N> Res = *this + RHS;
    Overflow = Res.ult(RHS);
    return Res;
  }
  [[nodiscard]] const constexpr APInt ssub_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    APInt<N> Res = *this - RHS;
    Overflow = (isNonNegative() != RHS.isNonNegative()) &&
               (Res.isNonNegative() != isNonNegative());
    return Res;
  }
  [[nodiscard]] const constexpr APInt usub_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    APInt<N> Res = *this - RHS;
    Overflow = Res.ugt(*this);
    return Res;
  }

  [[nodiscard]] const constexpr APInt sdiv_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    Overflow = isMinSignedValue() && RHS.isAllOnes();
    return sdiv(RHS);
  }
  [[nodiscard]] const constexpr APInt smul_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    APInt<N> Res = *this * RHS;
    if (RHS != 0)
      Overflow =
          Res.sdiv(RHS) != *this || (isMinSignedValue() && RHS.isAllOnes());
    else
      Overflow = false;
    return Res;
  }
  [[nodiscard]] const constexpr APInt umul_ov(const APInt &RHS,
                                              bool &Overflow) const noexcept {
    if (countl_zero() + RHS.countl_zero() + 2 <= N) {
      Overflow = true;
      return *this * RHS;
    }
    APInt<N> Res = lshr(1) * RHS;
    Overflow = Res.isNegative();
    Res <<= 1;
    if ((*this)[0]) {
      Res += RHS;
      if (Res.ult(RHS))
        Overflow = true;
    }
    return Res;
  }

  [[nodiscard]] const constexpr APInt sshl_ov(const APInt &ShAmt,
                                              bool &Overflow) const noexcept {
    return sshl_ov(static_cast<unsigned>(ShAmt.getLimitedValue(N)), Overflow);
  }
  [[nodiscard]] const constexpr APInt sshl_ov(unsigned ShAmt,
                                              bool &Overflow) const noexcept {
    Overflow = ShAmt >= N;
    if (Overflow)
      return APInt<N>(0);
    if (isNonNegative())
      Overflow = ShAmt >= countl_zero();
    else
      Overflow = ShAmt >= countl_one();
    return *this << ShAmt;
  }
  [[nodiscard]] const constexpr APInt ushl_ov(const APInt &ShAmt,
                                              bool &Overflow) const noexcept {
    return ushl_ov(static_cast<unsigned>(ShAmt.getLimitedValue(N)), Overflow);
  }
  [[nodiscard]] const constexpr APInt ushl_ov(unsigned ShAmt,
                                              bool &Overflow) const noexcept {
    Overflow = ShAmt >= N;
    if (Overflow)
      return APInt<N>(0);
    Overflow = ShAmt > countl_zero();
    return *this << ShAmt;
  }
  [[nodiscard]] const constexpr APInt
  sfloordiv_ov(const APInt &RHS, bool &Overflow) const noexcept {
    APInt<N> q = sdiv_ov(RHS, Overflow);
    if ((q * RHS != *this) && (isNegative() != RHS.isNegative()))
      return q - 1;
    return q;
  }

  [[nodiscard]] const constexpr APInt
  sadd_sat(const APInt &RHS) const noexcept {
    bool ov;
    APInt<N> r = sadd_ov(RHS, ov);
    return ov ? (isNegative() ? APInt<N>::getSignedMinValue()
                              : APInt<N>::getSignedMaxValue())
              : r;
  }
  [[nodiscard]] const constexpr APInt
  uadd_sat(const APInt &RHS) const noexcept {
    bool ov;
    APInt<N> r = uadd_ov(RHS, ov);
    return ov ? APInt<N>::getMaxValue() : r;
  }
  [[nodiscard]] const constexpr APInt
  ssub_sat(const APInt &RHS) const noexcept {

    bool ov;
    APInt<N> r = ssub_ov(RHS, ov);
    return ov ? (isNegative() ? APInt<N>::getSignedMinValue()
                              : APInt<N>::getSignedMaxValue())
              : r;
  }
  [[nodiscard]] const constexpr APInt
  usub_sat(const APInt &RHS) const noexcept {
    bool ov;
    APInt<N> r = usub_ov(RHS, ov);
    return ov ? APInt<N>(0) : r;
  }
  [[nodiscard]] const constexpr APInt
  smul_sat(const APInt &RHS) const noexcept {
    bool ov;
    APInt<N> r = smul_ov(RHS, ov);
    if (!ov)
      return r;
    bool neg = isNegative() ^ RHS.isNegative();
    return neg ? APInt<N>::getSignedMinValue()
               : APInt<N>::getSignedMaxValue();
  }
  [[nodiscard]] const constexpr APInt
  umul_sat(const APInt &RHS) const noexcept {
    bool ov;
    APInt<N> r = umul_ov(RHS, ov);
    return ov ? APInt<N>::getMaxValue() : r;
  }
  [[nodiscard]] const constexpr APInt
  sshl_sat(const APInt &RHS) const noexcept {
    return sshl_sat(static_cast<unsigned>(RHS.getLimitedValue(N)));
  }
  [[nodiscard]] const constexpr APInt sshl_sat(unsigned RHS) const noexcept {
    bool ov;
    APInt<N> r = sshl_ov(RHS, ov);
    return ov ? (isNegative() ? APInt<N>::getSignedMinValue()
                              : APInt<N>::getSignedMaxValue())
              : r;
  }
  [[nodiscard]] const constexpr APInt
  ushl_sat(const APInt &RHS) const noexcept {
    return ushl_sat(static_cast<unsigned>(RHS.getLimitedValue(N)));
  }
  [[nodiscard]] const constexpr APInt ushl_sat(unsigned RHS) const noexcept {
    bool ov;
    APInt<N> r = ushl_ov(RHS, ov);
    return ov ? APInt<N>::getMaxValue() : r;
  }

  // bit access
  [[nodiscard]] constexpr bool operator[](unsigned bitPosition) const noexcept {
    return (maskBit(bitPosition) & VAL) != 0;
  }

  // comparisons
  [[nodiscard]] constexpr bool operator==(const APInt &RHS) const noexcept {
    return VAL == RHS.VAL;
  }
  [[nodiscard]] constexpr bool operator==(unsigned long Val) const noexcept {
    return getZExtValue() == Val;
  }
  [[nodiscard]] constexpr bool operator!=(const APInt &RHS) const noexcept {
    return !((*this) == RHS);
  }
  [[nodiscard]] constexpr bool operator!=(unsigned long Val) const noexcept {
    return !((*this) == Val);
  }

  [[nodiscard]] constexpr bool eq(const APInt &RHS) const noexcept {
    return (*this) == RHS;
  }

  [[nodiscard]] constexpr bool ult(const APInt &RHS) const noexcept {
    return compare(RHS) < 0;
  }
  [[nodiscard]] constexpr bool ult(unsigned long RHS) const noexcept {
    return getZExtValue() < RHS;
  }
  [[nodiscard]] constexpr bool slt(const APInt &RHS) const noexcept {
    return compareSigned(RHS) < 0;
  }
  [[nodiscard]] constexpr bool slt(long RHS) const noexcept {
    return getSExtValue() < RHS;
  }
  [[nodiscard]] constexpr bool ule(const APInt &RHS) const noexcept {
    return compare(RHS) <= 0;
  }
  [[nodiscard]] constexpr bool ule(unsigned long RHS) const noexcept {
    return !ugt(RHS);
  }
  [[nodiscard]] constexpr bool sle(const APInt &RHS) const noexcept {
    return compareSigned(RHS) <= 0;
  }
  [[nodiscard]] constexpr bool sle(unsigned long RHS) const noexcept {
    return !sgt(static_cast<long>(RHS));
  }
  [[nodiscard]] constexpr bool ugt(const APInt &RHS) const noexcept {
    return !ule(RHS);
  }
  [[nodiscard]] constexpr bool ugt(unsigned long RHS) const noexcept {
    return getZExtValue() > RHS;
  }
  [[nodiscard]] constexpr bool sgt(const APInt &RHS) const noexcept {
    return !sle(RHS);
  }
  [[nodiscard]] constexpr bool sgt(long RHS) const noexcept {
    return getSExtValue() > RHS;
  }
  [[nodiscard]] constexpr bool uge(const APInt &RHS) const noexcept {
    return !ult(RHS);
  }
  [[nodiscard]] constexpr bool uge(unsigned long RHS) const noexcept {
    return !ult(RHS);
  }
  [[nodiscard]] constexpr bool sge(const APInt &RHS) const noexcept {
    return !slt(RHS);
  }
  [[nodiscard]] constexpr bool sge(long RHS) const noexcept {
    return !slt(RHS);
  }

  [[nodiscard]] constexpr bool intersects(const APInt &RHS) const noexcept {
    return (VAL & RHS.VAL) != 0;
  }
  [[nodiscard]] constexpr bool isSubsetOf(const APInt &RHS) const noexcept {
    return (VAL & ~RHS.VAL) == 0;
  }

  // mutators
  constexpr void setAllBits() noexcept {
    VAL = WORDTYPE_MAX;
    clearUnusedBits();
  }
  constexpr void setBit(unsigned BitPosition) noexcept {
    VAL |= maskBit(BitPosition);
  }
  constexpr void setBits(unsigned loBit, unsigned hiBit) noexcept {
    if (loBit == hiBit)
      return;
    unsigned long mask =
        WORDTYPE_MAX >> (APINT_BITS_PER_WORD - (hiBit - loBit));
    mask <<= loBit;
    VAL |= mask;
  }
  constexpr void setLowBits(unsigned loBits) noexcept { setBits(0, loBits); }
  constexpr void setHighBits(unsigned hiBits) noexcept {
    setBits(N - hiBits, N);
  }
  constexpr void setSignBit() noexcept { setBit(N - 1); }
  constexpr void setBitVal(unsigned BitPosition, bool BitValue) noexcept {
    BitValue ? setBit(BitPosition) : clearBit(BitPosition);
  }
  constexpr void clearAllBits() noexcept { VAL = 0; }
  constexpr void clearBit(unsigned BitPosition) noexcept {
    VAL &= ~maskBit(BitPosition);
  }
  constexpr void clearSignBit() noexcept { clearBit(N - 1); }
  constexpr void clearLowBits(unsigned loBits) noexcept {
    APInt<N> Keep = getHighBitsSet(N - loBits);
    *this &= Keep;
  }
  constexpr void clearHighBits(unsigned hiBits) noexcept {
    APInt<N> Keep = getLowBitsSet(N - hiBits);
    *this &= Keep;
  }
  constexpr void flipAllBits() noexcept {
    VAL ^= WORDTYPE_MAX;
    clearUnusedBits();
  }
  constexpr void negate() noexcept {
    flipAllBits();
    ++(*this);
  }
  constexpr void flipBit(unsigned bitPosition) noexcept {
    setBitVal(bitPosition, !(*this)[bitPosition]);
  }

  // extraction
  [[nodiscard]] constexpr const APInt
  extractBits(unsigned bitPosition) const noexcept {
    return APInt<N>(VAL >> bitPosition);
  }
  [[nodiscard]] constexpr unsigned long
  extractBitsAsZExtValue(unsigned bitPosition) const noexcept {
    return (VAL >> bitPosition) & (N == 64 ? WORDTYPE_MAX : ((1ULL << N) - 1));
  }

  // introspection
  [[nodiscard]] constexpr unsigned getActiveBits() const noexcept {
    return N - countl_zero();
  }
  [[nodiscard]] constexpr unsigned getSignificantBits() const noexcept {
    return N - getNumSignBits() + 1;
  }
  [[nodiscard]] constexpr unsigned long getZExtValue() const noexcept {
    return VAL;
  }
  [[nodiscard]] constexpr long getSExtValue() const noexcept {
    return SignExtend64(VAL);
  }

  [[nodiscard]] constexpr unsigned countl_zero() const noexcept {
    const unsigned unused = APINT_BITS_PER_WORD - N;
    unsigned clz =
        (VAL == 0) ? 64U : static_cast<unsigned int>(__builtin_clzll(VAL));
    return clz - unused;
  }
  [[nodiscard]] constexpr unsigned countl_one() const noexcept {
    unsigned long tmp = ~(VAL << (APINT_BITS_PER_WORD - N));
    return tmp == 0 ? 64U : static_cast<unsigned int>(__builtin_clzll(tmp));
  }
  [[nodiscard]] constexpr unsigned getNumSignBits() const noexcept {
    return isNegative() ? countl_one() : countl_zero();
  }
  [[nodiscard]] constexpr unsigned countr_zero() const noexcept {
    unsigned tz = static_cast<unsigned int>(__builtin_ctzll(VAL));
    return (tz > N) ? N : tz;
  }
  [[nodiscard]] constexpr unsigned countr_one() const noexcept {
    return static_cast<unsigned int>(__builtin_ctzll(~VAL));
  }
  [[nodiscard]] constexpr unsigned popcount() const noexcept {
    return static_cast<unsigned int>(__builtin_popcountll(VAL));
  }

  [[nodiscard]] constexpr unsigned logBase2() const noexcept {
    return getActiveBits() - 1;
  }
  [[nodiscard]] constexpr unsigned ceilLogBase2() const noexcept {
    APInt<N> t(*this);
    --t;
    return t.getActiveBits();
  }
  [[nodiscard]] const constexpr APInt abs() const noexcept {
    return isNegative() ? -(*this) : *this;
  }

  [[nodiscard]] const constexpr APInt multiplicativeInverse() const {
    APInt<N> Factor = *this;
    APInt<N> T(0);
    while (!(T = *this * Factor).isOne())
      Factor *= APInt<N>(2) - T;
    return Factor;
  }

private:
  static constexpr unsigned long WORDTYPE_MAX = ~static_cast<unsigned long>(0);
  static constexpr unsigned APINT_WORD_SIZE = sizeof(unsigned long);
  static constexpr unsigned APINT_BITS_PER_WORD = APINT_WORD_SIZE * 8;

  unsigned long VAL{0};

  [[nodiscard]] static constexpr unsigned
  rotateModulo(const APInt &amt) noexcept {
    APInt<N> rot = amt;
    rot = rot.urem(APInt<N>(N));
    return static_cast<unsigned>(rot.getLimitedValue(N));
  }
  [[nodiscard]] static constexpr long SignExtend64(unsigned long X) noexcept {
    const unsigned shift = 64U - N;
    // arithmetic shift from unsigned requires cast
    return static_cast<long>(static_cast<long>(X) << shift) >> shift;
  }

  [[nodiscard]] static constexpr unsigned long
  maskBit(unsigned bitPosition) noexcept {
    return 1ULL << bitPosition;
  }

  constexpr APInt &clearUnusedBits() noexcept {
    constexpr const unsigned WordBits = ((N - 1) % APINT_BITS_PER_WORD) + 1;
    constexpr unsigned long mask =
        (N == 0) ? 0ULL : (WORDTYPE_MAX >> (APINT_BITS_PER_WORD - WordBits));
    VAL &= mask;
    return *this;
  }

  [[nodiscard]] constexpr int compare(const APInt &RHS) const noexcept {
    if (VAL < RHS.VAL)
      return -1;
    if (VAL > RHS.VAL)
      return +1;
    return 0;
  }
  [[nodiscard]] constexpr int compareSigned(const APInt &RHS) const noexcept {
    auto lhs = SignExtend64(VAL);
    auto rhs = SignExtend64(RHS.VAL);
    if (lhs < rhs)
      return -1;
    if (lhs > rhs)
      return +1;
    return 0;
  }

  [[nodiscard]] constexpr unsigned long
  getLimitedValue(unsigned long limit = WORDTYPE_MAX) const noexcept {
    return ugt(limit) ? limit : getZExtValue();
  }
};

// free operators kept inline
template <unsigned int N>
inline constexpr bool operator==(unsigned long V1,
                                 const APInt<N> &V2) noexcept {
  return V2 == V1;
}
template <unsigned int N>
inline constexpr bool operator!=(unsigned long V1,
                                 const APInt<N> &V2) noexcept {
  return V2 != V1;
}

template <unsigned int N>
inline constexpr APInt<N> operator~(APInt<N> v) noexcept {
  v.flipAllBits();
  return v;
}

template <unsigned int N>
inline constexpr APInt<N> operator&(APInt<N> a, const APInt<N> &b) noexcept {
  a &= b;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator&(const APInt<N> &a, APInt<N> &&b) noexcept {
  b &= a;
  return b;
}
template <unsigned int N>
inline constexpr APInt<N> operator&(APInt<N> a, unsigned long rhs) noexcept {
  a &= rhs;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator&(unsigned long lhs, APInt<N> b) noexcept {
  b &= lhs;
  return b;
}

template <unsigned int N>
inline constexpr APInt<N> operator|(APInt<N> a, const APInt<N> &b) noexcept {
  a |= b;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator|(const APInt<N> &a, APInt<N> &&b) noexcept {
  b |= a;
  return b;
}
template <unsigned int N>
inline constexpr APInt<N> operator|(APInt<N> a, unsigned long rhs) noexcept {
  a |= rhs;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator|(unsigned long lhs, APInt<N> b) noexcept {
  b |= lhs;
  return b;
}

template <unsigned int N>
inline constexpr APInt<N> operator^(APInt<N> a, const APInt<N> &b) noexcept {
  a ^= b;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator^(const APInt<N> &a, APInt<N> &&b) noexcept {
  b ^= a;
  return b;
}
template <unsigned int N>
inline constexpr APInt<N> operator^(APInt<N> a, unsigned long rhs) noexcept {
  a ^= rhs;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator^(unsigned long lhs, APInt<N> b) noexcept {
  b ^= lhs;
  return b;
}

template <unsigned int N>
inline constexpr APInt<N> operator+(APInt<N> a, const APInt<N> &b) noexcept {
  a += b;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator+(const APInt<N> &a, APInt<N> &&b) noexcept {
  b += a;
  return b;
}
template <unsigned int N>
inline constexpr APInt<N> operator+(APInt<N> a, unsigned long rhs) noexcept {
  a += rhs;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator+(unsigned long lhs, APInt<N> b) noexcept {
  b += lhs;
  return b;
}

template <unsigned int N>
inline constexpr APInt<N> operator-(APInt<N> a, const APInt<N> &b) noexcept {
  a -= b;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator-(const APInt<N> &a, APInt<N> &&b) noexcept {
  b.negate();
  b += a;
  return b;
}
template <unsigned int N>
inline constexpr APInt<N> operator-(APInt<N> a, unsigned long rhs) noexcept {
  a -= rhs;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator-(unsigned long lhs, APInt<N> b) noexcept {
  b.negate();
  b += lhs;
  return b;
}

template <unsigned int N>
inline constexpr APInt<N> operator*(APInt<N> a, unsigned long rhs) noexcept {
  a *= rhs;
  return a;
}
template <unsigned int N>
inline constexpr APInt<N> operator*(unsigned long lhs, APInt<N> b) noexcept {
  b *= lhs;
  return b;
}

template <unsigned int N>
inline constexpr APInt<N> operator-(APInt<N> v) noexcept {
  v.negate();
  return v;
}

namespace APIntOps {
// signed/unsigned min/max
template <unsigned int N>
[[nodiscard]] inline constexpr const APInt<N> &
smin(const APInt<N> &A, const APInt<N> &B) noexcept {
  return A.slt(B) ? A : B;
}
template <unsigned int N>
[[nodiscard]] inline constexpr const APInt<N> &
smax(const APInt<N> &A, const APInt<N> &B) noexcept {
  return A.sgt(B) ? A : B;
}
template <unsigned int N>
[[nodiscard]] inline constexpr const APInt<N> &
umin(const APInt<N> &A, const APInt<N> &B) noexcept {
  return A.ult(B) ? A : B;
}
template <unsigned int N>
[[nodiscard]] inline constexpr const APInt<N> &
umax(const APInt<N> &A, const APInt<N> &B) noexcept {
  return A.ugt(B) ? A : B;
}

template <unsigned int N>
[[nodiscard]] inline constexpr APInt<N> abds(const APInt<N> &A,
                                             const APInt<N> &B) noexcept {
  return A.sge(B) ? (A - B) : (B - A);
}
template <unsigned int N>
[[nodiscard]] inline constexpr APInt<N> abdu(const APInt<N> &A,
                                             const APInt<N> &B) noexcept {
  return A.uge(B) ? (A - B) : (B - A);
}

template <unsigned int N>
[[nodiscard]] constexpr const APInt<N> avgFloorS(const APInt<N> &C1,
                                                 const APInt<N> &C2) noexcept {
  return (C1 & C2) + (C1 ^ C2).ashr(1);
}
template <unsigned int N>
[[nodiscard]] constexpr const APInt<N> avgFloorU(const APInt<N> &C1,
                                                 const APInt<N> &C2) noexcept {
  return (C1 & C2) + (C1 ^ C2).lshr(1);
}
template <unsigned int N>
[[nodiscard]] constexpr const APInt<N> avgCeilS(const APInt<N> &C1,
                                                const APInt<N> &C2) noexcept {
  return (C1 | C2) - (C1 ^ C2).ashr(1);
}
template <unsigned int N>
[[nodiscard]] constexpr const APInt<N> avgCeilU(const APInt<N> &C1,
                                                const APInt<N> &C2) noexcept {
  return (C1 | C2) - (C1 ^ C2).lshr(1);
}
} // namespace APIntOps

extern template class APInt<1>;
extern template class APInt<2>;
extern template class APInt<3>;
extern template class APInt<4>;
extern template class APInt<5>;
extern template class APInt<6>;
extern template class APInt<7>;
extern template class APInt<8>;
extern template class APInt<9>;
extern template class APInt<10>;
extern template class APInt<11>;
extern template class APInt<12>;
extern template class APInt<13>;
extern template class APInt<14>;
extern template class APInt<15>;
extern template class APInt<16>;
extern template class APInt<17>;
extern template class APInt<18>;
extern template class APInt<19>;
extern template class APInt<20>;
extern template class APInt<21>;
extern template class APInt<22>;
extern template class APInt<23>;
extern template class APInt<24>;
extern template class APInt<25>;
extern template class APInt<26>;
extern template class APInt<27>;
extern template class APInt<28>;
extern template class APInt<29>;
extern template class APInt<30>;
extern template class APInt<31>;
extern template class APInt<32>;
extern template class APInt<33>;
extern template class APInt<34>;
extern template class APInt<35>;
extern template class APInt<36>;
extern template class APInt<37>;
extern template class APInt<38>;
extern template class APInt<39>;
extern template class APInt<40>;
extern template class APInt<41>;
extern template class APInt<42>;
extern template class APInt<43>;
extern template class APInt<44>;
extern template class APInt<45>;
extern template class APInt<46>;
extern template class APInt<47>;
extern template class APInt<48>;
extern template class APInt<49>;
extern template class APInt<50>;
extern template class APInt<51>;
extern template class APInt<52>;
extern template class APInt<53>;
extern template class APInt<54>;
extern template class APInt<55>;
extern template class APInt<56>;
extern template class APInt<57>;
extern template class APInt<58>;
extern template class APInt<59>;
extern template class APInt<60>;
extern template class APInt<61>;
extern template class APInt<62>;
extern template class APInt<63>;
extern template class APInt<64>;
