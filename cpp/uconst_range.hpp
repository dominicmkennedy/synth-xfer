#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <optional>
#include <ostream>
#include <random>
#include <string_view>
#include <vector>

#include "apint.hpp"
#include "domain.hpp"

using namespace DomainHelpers;

template <std::size_t BW> class UConstRange {
public:
  using BV = APInt<BW>;
  static constexpr std::size_t arity = 2;
  static constexpr std::string_view name = "UConstRange";

  // ctor
  constexpr UConstRange() : v{} {}
  constexpr UConstRange(const std::array<BV, arity> &x) : v{x} {}

  constexpr const BV &operator[](std::size_t i) const noexcept { return v[i]; }

  friend std::ostream &operator<<(std::ostream &os, const UConstRange &x) {
    if (x.isBottom()) {
      return os << "(bottom)\n";
    }

    os << '[' << x.lower().getZExtValue() << ", " << x.upper().getZExtValue()
       << ']';

    if (x.isTop())
      os << " (top)";

    return os << "\n";
  }

  bool constexpr isTop() const noexcept {
    return lower() == APInt<BW>::getZero() &&
           upper() == APInt<BW>::getMaxValue();
  }
  bool constexpr isBottom() const noexcept { return lower().ugt(upper()); }

  const constexpr UConstRange meet(const UConstRange &rhs) const noexcept {
    const APInt l = rhs.lower().ugt(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().ult(upper()) ? rhs.upper() : upper();
    if (l.ugt(u))
      return bottom();
    return UConstRange({std::move(l), std::move(u)});
  }

  const constexpr UConstRange join(const UConstRange &rhs) const noexcept {
    const APInt l = rhs.lower().ult(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().ugt(upper()) ? rhs.upper() : upper();
    return UConstRange({std::move(l), std::move(u)});
  }

  const constexpr std::vector<APInt<BW>> toConcrete() const noexcept {
    if (lower().ugt(upper()))
      return {};

    std::vector<APInt<BW>> res;
    res.reserve(APIntOps::abdu(lower(), upper()).getZExtValue() + 1);

    for (APInt x = lower(); x.ule(upper()); x += 1) {
      res.push_back(x);

      if (x == APInt<BW>::getMaxValue())
        break;
    }

    return res;
  }

  constexpr std::uint64_t distance(const UConstRange &rhs) const noexcept {
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

  static constexpr const UConstRange fromConcrete(const APInt<BW> &x) noexcept {
    return UConstRange({x, x});
  }

  const APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<unsigned long> dist(lower().getZExtValue(),
                                                      upper().getZExtValue());
    return APInt<BW>(dist(rng));
  }

  static const UConstRange rand(std::mt19937 &rng) noexcept {
    std::uniform_int_distribution<unsigned long> dist(
        0, APInt<BW>::getAllOnes().getZExtValue());

    UConstRange cr({APInt<BW>(dist(rng)), APInt<BW>(dist(rng))});
    if (cr.isBottom()) {
      const APInt tmp = cr.v[0];
      cr.v[0] = cr.v[1];
      cr.v[1] = tmp;
    }

    return cr;
  }

  static constexpr const UConstRange bottom() noexcept {
    constexpr APInt min = APInt<BW>::getMinValue();
    constexpr APInt max = APInt<BW>::getMaxValue();
    return UConstRange({max, min});
  }

  static constexpr const UConstRange top() noexcept {
    constexpr APInt min = APInt<BW>::getMinValue();
    constexpr APInt max = APInt<BW>::getMaxValue();
    return UConstRange({min, max});
  }

  // TODO put a reserve call for the vector
  static constexpr std::vector<UConstRange> const enumLattice() noexcept {
    const unsigned int min =
        static_cast<unsigned int>(APInt<BW>::getMinValue().getZExtValue());
    const unsigned int max =
        static_cast<unsigned int>(APInt<BW>::getMaxValue().getZExtValue());
    APInt l = APInt<BW>(0);
    APInt u = APInt<BW>(0);
    std::vector<UConstRange> ret = {};

    for (unsigned int i = min; i <= max; ++i) {
      for (unsigned int j = i; j <= max; ++j) {
        l = i;
        u = j;
        ret.emplace_back(UConstRange({l, u}));
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
};

static_assert(Domain<UConstRange, 4>);
static_assert(Domain<UConstRange, 8>);
static_assert(Domain<UConstRange, 16>);
static_assert(Domain<UConstRange, 32>);
static_assert(Domain<UConstRange, 64>);
