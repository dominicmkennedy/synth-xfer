#ifndef LLVM_CONSTANTRANGE_STANDALONE_H
#define LLVM_CONSTANTRANGE_STANDALONE_H

#include <algorithm>
#include <cassert>
#include <cstdlib>
#include <optional>
#include <utility>

#include "APInt.h"
#include "KnownBits.h"

namespace llvm {
struct OverflowingBinaryOperator {
  enum { NoUnsignedWrap = 1u, NoSignedWrap = 2u };
};

struct KnownBits;

class [[nodiscard]] ConstantRange {
  APInt Lower, Upper;

  /// Create empty constant range with same bitwidth.
  ConstantRange getEmpty() const { return ConstantRange(getBitWidth(), false); }

  /// Create full constant range with same bitwidth.
  ConstantRange getFull() const { return ConstantRange(getBitWidth(), true); }

public:
  /// Initialize a full or empty set for the specified bit width.
  explicit ConstantRange(uint32_t BitWidth, bool isFullSet);

  /// Initialize a range to hold the single specified value.
  ConstantRange(APInt Value);

  /// Initialize a range of values explicitly. This will assert out if
  /// Lower==Upper and Lower != Min or Max value for its type. It will also
  /// assert out if the two APInt's are not the same bit width.
  ConstantRange(APInt Lower, APInt Upper);

  /// Create empty constant range with the given bit width.
  static ConstantRange getEmpty(uint32_t BitWidth) {
    return ConstantRange(BitWidth, false);
  }

  /// Create full constant range with the given bit width.
  static ConstantRange getFull(uint32_t BitWidth) {
    return ConstantRange(BitWidth, true);
  }

  /// Create non-empty constant range with the given bounds. If Lower and
  /// Upper are the same, a full range is returned.
  static ConstantRange getNonEmpty(APInt Lower, APInt Upper) {
    if (Lower == Upper)
      return getFull(Lower.getBitWidth());
    return ConstantRange(std::move(Lower), std::move(Upper));
  }

  /// Initialize a range based on a known bits constraint. The IsSigned flag
  /// indicates whether the constant range should not wrap in the signed or
  /// unsigned domain.
  static ConstantRange fromKnownBits(const KnownBits &Known, bool IsSigned);

  /// Split the ConstantRange into positive and negative components, ignoring
  /// zero values.
  std::pair<ConstantRange, ConstantRange> splitPosNeg() const;

  /// Initialize a range containing all values X that satisfy `(X & Mask)
  /// != C`. Note that the range returned may contain values where `(X & Mask)
  /// == C` holds, making it less precise, but still conservative.
  /// Return the lower value for this range.
  const APInt &getLower() const { return Lower; }

  /// Return the upper value for this range.
  const APInt &getUpper() const { return Upper; }

  /// Get the bit width of this ConstantRange.
  uint32_t getBitWidth() const { return Lower.getBitWidth(); }

  /// Return true if this set contains all of the elements possible
  /// for this data-type.
  bool isFullSet() const;

  /// Return true if this set contains no members.
  bool isEmptySet() const;

  /// Return true if this set wraps around the unsigned domain. Special cases:
  ///  * Empty set: Not wrapped.
  ///  * Full set: Not wrapped.
  ///  * [X, 0) == [X, Max]: Not wrapped.
  bool isWrappedSet() const;

  /// Return true if the exclusive upper bound wraps around the unsigned
  /// domain. Special cases:
  ///  * Empty set: Not wrapped.
  ///  * Full set: Not wrapped.
  ///  * [X, 0): Wrapped.
  bool isUpperWrapped() const;

  /// Return true if this set wraps around the signed domain. Special cases:
  ///  * Empty set: Not wrapped.
  ///  * Full set: Not wrapped.
  ///  * [X, SignedMin) == [X, SignedMax]: Not wrapped.
  bool isSignWrappedSet() const;

  /// Return true if the (exclusive) upper bound wraps around the signed
  /// domain. Special cases:
  ///  * Empty set: Not wrapped.
  ///  * Full set: Not wrapped.
  ///  * [X, SignedMin): Wrapped.
  bool isUpperSignWrapped() const;

  /// Return true if the specified value is in the set.
  bool contains(const APInt &Val) const;

  /// Return true if the other range is a subset of this one.
  bool contains(const ConstantRange &CR) const;

  /// If this set contains a single element, return it, otherwise return null.
  const APInt *getSingleElement() const {
    if (Upper == Lower + 1)
      return &Lower;
    return nullptr;
  }

  /// If this set contains all but a single element, return it, otherwise return
  /// null.
  const APInt *getSingleMissingElement() const {
    if (Lower == Upper + 1)
      return &Upper;
    return nullptr;
  }

  /// Return true if this set contains exactly one member.
  bool isSingleElement() const { return getSingleElement() != nullptr; }

  /// Compare set size of this range with the range CR.
  bool isSizeStrictlySmallerThan(const ConstantRange &CR) const;

  /// Compare set size of this range with Value.
  bool isSizeLargerThan(uint64_t MaxSize) const;

  /// Return true if all values in this range are negative.
  bool isAllNegative() const;

  /// Return true if all values in this range are non-negative.
  bool isAllNonNegative() const;

  /// Return true if all values in this range are positive.
  bool isAllPositive() const;

  /// Return the largest unsigned value contained in the ConstantRange.
  APInt getUnsignedMax() const;

  /// Return the smallest unsigned value contained in the ConstantRange.
  APInt getUnsignedMin() const;

  /// Return the largest signed value contained in the ConstantRange.
  APInt getSignedMax() const;

  /// Return the smallest signed value contained in the ConstantRange.
  APInt getSignedMin() const;

  /// Return true if this range is equal to another range.
  bool operator==(const ConstantRange &CR) const {
    return Lower == CR.Lower && Upper == CR.Upper;
  }
  bool operator!=(const ConstantRange &CR) const { return !operator==(CR); }

  /// Compute the maximal number of active bits needed to represent every value
  /// in this range.
  unsigned getActiveBits() const;

  /// Compute the maximal number of bits needed to represent every value
  /// in this signed range.
  unsigned getMinSignedBits() const;

  /// Subtract the specified constant from the endpoints of this constant range.
  ConstantRange subtract(const APInt &CI) const;

  /// Subtract the specified range from this range (aka relative complement of
  /// the sets).
  ConstantRange difference(const ConstantRange &CR) const;

  /// If represented precisely, the result of some range operations may consist
  /// of multiple disjoint ranges. As only a single range may be returned, any
  /// range covering these disjoint ranges constitutes a valid result, but some
  /// may be more useful than others depending on context. The preferred range
  /// type specifies whether a range that is non-wrapping in the unsigned or
  /// signed domain, or has the smallest size, is preferred. If a signedness is
  /// preferred but all ranges are non-wrapping or all wrapping, then the
  /// smallest set size is preferred. If there are multiple smallest sets, any
  /// one of them may be returned.
  enum PreferredRangeType { Smallest, Unsigned, Signed };

  /// Return the range that results from the intersection of this range with
  /// another range. If the intersection is disjoint, such that two results
  /// are possible, the preferred range is determined by the PreferredRangeType.
  ConstantRange intersectWith(const ConstantRange &CR,
                              PreferredRangeType Type = Smallest) const;

  /// Return the range that results from the union of this range
  /// with another range.  The resultant range is guaranteed to include the
  /// elements of both sets, but may contain more.  For example, [3, 9) union
  /// [12,15) is [3, 15), which includes 9, 10, and 11, which were not included
  /// in either set before.
  ConstantRange unionWith(const ConstantRange &CR,
                          PreferredRangeType Type = Smallest) const;

  /// Intersect the two ranges and return the result if it can be represented
  /// exactly, otherwise return std::nullopt.
  std::optional<ConstantRange>
  exactIntersectWith(const ConstantRange &CR) const;

  /// Union the two ranges and return the result if it can be represented
  /// exactly, otherwise return std::nullopt.
  std::optional<ConstantRange> exactUnionWith(const ConstantRange &CR) const;

  /// Return a new range in the specified integer type, which must
  /// be strictly larger than the current type.  The returned range will
  /// correspond to the possible range of values if the source range had been
  /// zero extended to BitWidth.
  ConstantRange zeroExtend(uint32_t BitWidth) const;

  /// Return a new range in the specified integer type, which must
  /// be strictly larger than the current type.  The returned range will
  /// correspond to the possible range of values if the source range had been
  /// sign extended to BitWidth.
  ConstantRange signExtend(uint32_t BitWidth) const;

