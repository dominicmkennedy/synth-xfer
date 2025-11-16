#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <ostream>
#include <random>
#include <vector>

#include "apint.hpp"
#include "domain.hpp"

using namespace DomainHelpers;

template <std::size_t BW> class ConstRange {
public:
  using BV = APInt<BW>;
  static constexpr std::size_t arity = 2;
  static constexpr std::string name = "ConstRange";

  // ctor
  constexpr ConstRange(const std::array<BV, arity> &x) : v{x} {}

  constexpr const BV &operator[](std::size_t i) const noexcept { return v[i]; }

  friend std::ostream &operator<<(std::ostream &os, const ConstRange &x) {
    if (x.isBottom()) {
      return os << "(bottom)\n";
    }

    os << '[' << x.lower().getZExtValue() << ", " << x.upper().getZExtValue()
       << ']';

    if (isTop(x))
      os << " (top)";

    return os << "\n";
  }

  bool constexpr isBottom() const noexcept { return lower().ugt(upper()); }

  const constexpr ConstRange meet(const ConstRange &rhs) const noexcept {
    const APInt l = rhs.lower().ugt(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().ult(upper()) ? rhs.upper() : upper();
    if (l.ugt(u))
      return bottom();
    return ConstRange({std::move(l), std::move(u)});
  }

  const constexpr ConstRange join(const ConstRange &rhs) const noexcept {
    const APInt l = rhs.lower().ult(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().ugt(upper()) ? rhs.upper() : upper();
    return ConstRange({std::move(l), std::move(u)});
  }

  const constexpr std::vector<APInt<BW>> toConcrete() const noexcept {
    if (lower().ugt(upper()))
      return {};

    std::vector<APInt<BW>> res;
    for (APInt x = lower(); x.ule(upper()); x += 1) {
      res.push_back(x);

      if (x == APInt<BW>::getMaxValue())
        break;
    }

    return res;
  }

  constexpr std::uint64_t distance(const ConstRange &rhs) const noexcept {
    if (isBottom() && rhs.isBottom())
      return 0;

    if (isBottom())
      return APIntOps::abdu(rhs.lower(), rhs.upper()).getActiveBits();

    if (rhs.isBottom())
      return APIntOps::abdu(lower(), upper()).getActiveBits();

    const APInt ld = APIntOps::abdu(lower(), rhs.lower());
    const APInt ud = APIntOps::abdu(upper(), rhs.upper());
    return static_cast<unsigned long>((ld + ud).getActiveBits());
  }

  static constexpr const ConstRange fromConcrete(const APInt<BW> &x) noexcept {
    return ConstRange({x, x});
  }

  const APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<unsigned long> dist(lower().getZExtValue(),
                                                      upper().getZExtValue());
    return APInt<BW>(dist(rng));
  }

  static const ConstRange rand(std::mt19937 &rng) noexcept {
    std::uniform_int_distribution<unsigned long> dist(
        0, APInt<BW>::getAllOnes().getZExtValue());

    ConstRange cr({APInt<BW>(dist(rng)), APInt<BW>(dist(rng))});
    if (cr.isBottom()) {
      const APInt tmp = cr.v[0];
      cr.v[0] = cr.v[1];
      cr.v[1] = tmp;
    }

    return cr;
  }

  static constexpr const ConstRange bottom() noexcept {
    constexpr APInt min = APInt<BW>::getMinValue();
    constexpr APInt max = APInt<BW>::getMaxValue();
    return ConstRange({max, min});
  }

  static constexpr const ConstRange top() noexcept {
    constexpr APInt min = APInt<BW>::getMinValue();
    constexpr APInt max = APInt<BW>::getMaxValue();
    return ConstRange({min, max});
  }

  // TODO put a reserve call for the vector
  static constexpr std::vector<ConstRange> const enumLattice() noexcept {
    const unsigned int min =
        static_cast<unsigned int>(APInt<BW>::getMinValue().getZExtValue());
    const unsigned int max =
        static_cast<unsigned int>(APInt<BW>::getMaxValue().getZExtValue());
    APInt l = APInt<BW>(0);
    APInt u = APInt<BW>(0);
    std::vector<ConstRange> ret = {};

    for (unsigned int i = min; i <= max; ++i) {
      for (unsigned int j = i; j <= max; ++j) {
        l = i;
        u = j;
        ret.emplace_back(ConstRange({l, u}));
      }
    }

    return ret;
  }

  static constexpr double maxDist() noexcept { return BW; }

  // TODO make private?
  std::array<BV, arity> v{};

private:
  [[nodiscard]] constexpr const APInt<BW> lower() const noexcept {
    return v[0];
  }
  [[nodiscard]] constexpr const APInt<BW> upper() const noexcept {
    return v[1];
  }

  // Make public/require in the concept
  [[nodiscard]] constexpr bool isConstant() const noexcept {
    return lower() == upper();
  }

  [[nodiscard]] constexpr const APInt<BW> getConstant() const noexcept {
    assert(this.isConstant() && "Can't get constant if val is not const");
    return lower();
  }
};

static_assert(Domain<ConstRange, 4>);
static_assert(Domain<ConstRange, 8>);
static_assert(Domain<ConstRange, 16>);
static_assert(Domain<ConstRange, 32>);
static_assert(Domain<ConstRange, 64>);