  /// Return a new range in the specified integer type, which must be
  /// strictly smaller than the current type.  The returned range will
  /// correspond to the possible range of values if the source range had been
  /// truncated to the specified type with wrap type \p NoWrapKind.
  /// Note that the result of trunc nuw is exact.
  ConstantRange truncate(uint32_t BitWidth, unsigned NoWrapKind = 0) const;

  /// Return a new range representing the possible values resulting
  /// from an addition of a value in this range and a value in \p Other.
  ConstantRange add(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from an addition with wrap type \p NoWrapKind of a value in this
  /// range and a value in \p Other.
  /// If the result range is disjoint, the preferred range is determined by the
  /// \p PreferredRangeType.
  ConstantRange addWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                              PreferredRangeType RangeType = Smallest) const;

  /// Return a new range representing the possible values resulting
  /// from a subtraction of a value in this range and a value in \p Other.
  ConstantRange sub(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from an subtraction with wrap type \p NoWrapKind of a value in this
  /// range and a value in \p Other.
  /// If the result range is disjoint, the preferred range is determined by the
  /// \p PreferredRangeType.
  ConstantRange subWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                              PreferredRangeType RangeType = Smallest) const;

  /// Return a new range representing the possible values resulting
  /// from a multiplication of a value in this range and a value in \p Other,
  /// treating both this and \p Other as unsigned ranges.
  ConstantRange multiply(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a multiplication with wrap type \p NoWrapKind of a value in this
  /// range and a value in \p Other.
  /// If the result range is disjoint, the preferred range is determined by the
  /// \p PreferredRangeType.
  ConstantRange
  multiplyWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                     PreferredRangeType RangeType = Smallest) const;

  /// Return a new range representing the possible values resulting
  /// from an unsigned division of a value in this range and a value in
  /// \p Other.
  ConstantRange udiv(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a signed division of a value in this range and a value in
  /// \p Other. Division by zero and division of SignedMin by -1 are considered
  /// undefined behavior, in line with IR, and do not contribute towards the
  /// result.
  ConstantRange sdiv(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from an unsigned remainder operation of a value in this range and a
  /// value in \p Other.
  ConstantRange urem(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a signed remainder operation of a value in this range and a
  /// value in \p Other.
  ConstantRange srem(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting from
  /// a binary-xor of a value in this range by an all-one value,
  /// aka bitwise complement operation.
  ConstantRange binaryNot() const;

  /// Return a new range representing the possible values resulting
  /// from a binary-and of a value in this range by a value in \p Other.
  ConstantRange binaryAnd(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a binary-or of a value in this range by a value in \p Other.
  ConstantRange binaryOr(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a binary-xor of a value in this range by a value in \p Other.
  ConstantRange binaryXor(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a left shift of a value in this range by a value in \p Other.
  /// TODO: This isn't fully implemented yet.
  ConstantRange shl(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting
  /// from a left shift with wrap type \p NoWrapKind of a value in this
  /// range and a value in \p Other.
  /// If the result range is disjoint, the preferred range is determined by the
  /// \p PreferredRangeType.
  ConstantRange shlWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                              PreferredRangeType RangeType = Smallest) const;

  /// Return a new range representing the possible values resulting from a
  /// logical right shift of a value in this range and a value in \p Other.
  ConstantRange lshr(const ConstantRange &Other) const;

  /// Return a new range representing the possible values resulting from a
  /// arithmetic right shift of a value in this range and a value in \p Other.
  ConstantRange ashr(const ConstantRange &Other) const;

  /// Perform an unsigned saturating addition of two constant ranges.
  ConstantRange uadd_sat(const ConstantRange &Other) const;

  /// Perform a signed saturating addition of two constant ranges.
  ConstantRange sadd_sat(const ConstantRange &Other) const;

  /// Perform an unsigned saturating subtraction of two constant ranges.
  ConstantRange usub_sat(const ConstantRange &Other) const;

  /// Perform a signed saturating subtraction of two constant ranges.
  ConstantRange ssub_sat(const ConstantRange &Other) const;

  /// Perform an unsigned saturating multiplication of two constant ranges.
  ConstantRange umul_sat(const ConstantRange &Other) const;

  /// Perform a signed saturating multiplication of two constant ranges.
  ConstantRange smul_sat(const ConstantRange &Other) const;

  /// Perform an unsigned saturating left shift of this constant range by a
  /// value in \p Other.
  ConstantRange ushl_sat(const ConstantRange &Other) const;

  /// Perform a signed saturating left shift of this constant range by a
  /// value in \p Other.
  ConstantRange sshl_sat(const ConstantRange &Other) const;

  /// Return a new range that is the logical not of the current set.
  ConstantRange inverse() const;

  /// Calculate absolute value range. If the original range contains signed
  /// min, then the resulting range will contain signed min if and only if
  /// \p IntMinIsPoison is false.
  ConstantRange abs(bool IntMinIsPoison = false) const;

  /// Return known bits for values in this range.
  KnownBits toKnownBits() const;
};

/// Parse out a conservative ConstantRange from !range metadata.
///
/// E.g. if RangeMD is !{i32 0, i32 10, i32 15, i32 20} then return [0, 20).

inline ConstantRange::ConstantRange(uint32_t BitWidth, bool Full)
    : Lower(Full ? APInt::getMaxValue(BitWidth) : APInt::getMinValue(BitWidth)),
      Upper(Lower) {}

inline ConstantRange::ConstantRange(APInt V)
    : Lower(std::move(V)), Upper(Lower + 1) {}

inline ConstantRange::ConstantRange(APInt L, APInt U)
    : Lower(std::move(L)), Upper(std::move(U)) {
  assert(Lower.getBitWidth() == Upper.getBitWidth() &&
         "ConstantRange with unequal bit widths");
  assert((Lower != Upper || (Lower.isMaxValue() || Lower.isMinValue())) &&
         "Lower == Upper, but they aren't min or max value!");
}

inline ConstantRange ConstantRange::fromKnownBits(const KnownBits &Known,
                                                  bool IsSigned) {
  if (Known.hasConflict())
    return getEmpty(Known.getBitWidth());
  if (Known.isUnknown())
    return getFull(Known.getBitWidth());

  // For unsigned ranges, or signed ranges with known sign bit, create a simple
  // range between the smallest and largest possible value.
  if (!IsSigned || Known.isNegative() || Known.isNonNegative())
    return ConstantRange(Known.getMinValue(), Known.getMaxValue() + 1);

  // If we don't know the sign bit, pick the lower bound as a negative number
  // and the upper bound as a non-negative one.
  APInt Lower = Known.getMinValue(), Upper = Known.getMaxValue();
  Lower.setSignBit();
  Upper.clearSignBit();
  return ConstantRange(Lower, Upper + 1);
}

inline KnownBits ConstantRange::toKnownBits() const {
  // TODO: We could return conflicting known bits here, but consumers are
  // likely not prepared for that.
  if (isEmptySet())
    return KnownBits(getBitWidth());

  // We can only retain the top bits that are the same between min and max.
  APInt Min = getUnsignedMin();
  APInt Max = getUnsignedMax();
  KnownBits Known = KnownBits::makeConstant(Min);
  if (std::optional<unsigned> DifferentBit =
          APIntOps::GetMostSignificantDifferentBit(Min, Max)) {
    Known.Zero.clearLowBits(*DifferentBit + 1);
    Known.One.clearLowBits(*DifferentBit + 1);
  }
  return Known;
}

inline std::pair<ConstantRange, ConstantRange>
ConstantRange::splitPosNeg() const {
  uint32_t BW = getBitWidth();
  APInt Zero = APInt::getZero(BW), One = APInt(BW, 1);
  APInt SignedMin = APInt::getSignedMinValue(BW);
  // There are no positive 1-bit values. The 1 would get interpreted as -1.
  ConstantRange PosFilter =
      BW == 1 ? getEmpty() : ConstantRange(One, SignedMin);
  ConstantRange NegFilter(SignedMin, Zero);
  return {intersectWith(PosFilter), intersectWith(NegFilter)};
}

inline bool ConstantRange::isFullSet() const {
  return Lower == Upper && Lower.isMaxValue();
}

inline bool ConstantRange::isEmptySet() const {
  return Lower == Upper && Lower.isMinValue();
}

inline bool ConstantRange::isWrappedSet() const {
  return Lower.ugt(Upper) && !Upper.isZero();
}

inline bool ConstantRange::isUpperWrapped() const { return Lower.ugt(Upper); }

inline bool ConstantRange::isSignWrappedSet() const {
  return Lower.sgt(Upper) && !Upper.isMinSignedValue();
}

inline bool ConstantRange::isUpperSignWrapped() const {
  return Lower.sgt(Upper);
}

inline bool
ConstantRange::isSizeStrictlySmallerThan(const ConstantRange &Other) const {
  assert(getBitWidth() == Other.getBitWidth());
  if (isFullSet())
    return false;
  if (Other.isFullSet())
    return true;
  return (Upper - Lower).ult(Other.Upper - Other.Lower);
}

inline bool ConstantRange::isSizeLargerThan(uint64_t MaxSize) const {
  // If this a full set, we need special handling to avoid needing an extra bit
  // to represent the size.
  if (isFullSet())
    return MaxSize == 0 || APInt::getMaxValue(getBitWidth()).ugt(MaxSize - 1);

  return (Upper - Lower).ugt(MaxSize);
}

inline bool ConstantRange::isAllNegative() const {
  // Empty set is all negative, full set is not.
  if (isEmptySet())
    return true;
  if (isFullSet())
    return false;

  return !isUpperSignWrapped() && !Upper.isStrictlyPositive();
}

inline bool ConstantRange::isAllNonNegative() const {
  // Empty and full set are automatically treated correctly.
  return !isSignWrappedSet() && Lower.isNonNegative();
}

inline bool ConstantRange::isAllPositive() const {
  // Empty set is all positive, full set is not.
  if (isEmptySet())
    return true;
  if (isFullSet())
    return false;

  return !isSignWrappedSet() && Lower.isStrictlyPositive();
}

inline APInt ConstantRange::getUnsignedMax() const {
  if (isFullSet() || isUpperWrapped())
    return APInt::getMaxValue(getBitWidth());
  return getUpper() - 1;
}

inline APInt ConstantRange::getUnsignedMin() const {
  if (isFullSet() || isWrappedSet())
    return APInt::getMinValue(getBitWidth());
  return getLower();
}

inline APInt ConstantRange::getSignedMax() const {
  if (isFullSet() || isUpperSignWrapped())
    return APInt::getSignedMaxValue(getBitWidth());
  return getUpper() - 1;
}

inline APInt ConstantRange::getSignedMin() const {
  if (isFullSet() || isSignWrappedSet())
    return APInt::getSignedMinValue(getBitWidth());
  return getLower();
}

inline bool ConstantRange::contains(const APInt &V) const {
  if (Lower == Upper)
    return isFullSet();

  if (!isUpperWrapped())
    return Lower.ule(V) && V.ult(Upper);
  return Lower.ule(V) || V.ult(Upper);
}

inline bool ConstantRange::contains(const ConstantRange &Other) const {
  if (isFullSet() || Other.isEmptySet())
    return true;
  if (isEmptySet() || Other.isFullSet())
    return false;

  if (!isUpperWrapped()) {
    if (Other.isUpperWrapped())
      return false;

    return Lower.ule(Other.getLower()) && Other.getUpper().ule(Upper);
  }

  if (!Other.isUpperWrapped())
    return Other.getUpper().ule(Upper) || Lower.ule(Other.getLower());

  return Other.getUpper().ule(Upper) && Lower.ule(Other.getLower());
}

inline unsigned ConstantRange::getActiveBits() const {
  if (isEmptySet())
    return 0;

  return getUnsignedMax().getActiveBits();
}

inline unsigned ConstantRange::getMinSignedBits() const {
  if (isEmptySet())
    return 0;

  return std::max(getSignedMin().getSignificantBits(),
                  getSignedMax().getSignificantBits());
}

inline ConstantRange ConstantRange::subtract(const APInt &Val) const {
  assert(Val.getBitWidth() == getBitWidth() && "Wrong bit width");
  // If the set is empty or full, don't modify the endpoints.
  if (Lower == Upper)
    return *this;
  return ConstantRange(Lower - Val, Upper - Val);
}

inline ConstantRange ConstantRange::difference(const ConstantRange &CR) const {
  return intersectWith(CR.inverse());
}

static ConstantRange getPreferredRange(const ConstantRange &CR1,
                                       const ConstantRange &CR2,
                                       ConstantRange::PreferredRangeType Type) {
  if (Type == ConstantRange::Unsigned) {
    if (!CR1.isWrappedSet() && CR2.isWrappedSet())
      return CR1;
    if (CR1.isWrappedSet() && !CR2.isWrappedSet())
      return CR2;
  } else if (Type == ConstantRange::Signed) {
    if (!CR1.isSignWrappedSet() && CR2.isSignWrappedSet())
      return CR1;
    if (CR1.isSignWrappedSet() && !CR2.isSignWrappedSet())
      return CR2;
  }

  if (CR1.isSizeStrictlySmallerThan(CR2))
    return CR1;
  return CR2;
}

inline ConstantRange
ConstantRange::intersectWith(const ConstantRange &CR,
                             PreferredRangeType Type) const {
  assert(getBitWidth() == CR.getBitWidth() &&
         "ConstantRange types don't agree!");

  // Handle common cases.
  if (isEmptySet() || CR.isFullSet())
    return *this;
  if (CR.isEmptySet() || isFullSet())
    return CR;

  if (!isUpperWrapped() && CR.isUpperWrapped())
    return CR.intersectWith(*this, Type);

  if (!isUpperWrapped() && !CR.isUpperWrapped()) {
    if (Lower.ult(CR.Lower)) {
      // L---U       : this
      //       L---U : CR
      if (Upper.ule(CR.Lower))
        return getEmpty();

      // L---U       : this
      //   L---U     : CR
      if (Upper.ult(CR.Upper))
        return ConstantRange(CR.Lower, Upper);

      // L-------U   : this
      //   L---U     : CR
      return CR;
    }
    //   L---U     : this
    // L-------U   : CR
    if (Upper.ult(CR.Upper))
      return *this;

    //   L-----U   : this
    // L-----U     : CR
    if (Lower.ult(CR.Upper))
      return ConstantRange(Lower, CR.Upper);

    //       L---U : this
    // L---U       : CR
    return getEmpty();
  }

  if (isUpperWrapped() && !CR.isUpperWrapped()) {
    if (CR.Lower.ult(Upper)) {
      // ------U   L--- : this
      //  L--U          : CR
      if (CR.Upper.ult(Upper))
        return CR;

      // ------U   L--- : this
      //  L------U      : CR
      if (CR.Upper.ule(Lower))
        return ConstantRange(CR.Lower, Upper);

      // ------U   L--- : this
      //  L----------U  : CR
      return getPreferredRange(*this, CR, Type);
    }
    if (CR.Lower.ult(Lower)) {
      // --U      L---- : this
      //     L--U       : CR
      if (CR.Upper.ule(Lower))
        return getEmpty();

      // --U      L---- : this
      //     L------U   : CR
      return ConstantRange(Lower, CR.Upper);
    }

    // --U  L------ : this
    //        L--U  : CR
    return CR;
  }

  if (CR.Upper.ult(Upper)) {
    // ------U L-- : this
    // --U L------ : CR
    if (CR.Lower.ult(Upper))
      return getPreferredRange(*this, CR, Type);

    // ----U   L-- : this
    // --U   L---- : CR
    if (CR.Lower.ult(Lower))
      return ConstantRange(Lower, CR.Upper);

    // ----U L---- : this
    // --U     L-- : CR
    return CR;
  }
  if (CR.Upper.ule(Lower)) {
    // --U     L-- : this
    // ----U L---- : CR
    if (CR.Lower.ult(Lower))
      return *this;

    // --U   L---- : this
    // ----U   L-- : CR
    return ConstantRange(CR.Lower, Upper);
  }

  // --U L------ : this
  // ------U L-- : CR
  return getPreferredRange(*this, CR, Type);
}

inline ConstantRange ConstantRange::unionWith(const ConstantRange &CR,
                                              PreferredRangeType Type) const {
  assert(getBitWidth() == CR.getBitWidth() &&
         "ConstantRange types don't agree!");

  if (isFullSet() || CR.isEmptySet())
    return *this;
  if (CR.isFullSet() || isEmptySet())
    return CR;

  if (!isUpperWrapped() && CR.isUpperWrapped())
    return CR.unionWith(*this, Type);

  if (!isUpperWrapped() && !CR.isUpperWrapped()) {
    //        L---U  and  L---U        : this
    //  L---U                   L---U  : CR
    // result in one of
    //  L---------U
    // -----U L-----
    if (CR.Upper.ult(Lower) || Upper.ult(CR.Lower))
      return getPreferredRange(ConstantRange(Lower, CR.Upper),
                               ConstantRange(CR.Lower, Upper), Type);

    APInt L = CR.Lower.ult(Lower) ? CR.Lower : Lower;
    APInt U = (CR.Upper - 1).ugt(Upper - 1) ? CR.Upper : Upper;

    if (L.isZero() && U.isZero())
      return getFull();

    return ConstantRange(std::move(L), std::move(U));
  }

  if (!CR.isUpperWrapped()) {
    // ------U   L-----  and  ------U   L----- : this
    //   L--U                            L--U  : CR
    if (CR.Upper.ule(Upper) || CR.Lower.uge(Lower))
      return *this;

    // ------U   L----- : this
    //    L---------U   : CR
    if (CR.Lower.ule(Upper) && Lower.ule(CR.Upper))
      return getFull();

    // ----U       L---- : this
    //       L---U       : CR
    // results in one of
    // ----------U L----
    // ----U L----------
    if (Upper.ult(CR.Lower) && CR.Upper.ult(Lower))
      return getPreferredRange(ConstantRange(Lower, CR.Upper),
                               ConstantRange(CR.Lower, Upper), Type);

    // ----U     L----- : this
    //        L----U    : CR
    if (Upper.ult(CR.Lower) && Lower.ule(CR.Upper))
      return ConstantRange(CR.Lower, Upper);

    // ------U    L---- : this
    //    L-----U       : CR
    assert(CR.Lower.ule(Upper) && CR.Upper.ult(Lower) &&
           "ConstantRange::unionWith missed a case with one range wrapped");
    return ConstantRange(Lower, CR.Upper);
  }

  // ------U    L----  and  ------U    L---- : this
  // -U  L-----------  and  ------------U  L : CR
  if (CR.Lower.ule(Upper) || Lower.ule(CR.Upper))
    return getFull();

  APInt L = CR.Lower.ult(Lower) ? CR.Lower : Lower;
  APInt U = CR.Upper.ugt(Upper) ? CR.Upper : Upper;

  return ConstantRange(std::move(L), std::move(U));
}

inline std::optional<ConstantRange>
ConstantRange::exactIntersectWith(const ConstantRange &CR) const {
  // TODO: This can be implemented more efficiently.
  ConstantRange Result = intersectWith(CR);
  if (Result == inverse().unionWith(CR.inverse()).inverse())
    return Result;
  return std::nullopt;
}

inline std::optional<ConstantRange>
ConstantRange::exactUnionWith(const ConstantRange &CR) const {
  // TODO: This can be implemented more efficiently.
  ConstantRange Result = unionWith(CR);
  if (Result == inverse().intersectWith(CR.inverse()).inverse())
    return Result;
  return std::nullopt;
}

inline ConstantRange ConstantRange::zeroExtend(uint32_t DstTySize) const {
  if (isEmptySet())
    return getEmpty(DstTySize);

  unsigned SrcTySize = getBitWidth();
  if (DstTySize == SrcTySize)
    return *this;
  assert(SrcTySize < DstTySize && "Not a value extension");
  if (isFullSet() || isUpperWrapped()) {
    // Change into [0, 1 << src bit width)
    APInt LowerExt(DstTySize, 0);
    if (!Upper) // special case: [X, 0) -- not really wrapping around
      LowerExt = Lower.zext(DstTySize);
    return ConstantRange(std::move(LowerExt),
                         APInt::getOneBitSet(DstTySize, SrcTySize));
  }

  return ConstantRange(Lower.zext(DstTySize), Upper.zext(DstTySize));
}

inline ConstantRange ConstantRange::signExtend(uint32_t DstTySize) const {
  if (isEmptySet())
    return getEmpty(DstTySize);

  unsigned SrcTySize = getBitWidth();
  if (DstTySize == SrcTySize)
    return *this;
  assert(SrcTySize < DstTySize && "Not a value extension");

  // special case: [X, INT_MIN) -- not really wrapping around
  if (Upper.isMinSignedValue())
    return ConstantRange(Lower.sext(DstTySize), Upper.zext(DstTySize));

  if (isFullSet() || isSignWrappedSet()) {
    return ConstantRange(
        APInt::getHighBitsSet(DstTySize, DstTySize - SrcTySize + 1),
        APInt::getLowBitsSet(DstTySize, SrcTySize - 1) + 1);
  }

  return ConstantRange(Lower.sext(DstTySize), Upper.sext(DstTySize));
}

inline ConstantRange ConstantRange::truncate(uint32_t DstTySize,
                                             unsigned NoWrapKind) const {
  if (DstTySize == getBitWidth())
    return *this;
  assert(getBitWidth() > DstTySize && "Not a value truncation");
  if (isEmptySet())
    return getEmpty(DstTySize);
  if (isFullSet())
    return getFull(DstTySize);

  APInt LowerDiv(Lower), UpperDiv(Upper);
  ConstantRange Union(DstTySize, /*isFullSet=*/false);

  // Analyze wrapped sets in their two parts: [0, Upper) \/ [Lower, MaxValue]
  // We use the non-wrapped set code to analyze the [Lower, MaxValue) part, and
  // then we do the union with [MaxValue, Upper)
  if (isUpperWrapped()) {
    // If Upper is greater than MaxValue(DstTy), it covers the whole truncated
    // range.
    if (Upper.getActiveBits() > DstTySize)
      return getFull(DstTySize);

    // For nuw the two parts are: [0, Upper) \/ [Lower, MaxValue(DstTy)]
    if (NoWrapKind & OverflowingBinaryOperator::NoUnsignedWrap) {
      Union = ConstantRange(APInt::getZero(DstTySize), Upper.trunc(DstTySize));
      UpperDiv = APInt::getOneBitSet(getBitWidth(), DstTySize);
    } else {
      // If Upper is equal to MaxValue(DstTy), it covers the whole truncated
      // range.
      if (Upper.countr_one() == DstTySize)
        return getFull(DstTySize);
      Union =
          ConstantRange(APInt::getMaxValue(DstTySize), Upper.trunc(DstTySize));
      UpperDiv.setAllBits();
      // Union covers the MaxValue case, so return if the remaining range is
      // just MaxValue(DstTy).
      if (LowerDiv == UpperDiv)
        return Union;
    }
  }

  // Chop off the most significant bits that are past the destination bitwidth.
  if (LowerDiv.getActiveBits() > DstTySize) {
    // For trunc nuw if LowerDiv is greater than MaxValue(DstTy), the range is
    // outside the whole truncated range.
    if (NoWrapKind & OverflowingBinaryOperator::NoUnsignedWrap)
      return Union;
    // Mask to just the signficant bits and subtract from LowerDiv/UpperDiv.
    APInt Adjust = LowerDiv & APInt::getBitsSetFrom(getBitWidth(), DstTySize);
    LowerDiv -= Adjust;
    UpperDiv -= Adjust;
  }

  unsigned UpperDivWidth = UpperDiv.getActiveBits();
  if (UpperDivWidth <= DstTySize)
    return ConstantRange(LowerDiv.trunc(DstTySize), UpperDiv.trunc(DstTySize))
        .unionWith(Union);

  if (!LowerDiv.isZero() &&
      NoWrapKind & OverflowingBinaryOperator::NoUnsignedWrap)
    return ConstantRange(LowerDiv.trunc(DstTySize), APInt::getZero(DstTySize))
        .unionWith(Union);

  // The truncated value wraps around. Check if we can do better than fullset.
  if (UpperDivWidth == DstTySize + 1) {
    // Clear the MSB so that UpperDiv wraps around.
    UpperDiv.clearBit(DstTySize);
    if (UpperDiv.ult(LowerDiv))
      return ConstantRange(LowerDiv.trunc(DstTySize), UpperDiv.trunc(DstTySize))
          .unionWith(Union);
  }

  return getFull(DstTySize);
}

inline ConstantRange ConstantRange::add(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();
  if (isFullSet() || Other.isFullSet())
    return getFull();

  APInt NewLower = getLower() + Other.getLower();
  APInt NewUpper = getUpper() + Other.getUpper() - 1;
  if (NewLower == NewUpper)
    return getFull();

  ConstantRange X = ConstantRange(std::move(NewLower), std::move(NewUpper));
  if (X.isSizeStrictlySmallerThan(*this) || X.isSizeStrictlySmallerThan(Other))
    // We've wrapped, therefore, full set.
    return getFull();
  return X;
}

inline ConstantRange
ConstantRange::addWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                             PreferredRangeType RangeType) const {
  // Calculate the range for "X + Y" which is guaranteed not to wrap(overflow).
  // (X is from this, and Y is from Other)
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();
  if (isFullSet() && Other.isFullSet())
    return getFull();

  using OBO = OverflowingBinaryOperator;
  ConstantRange Result = add(Other);

  // If an overflow happens for every value pair in these two constant ranges,
  // we must return Empty set. In this case, we get that for free, because we
  // get lucky that intersection of add() with uadd_sat()/sadd_sat() results
  // in an empty set.

  if (NoWrapKind & OBO::NoSignedWrap)
    Result = Result.intersectWith(sadd_sat(Other), RangeType);

  if (NoWrapKind & OBO::NoUnsignedWrap)
    Result = Result.intersectWith(uadd_sat(Other), RangeType);

  return Result;
}

inline ConstantRange ConstantRange::sub(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();
  if (isFullSet() || Other.isFullSet())
    return getFull();

  APInt NewLower = getLower() - Other.getUpper() + 1;
  APInt NewUpper = getUpper() - Other.getLower();
  if (NewLower == NewUpper)
    return getFull();

  ConstantRange X = ConstantRange(std::move(NewLower), std::move(NewUpper));
  if (X.isSizeStrictlySmallerThan(*this) || X.isSizeStrictlySmallerThan(Other))
    // We've wrapped, therefore, full set.
    return getFull();
  return X;
}

inline ConstantRange
ConstantRange::subWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                             PreferredRangeType RangeType) const {
  // Calculate the range for "X - Y" which is guaranteed not to wrap(overflow).
  // (X is from this, and Y is from Other)
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();
  if (isFullSet() && Other.isFullSet())
    return getFull();

  using OBO = OverflowingBinaryOperator;
  ConstantRange Result = sub(Other);

  // If an overflow happens for every value pair in these two constant ranges,
  // we must return Empty set. In signed case, we get that for free, because we
  // get lucky that intersection of sub() with ssub_sat() results in an
  // empty set. But for unsigned we must perform the overflow check manually.

  if (NoWrapKind & OBO::NoSignedWrap)
    Result = Result.intersectWith(ssub_sat(Other), RangeType);

  if (NoWrapKind & OBO::NoUnsignedWrap) {
    if (getUnsignedMax().ult(Other.getUnsignedMin()))
      return getEmpty(); // Always overflows.
    Result = Result.intersectWith(usub_sat(Other), RangeType);
  }

  return Result;
}

inline ConstantRange ConstantRange::multiply(const ConstantRange &Other) const {
  // TODO: If either operand is a single element and the multiply is known to
  // be non-wrapping, round the result min and max value to the appropriate
  // multiple of that element. If wrapping is possible, at least adjust the
  // range according to the greatest power-of-two factor of the single element.

  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  if (const APInt *C = getSingleElement()) {
    if (C->isOne())
      return Other;
    if (C->isAllOnes())
      return ConstantRange(APInt::getZero(getBitWidth())).sub(Other);
  }

  if (const APInt *C = Other.getSingleElement()) {
    if (C->isOne())
      return *this;
    if (C->isAllOnes())
      return ConstantRange(APInt::getZero(getBitWidth())).sub(*this);
  }

  // Multiplication is signedness-independent. However different ranges can be
  // obtained depending on how the input ranges are treated. These different
  // ranges are all conservatively correct, but one might be better than the
  // other. We calculate two ranges; one treating the inputs as unsigned
  // and the other signed, then return the smallest of these ranges.

  // Unsigned range first.
  APInt this_min = getUnsignedMin().zext(getBitWidth() * 2);
  APInt this_max = getUnsignedMax().zext(getBitWidth() * 2);
  APInt Other_min = Other.getUnsignedMin().zext(getBitWidth() * 2);
  APInt Other_max = Other.getUnsignedMax().zext(getBitWidth() * 2);

  ConstantRange Result_zext =
      ConstantRange(this_min * Other_min, this_max * Other_max + 1);
  ConstantRange UR = Result_zext.truncate(getBitWidth());

  // If the unsigned range doesn't wrap, and isn't negative then it's a range
  // from one positive number to another which is as good as we can generate.
  // In this case, skip the extra work of generating signed ranges which aren't
  // going to be better than this range.
  if (!UR.isUpperWrapped() &&
      (UR.getUpper().isNonNegative() || UR.getUpper().isMinSignedValue()))
    return UR;

  // Now the signed range. Because we could be dealing with negative numbers
  // here, the lower bound is the smallest of the cartesian product of the
  // lower and upper ranges; for example:
  //   [-1,4) * [-2,3) = min(-1*-2, -1*2, 3*-2, 3*2) = -6.
  // Similarly for the upper bound, swapping min for max.

  this_min = getSignedMin().sext(getBitWidth() * 2);
  this_max = getSignedMax().sext(getBitWidth() * 2);
  Other_min = Other.getSignedMin().sext(getBitWidth() * 2);
  Other_max = Other.getSignedMax().sext(getBitWidth() * 2);

  auto L = {this_min * Other_min, this_min * Other_max, this_max * Other_min,
            this_max * Other_max};
  auto Compare = [](const APInt &A, const APInt &B) { return A.slt(B); };
  ConstantRange Result_sext(std::min(L, Compare), std::max(L, Compare) + 1);
  ConstantRange SR = Result_sext.truncate(getBitWidth());

  return UR.isSizeStrictlySmallerThan(SR) ? UR : SR;
}

inline ConstantRange
ConstantRange::multiplyWithNoWrap(const ConstantRange &Other,
                                  unsigned NoWrapKind,
                                  PreferredRangeType RangeType) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();
  if (isFullSet() && Other.isFullSet())
    return getFull();

  ConstantRange Result = multiply(Other);

  if (NoWrapKind & OverflowingBinaryOperator::NoSignedWrap)
    Result = Result.intersectWith(smul_sat(Other), RangeType);

  if (NoWrapKind & OverflowingBinaryOperator::NoUnsignedWrap)
    Result = Result.intersectWith(umul_sat(Other), RangeType);

  // mul nsw nuw X, Y s>= 0 if X s> 1 or Y s> 1
  if ((NoWrapKind == (OverflowingBinaryOperator::NoSignedWrap |
                      OverflowingBinaryOperator::NoUnsignedWrap)) &&
      !Result.isAllNonNegative()) {
    if (getSignedMin().sgt(1) || Other.getSignedMin().sgt(1))
      Result = Result.intersectWith(
          getNonEmpty(APInt::getZero(getBitWidth()),
                      APInt::getSignedMinValue(getBitWidth())),
          RangeType);
  }

  return Result;
}

inline ConstantRange ConstantRange::udiv(const ConstantRange &RHS) const {
  if (isEmptySet() || RHS.isEmptySet() || RHS.getUnsignedMax().isZero())
    return getEmpty();

  APInt LowerVal = getUnsignedMin().udiv(RHS.getUnsignedMax());

  APInt RHS_umin = RHS.getUnsignedMin();
  if (RHS_umin.isZero()) {
    // We want the lowest value in RHS excluding zero. Usually that would be 1
    // except for a range in the form of [X, 1) in which case it would be X.
    if (RHS.getUpper() == 1)
      RHS_umin = RHS.getLower();
    else
      RHS_umin = 1;
  }

  APInt UpperVal = getUnsignedMax().udiv(RHS_umin) + 1;
  return getNonEmpty(std::move(LowerVal), std::move(UpperVal));
}

inline ConstantRange ConstantRange::sdiv(const ConstantRange &RHS) const {
  APInt Zero = APInt::getZero(getBitWidth());
  APInt SignedMin = APInt::getSignedMinValue(getBitWidth());

  // We split up the LHS and RHS into positive and negative components
  // and then also compute the positive and negative components of the result
  // separately by combining division results with the appropriate signs.
  auto [PosL, NegL] = splitPosNeg();
  auto [PosR, NegR] = RHS.splitPosNeg();

  ConstantRange PosRes = getEmpty();
  if (!PosL.isEmptySet() && !PosR.isEmptySet())
    // pos / pos = pos.
    PosRes = ConstantRange(PosL.Lower.sdiv(PosR.Upper - 1),
                           (PosL.Upper - 1).sdiv(PosR.Lower) + 1);

  if (!NegL.isEmptySet() && !NegR.isEmptySet()) {
    // neg / neg = pos.
    //
    // We need to deal with one tricky case here: SignedMin / -1 is UB on the
    // IR level, so we'll want to exclude this case when calculating bounds.
    // (For APInts the operation is well-defined and yields SignedMin.) We
    // handle this by dropping either SignedMin from the LHS or -1 from the RHS.
    APInt Lo = (NegL.Upper - 1).sdiv(NegR.Lower);
    if (NegL.Lower.isMinSignedValue() && NegR.Upper.isZero()) {
      // Remove -1 from the LHS. Skip if it's the only element, as this would
      // leave us with an empty set.
      if (!NegR.Lower.isAllOnes()) {
        APInt AdjNegRUpper;
        if (RHS.Lower.isAllOnes())
          // Negative part of [-1, X] without -1 is [SignedMin, X].
          AdjNegRUpper = RHS.Upper;
        else
          // [X, -1] without -1 is [X, -2].
          AdjNegRUpper = NegR.Upper - 1;

        PosRes = PosRes.unionWith(
            ConstantRange(Lo, NegL.Lower.sdiv(AdjNegRUpper - 1) + 1));
      }

      // Remove SignedMin from the RHS. Skip if it's the only element, as this
      // would leave us with an empty set.
      if (NegL.Upper != SignedMin + 1) {
        APInt AdjNegLLower;
        if (Upper == SignedMin + 1)
          // Negative part of [X, SignedMin] without SignedMin is [X, -1].
          AdjNegLLower = Lower;
        else
          // [SignedMin, X] without SignedMin is [SignedMin + 1, X].
          AdjNegLLower = NegL.Lower + 1;

        PosRes = PosRes.unionWith(ConstantRange(
            std::move(Lo), AdjNegLLower.sdiv(NegR.Upper - 1) + 1));
      }
    } else {
      PosRes = PosRes.unionWith(
          ConstantRange(std::move(Lo), NegL.Lower.sdiv(NegR.Upper - 1) + 1));
    }
  }

  ConstantRange NegRes = getEmpty();
  if (!PosL.isEmptySet() && !NegR.isEmptySet())
    // pos / neg = neg.
    NegRes = ConstantRange((PosL.Upper - 1).sdiv(NegR.Upper - 1),
                           PosL.Lower.sdiv(NegR.Lower) + 1);

  if (!NegL.isEmptySet() && !PosR.isEmptySet())
    // neg / pos = neg.
    NegRes = NegRes.unionWith(
        ConstantRange(NegL.Lower.sdiv(PosR.Lower),
                      (NegL.Upper - 1).sdiv(PosR.Upper - 1) + 1));

  // Prefer a non-wrapping signed range here.
  ConstantRange Res = NegRes.unionWith(PosRes, PreferredRangeType::Signed);

  // Preserve the zero that we dropped when splitting the LHS by sign.
  if (contains(Zero) && (!PosR.isEmptySet() || !NegR.isEmptySet()))
    Res = Res.unionWith(ConstantRange(Zero));
  return Res;
}

inline ConstantRange ConstantRange::urem(const ConstantRange &RHS) const {
  if (isEmptySet() || RHS.isEmptySet() || RHS.getUnsignedMax().isZero())
    return getEmpty();

  if (const APInt *RHSInt = RHS.getSingleElement()) {
    // UREM by null is UB.
    if (RHSInt->isZero())
      return getEmpty();
    // Use APInt's implementation of UREM for single element ranges.
    if (const APInt *LHSInt = getSingleElement())
      return {LHSInt->urem(*RHSInt)};
  }

  // L % R for L < R is L.
  if (getUnsignedMax().ult(RHS.getUnsignedMin()))
    return *this;

  // L % R is <= L and < R.
  APInt UpperVal =
      APIntOps::umin(getUnsignedMax(), RHS.getUnsignedMax() - 1) + 1;
  return getNonEmpty(APInt::getZero(getBitWidth()), std::move(UpperVal));
}

inline ConstantRange ConstantRange::srem(const ConstantRange &RHS) const {
  if (isEmptySet() || RHS.isEmptySet())
    return getEmpty();

  if (const APInt *RHSInt = RHS.getSingleElement()) {
    // SREM by null is UB.
    if (RHSInt->isZero())
      return getEmpty();
    // Use APInt's implementation of SREM for single element ranges.
    if (const APInt *LHSInt = getSingleElement())
      return {LHSInt->srem(*RHSInt)};
  }

  ConstantRange AbsRHS = RHS.abs();
  APInt MinAbsRHS = AbsRHS.getUnsignedMin();
  APInt MaxAbsRHS = AbsRHS.getUnsignedMax();

  // Modulus by zero is UB.
  if (MaxAbsRHS.isZero())
    return getEmpty();

  if (MinAbsRHS.isZero())
    ++MinAbsRHS;

  APInt MinLHS = getSignedMin(), MaxLHS = getSignedMax();

  if (MinLHS.isNonNegative()) {
    // L % R for L < R is L.
    if (MaxLHS.ult(MinAbsRHS))
      return *this;

    // L % R is <= L and < R.
    APInt UpperVal = APIntOps::umin(MaxLHS, MaxAbsRHS - 1) + 1;
    return ConstantRange(APInt::getZero(getBitWidth()), std::move(UpperVal));
  }

  // Same basic logic as above, but the result is negative.
  if (MaxLHS.isNegative()) {
    if (MinLHS.ugt(-MinAbsRHS))
      return *this;

    APInt LowerVal = APIntOps::umax(MinLHS, -MaxAbsRHS + 1);
    return ConstantRange(std::move(LowerVal), APInt(getBitWidth(), 1));
  }

  // LHS range crosses zero.
  APInt LowerVal = APIntOps::umax(MinLHS, -MaxAbsRHS + 1);
  APInt UpperVal = APIntOps::umin(MaxLHS, MaxAbsRHS - 1) + 1;
  return ConstantRange(std::move(LowerVal), std::move(UpperVal));
}

inline ConstantRange ConstantRange::binaryNot() const {
  return ConstantRange(APInt::getAllOnes(getBitWidth())).sub(*this);
}

/// Estimate the 'bit-masked AND' operation's lower bound.
///
/// E.g., given two ranges as follows (single quotes are separators and
/// have no meaning here),
///
///   LHS = [10'00101'1,  ; LLo
///          10'10000'0]  ; LHi
///   RHS = [10'11111'0,  ; RLo
///          10'11111'1]  ; RHi
///
/// we know that the higher 2 bits of the result is always 10; and we also
/// notice that RHS[1:6] are always 1, so the result[1:6] cannot be less than
/// LHS[1:6] (i.e., 00101). Thus, the lower bound is 10'00101'0.
///
/// The algorithm is as follows,
/// 1. we first calculate a mask to find the higher common bits by
///       Mask = ~((LLo ^ LHi) | (RLo ^ RHi) | (LLo ^ RLo));
///       Mask = clear all non-leading-ones bits in Mask;
///    in the example, the Mask is set to 11'00000'0;
/// 2. calculate a new mask by setting all common leading bits to 1 in RHS, and
///    keeping the longest leading ones (i.e., 11'11111'0 in the example);
/// 3. return (LLo & new mask) as the lower bound;
/// 4. repeat the step 2 and 3 with LHS and RHS swapped, and update the lower
///    bound with the larger one.
static APInt estimateBitMaskedAndLowerBound(const ConstantRange &LHS,
                                            const ConstantRange &RHS) {
  auto BitWidth = LHS.getBitWidth();
  // If either is full set or unsigned wrapped, then the range must contain '0'
  // which leads the lower bound to 0.
  if ((LHS.isFullSet() || RHS.isFullSet()) ||
      (LHS.isWrappedSet() || RHS.isWrappedSet()))
    return APInt::getZero(BitWidth);

  auto LLo = LHS.getLower();
  auto LHi = LHS.getUpper() - 1;
  auto RLo = RHS.getLower();
  auto RHi = RHS.getUpper() - 1;

  // Calculate the mask for the higher common bits.
  auto Mask = ~((LLo ^ LHi) | (RLo ^ RHi) | (LLo ^ RLo));
  unsigned LeadingOnes = Mask.countLeadingOnes();
  Mask.clearLowBits(BitWidth - LeadingOnes);

  auto estimateBound = [BitWidth, &Mask](APInt ALo, const APInt &BLo,
                                         const APInt &BHi) {
    unsigned LeadingOnes = ((BLo & BHi) | Mask).countLeadingOnes();
    unsigned StartBit = BitWidth - LeadingOnes;
    ALo.clearLowBits(StartBit);
    return ALo;
  };

  auto LowerBoundByLHS = estimateBound(LLo, RLo, RHi);
  auto LowerBoundByRHS = estimateBound(RLo, LLo, LHi);

  return APIntOps::umax(LowerBoundByLHS, LowerBoundByRHS);
}

inline ConstantRange
ConstantRange::binaryAnd(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  ConstantRange KnownBitsRange =
      fromKnownBits(toKnownBits() & Other.toKnownBits(), false);
  auto LowerBound = estimateBitMaskedAndLowerBound(*this, Other);
  ConstantRange UMinUMaxRange = getNonEmpty(
      LowerBound, APIntOps::umin(Other.getUnsignedMax(), getUnsignedMax()) + 1);
  return KnownBitsRange.intersectWith(UMinUMaxRange);
}

inline ConstantRange ConstantRange::binaryOr(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  ConstantRange KnownBitsRange =
      fromKnownBits(toKnownBits() | Other.toKnownBits(), false);

  //      ~a & ~b    >= x
  // <=>  ~(~a & ~b) <= ~x
  // <=>  a | b      <= ~x
  // <=>  a | b      <  ~x + 1 = -x
  // thus, UpperBound(a | b) == -LowerBound(~a & ~b)
  auto UpperBound =
      -estimateBitMaskedAndLowerBound(binaryNot(), Other.binaryNot());
  // Upper wrapped range.
  ConstantRange UMaxUMinRange = getNonEmpty(
      APIntOps::umax(getUnsignedMin(), Other.getUnsignedMin()), UpperBound);
  return KnownBitsRange.intersectWith(UMaxUMinRange);
}

inline ConstantRange
ConstantRange::binaryXor(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  // Use APInt's implementation of XOR for single element ranges.
  if (isSingleElement() && Other.isSingleElement())
    return {*getSingleElement() ^ *Other.getSingleElement()};

  // Special-case binary complement, since we can give a precise answer.
  if (Other.isSingleElement() && Other.getSingleElement()->isAllOnes())
    return binaryNot();
  if (isSingleElement() && getSingleElement()->isAllOnes())
    return Other.binaryNot();

  KnownBits LHSKnown = toKnownBits();
  KnownBits RHSKnown = Other.toKnownBits();
  KnownBits Known = LHSKnown ^ RHSKnown;
  ConstantRange CR = fromKnownBits(Known, /*IsSigned*/ false);
  // Typically the following code doesn't improve the result if BW = 1.
  if (getBitWidth() == 1)
    return CR;

  // If LHS is known to be the subset of RHS, treat LHS ^ RHS as RHS -nuw/nsw
  // LHS. If RHS is known to be the subset of LHS, treat LHS ^ RHS as LHS
  // -nuw/nsw RHS.
  if ((~LHSKnown.Zero).isSubsetOf(RHSKnown.One))
    CR = CR.intersectWith(Other.sub(*this), PreferredRangeType::Unsigned);
  else if ((~RHSKnown.Zero).isSubsetOf(LHSKnown.One))
    CR = CR.intersectWith(this->sub(Other), PreferredRangeType::Unsigned);
  return CR;
}

inline ConstantRange ConstantRange::shl(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt Min = getUnsignedMin();
  APInt Max = getUnsignedMax();
  if (const APInt *RHS = Other.getSingleElement()) {
    unsigned BW = getBitWidth();
    if (RHS->uge(BW))
      return getEmpty();

    unsigned EqualLeadingBits = (Min ^ Max).countl_zero();
    if (RHS->ule(EqualLeadingBits))
      return getNonEmpty(Min << *RHS, (Max << *RHS) + 1);

    return getNonEmpty(
        APInt::getZero(BW),
        APInt::getBitsSetFrom(BW, static_cast<unsigned>(RHS->getZExtValue())) +
            1);
  }

  APInt OtherMax = Other.getUnsignedMax();
  if (isAllNegative() && OtherMax.ule(Min.countl_one())) {
    // For negative numbers, if the shift does not overflow in a signed sense,
    // a larger shift will make the number smaller.
    Max <<= Other.getUnsignedMin();
    Min <<= OtherMax;
    return ConstantRange::getNonEmpty(std::move(Min), std::move(Max) + 1);
  }

  // There's overflow!
  if (OtherMax.ugt(Max.countl_zero()))
    return getFull();

  // FIXME: implement the other tricky cases

  Min <<= Other.getUnsignedMin();
  Max <<= OtherMax;

  return ConstantRange::getNonEmpty(std::move(Min), std::move(Max) + 1);
}

static ConstantRange computeShlNUW(const ConstantRange &LHS,
                                   const ConstantRange &RHS) {
  unsigned BitWidth = LHS.getBitWidth();
  bool Overflow;
  APInt LHSMin = LHS.getUnsignedMin();
  unsigned RHSMin =
      static_cast<unsigned>(RHS.getUnsignedMin().getLimitedValue(BitWidth));
  APInt MinShl = LHSMin.ushl_ov(RHSMin, Overflow);
  if (Overflow)
    return ConstantRange::getEmpty(BitWidth);
  APInt LHSMax = LHS.getUnsignedMax();
  unsigned RHSMax =
      static_cast<unsigned>(RHS.getUnsignedMax().getLimitedValue(BitWidth));
  APInt MaxShl = MinShl;
  unsigned MaxShAmt = LHSMax.countLeadingZeros();
  if (RHSMin <= MaxShAmt)
    MaxShl = LHSMax << std::min(RHSMax, MaxShAmt);
  RHSMin = std::max(RHSMin, MaxShAmt + 1);
  RHSMax = std::min(RHSMax, LHSMin.countLeadingZeros());
  if (RHSMin <= RHSMax)
    MaxShl = APIntOps::umax(MaxShl,
                            APInt::getHighBitsSet(BitWidth, BitWidth - RHSMin));
  return ConstantRange::getNonEmpty(MinShl, MaxShl + 1);
}

static ConstantRange computeShlNSWWithNNegLHS(const APInt &LHSMin,
                                              const APInt &LHSMax,
                                              unsigned RHSMin,
                                              unsigned RHSMax) {
  unsigned BitWidth = LHSMin.getBitWidth();
  bool Overflow;
  APInt MinShl = LHSMin.sshl_ov(RHSMin, Overflow);
  if (Overflow)
    return ConstantRange::getEmpty(BitWidth);
  APInt MaxShl = MinShl;
  unsigned MaxShAmt = LHSMax.countLeadingZeros() - 1;
  if (RHSMin <= MaxShAmt)
    MaxShl = LHSMax << std::min(RHSMax, MaxShAmt);
  RHSMin = std::max(RHSMin, MaxShAmt + 1);
  RHSMax = std::min(RHSMax, LHSMin.countLeadingZeros() - 1);
  if (RHSMin <= RHSMax)
    MaxShl = APIntOps::umax(MaxShl,
                            APInt::getBitsSet(BitWidth, RHSMin, BitWidth - 1));
  return ConstantRange::getNonEmpty(MinShl, MaxShl + 1);
}

static ConstantRange computeShlNSWWithNegLHS(const APInt &LHSMin,
                                             const APInt &LHSMax,
                                             unsigned RHSMin, unsigned RHSMax) {
  unsigned BitWidth = LHSMin.getBitWidth();
  bool Overflow;
  APInt MaxShl = LHSMax.sshl_ov(RHSMin, Overflow);
  if (Overflow)
    return ConstantRange::getEmpty(BitWidth);
  APInt MinShl = MaxShl;
  unsigned MaxShAmt = LHSMin.countLeadingOnes() - 1;
  if (RHSMin <= MaxShAmt)
    MinShl = LHSMin.shl(std::min(RHSMax, MaxShAmt));
  RHSMin = std::max(RHSMin, MaxShAmt + 1);
  RHSMax = std::min(RHSMax, LHSMax.countLeadingOnes() - 1);
  if (RHSMin <= RHSMax)
    MinShl = APInt::getSignMask(BitWidth);
  return ConstantRange::getNonEmpty(MinShl, MaxShl + 1);
}

static ConstantRange computeShlNSW(const ConstantRange &LHS,
                                   const ConstantRange &RHS) {
  unsigned BitWidth = LHS.getBitWidth();
  unsigned RHSMin =
      static_cast<unsigned>(RHS.getUnsignedMin().getLimitedValue(BitWidth));
  unsigned RHSMax =
      static_cast<unsigned>(RHS.getUnsignedMax().getLimitedValue(BitWidth));
  APInt LHSMin = LHS.getSignedMin();
  APInt LHSMax = LHS.getSignedMax();
  if (LHSMin.isNonNegative())
    return computeShlNSWWithNNegLHS(LHSMin, LHSMax, RHSMin, RHSMax);
  else if (LHSMax.isNegative())
    return computeShlNSWWithNegLHS(LHSMin, LHSMax, RHSMin, RHSMax);
  return computeShlNSWWithNNegLHS(APInt::getZero(BitWidth), LHSMax, RHSMin,
                                  RHSMax)
      .unionWith(computeShlNSWWithNegLHS(LHSMin, APInt::getAllOnes(BitWidth),
                                         RHSMin, RHSMax),
                 ConstantRange::Signed);
}

inline ConstantRange
ConstantRange::shlWithNoWrap(const ConstantRange &Other, unsigned NoWrapKind,
                             PreferredRangeType RangeType) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  switch (NoWrapKind) {
  case 0:
    return shl(Other);
  case OverflowingBinaryOperator::NoSignedWrap:
    return computeShlNSW(*this, Other);
  case OverflowingBinaryOperator::NoUnsignedWrap:
    return computeShlNUW(*this, Other);
  case OverflowingBinaryOperator::NoSignedWrap |
      OverflowingBinaryOperator::NoUnsignedWrap:
    return computeShlNSW(*this, Other)
        .intersectWith(computeShlNUW(*this, Other), RangeType);
  default:
    std::abort();
  }
}

inline ConstantRange ConstantRange::lshr(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt max = getUnsignedMax().lshr(Other.getUnsignedMin()) + 1;
  APInt min = getUnsignedMin().lshr(Other.getUnsignedMax());
  return getNonEmpty(std::move(min), std::move(max));
}

inline ConstantRange ConstantRange::ashr(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  // May straddle zero, so handle both positive and negative cases.
  // 'PosMax' is the upper bound of the result of the ashr
  // operation, when Upper of the LHS of ashr is a non-negative.
  // number. Since ashr of a non-negative number will result in a
  // smaller number, the Upper value of LHS is shifted right with
  // the minimum value of 'Other' instead of the maximum value.
  APInt PosMax = getSignedMax().ashr(Other.getUnsignedMin()) + 1;

  // 'PosMin' is the lower bound of the result of the ashr
  // operation, when Lower of the LHS is a non-negative number.
  // Since ashr of a non-negative number will result in a smaller
  // number, the Lower value of LHS is shifted right with the
  // maximum value of 'Other'.
  APInt PosMin = getSignedMin().ashr(Other.getUnsignedMax());

  // 'NegMax' is the upper bound of the result of the ashr
  // operation, when Upper of the LHS of ashr is a negative number.
  // Since 'ashr' of a negative number will result in a bigger
  // number, the Upper value of LHS is shifted right with the
  // maximum value of 'Other'.
  APInt NegMax = getSignedMax().ashr(Other.getUnsignedMax()) + 1;

  // 'NegMin' is the lower bound of the result of the ashr
  // operation, when Lower of the LHS of ashr is a negative number.
  // Since 'ashr' of a negative number will result in a bigger
  // number, the Lower value of LHS is shifted right with the
  // minimum value of 'Other'.
  APInt NegMin = getSignedMin().ashr(Other.getUnsignedMin());

  APInt max, min;
  if (getSignedMin().isNonNegative()) {
    // Upper and Lower of LHS are non-negative.
    min = PosMin;
    max = PosMax;
  } else if (getSignedMax().isNegative()) {
    // Upper and Lower of LHS are negative.
    min = NegMin;
    max = NegMax;
  } else {
    // Upper is non-negative and Lower is negative.
    min = NegMin;
    max = PosMax;
  }
  return getNonEmpty(std::move(min), std::move(max));
}

inline ConstantRange ConstantRange::uadd_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt NewL = getUnsignedMin().uadd_sat(Other.getUnsignedMin());
  APInt NewU = getUnsignedMax().uadd_sat(Other.getUnsignedMax()) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::sadd_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt NewL = getSignedMin().sadd_sat(Other.getSignedMin());
  APInt NewU = getSignedMax().sadd_sat(Other.getSignedMax()) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::usub_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt NewL = getUnsignedMin().usub_sat(Other.getUnsignedMax());
  APInt NewU = getUnsignedMax().usub_sat(Other.getUnsignedMin()) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::ssub_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt NewL = getSignedMin().ssub_sat(Other.getSignedMax());
  APInt NewU = getSignedMax().ssub_sat(Other.getSignedMin()) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::umul_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt NewL = getUnsignedMin().umul_sat(Other.getUnsignedMin());
  APInt NewU = getUnsignedMax().umul_sat(Other.getUnsignedMax()) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::smul_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  // Because we could be dealing with negative numbers here, the lower bound is
  // the smallest of the cartesian product of the lower and upper ranges;
  // for example:
  //   [-1,4) * [-2,3) = min(-1*-2, -1*2, 3*-2, 3*2) = -6.
  // Similarly for the upper bound, swapping min for max.

  APInt Min = getSignedMin();
  APInt Max = getSignedMax();
  APInt OtherMin = Other.getSignedMin();
  APInt OtherMax = Other.getSignedMax();

  auto L = {Min.smul_sat(OtherMin), Min.smul_sat(OtherMax),
            Max.smul_sat(OtherMin), Max.smul_sat(OtherMax)};
  auto Compare = [](const APInt &A, const APInt &B) { return A.slt(B); };
  return getNonEmpty(std::min(L, Compare), std::max(L, Compare) + 1);
}

inline ConstantRange ConstantRange::ushl_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt NewL = getUnsignedMin().ushl_sat(Other.getUnsignedMin());
  APInt NewU = getUnsignedMax().ushl_sat(Other.getUnsignedMax()) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::sshl_sat(const ConstantRange &Other) const {
  if (isEmptySet() || Other.isEmptySet())
    return getEmpty();

  APInt Min = getSignedMin(), Max = getSignedMax();
  APInt ShAmtMin = Other.getUnsignedMin(), ShAmtMax = Other.getUnsignedMax();
  APInt NewL = Min.sshl_sat(Min.isNonNegative() ? ShAmtMin : ShAmtMax);
  APInt NewU = Max.sshl_sat(Max.isNegative() ? ShAmtMin : ShAmtMax) + 1;
  return getNonEmpty(std::move(NewL), std::move(NewU));
}

inline ConstantRange ConstantRange::inverse() const {
  if (isFullSet())
    return getEmpty();
  if (isEmptySet())
    return getFull();
  return ConstantRange(Upper, Lower);
}

inline ConstantRange ConstantRange::abs(bool IntMinIsPoison) const {
  if (isEmptySet())
    return getEmpty();

  if (isSignWrappedSet()) {
    APInt Lo;
    // Check whether the range crosses zero.
    if (Upper.isStrictlyPositive() || !Lower.isStrictlyPositive())
      Lo = APInt::getZero(getBitWidth());
    else
      Lo = APIntOps::umin(Lower, -Upper + 1);

    // If SignedMin is not poison, then it is included in the result range.
    if (IntMinIsPoison)
      return ConstantRange(Lo, APInt::getSignedMinValue(getBitWidth()));
    else
      return ConstantRange(Lo, APInt::getSignedMinValue(getBitWidth()) + 1);
  }

  APInt SMin = getSignedMin(), SMax = getSignedMax();

  // Skip SignedMin if it is poison.
  if (IntMinIsPoison && SMin.isMinSignedValue()) {
    // The range may become empty if it *only* contains SignedMin.
    if (SMax.isMinSignedValue())
      return getEmpty();
    ++SMin;
  }

  // All non-negative.
  if (SMin.isNonNegative())
    return ConstantRange(SMin, SMax + 1);

  // All negative.
  if (SMax.isNegative())
    return ConstantRange(-SMax, -SMin + 1);

  // Range crosses zero.
  return ConstantRange::getNonEmpty(APInt::getZero(getBitWidth()),
                                    APIntOps::umax(-SMin, SMax) + 1);
}

} // end namespace llvm

#endif
