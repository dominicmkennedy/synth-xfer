#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <ostream>
#include <random>
#include <string_view>
#include <vector>

#include "apint.hpp"
#include "domain.hpp"

using namespace DomainHelpers;

template <std::size_t BW> class SConstRange {
public:
  using BV = APInt<BW>;
  static constexpr std::size_t arity = 2;
  static constexpr std::string_view name = "SConstRange";

  // ctor
  constexpr SConstRange() : v{} {}
  constexpr SConstRange(const std::array<BV, arity> &x) : v{x} {}

  constexpr const BV &operator[](std::size_t i) const noexcept { return v[i]; }

  friend std::ostream &operator<<(std::ostream &os, const SConstRange &x) {
    if (x.isBottom()) {
      return os << "(bottom)\n";
    }

    os << '[' << x.lower().getSExtValue() << ", " << x.upper().getSExtValue()
       << ']';

    if (x.isTop())
      os << " (top)";

    return os << "\n";
  }

  bool constexpr isTop() const noexcept {
    return lower() == APInt<BW>::getSignedMinValue() &&
           upper() == APInt<BW>::getSignedMaxValue();
  }
  bool constexpr isBottom() const noexcept { return lower().sgt(upper()); }

  const constexpr SConstRange meet(const SConstRange &rhs) const noexcept {
    const APInt l = rhs.lower().sgt(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().slt(upper()) ? rhs.upper() : upper();
    if (l.sgt(u))
      return bottom();
    return SConstRange({std::move(l), std::move(u)});
  }

  const constexpr SConstRange join(const SConstRange &rhs) const noexcept {
    const APInt l = rhs.lower().slt(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().sgt(upper()) ? rhs.upper() : upper();
    return SConstRange({std::move(l), std::move(u)});
  }

  const constexpr std::vector<APInt<BW>> toConcrete() const noexcept {
    if (lower().sgt(upper()))
      return {};

    std::vector<APInt<BW>> res;
    res.reserve(APIntOps::abds(lower(), upper()).getZExtValue() + 1);

    for (APInt x = lower(); x.sle(upper()); x += 1) {
      res.push_back(x);

      if (x == APInt<BW>::getSignedMaxValue())
        break;
    }

    return res;
  }

  constexpr std::uint64_t distance(const SConstRange &rhs) const noexcept {
    if (isBottom() && rhs.isBottom())
      return 0;

    if (isBottom())
      return APIntOps::abds(rhs.lower(), rhs.upper()).getActiveBits();

    if (rhs.isBottom())
      return APIntOps::abds(lower(), upper()).getActiveBits();

    const APInt ld = APIntOps::abds(lower(), rhs.lower());
    const APInt ud = APIntOps::abds(upper(), rhs.upper());
    return static_cast<unsigned long>((ld + ud).getActiveBits());
  }

  static constexpr const SConstRange fromConcrete(const APInt<BW> &x) noexcept {
    return SConstRange({x, x});
  }

  const APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<long> dist(lower().getSExtValue(),
                                             upper().getSExtValue());
    return APInt<BW>(static_cast<unsigned long>(dist(rng)));
  }

  static const SConstRange rand(std::mt19937 &rng) noexcept {
    std::uniform_int_distribution<unsigned long> dist(
        0, APInt<BW>::getAllOnes().getZExtValue());

    SConstRange cr({APInt<BW>(dist(rng)), APInt<BW>(dist(rng))});
    if (cr.isBottom()) {
      const APInt tmp = cr.v[0];
      cr.v[0] = cr.v[1];
      cr.v[1] = tmp;
    }

    return cr;
  }

  static constexpr const SConstRange bottom() noexcept {
    constexpr APInt min = APInt<BW>::getSignedMinValue();
    constexpr APInt max = APInt<BW>::getSignedMaxValue();
    return SConstRange({max, min});
  }

  static constexpr const SConstRange top() noexcept {
    constexpr APInt min = APInt<BW>::getSignedMinValue();
    constexpr APInt max = APInt<BW>::getSignedMaxValue();
    return SConstRange({min, max});
  }

  // TODO put a reserve call for the vector
  static constexpr std::vector<SConstRange> const enumLattice() noexcept {
    const int min =
        static_cast<int>(APInt<BW>::getSignedMinValue().getSExtValue());
    const int max =
        static_cast<int>(APInt<BW>::getSignedMaxValue().getSExtValue());
    APInt l = APInt<BW>::getSignedMinValue();
    APInt u = APInt<BW>::getSignedMinValue();
    std::vector<SConstRange> ret = {};

    for (int i = min; i <= max; ++i) {
      for (int j = i; j <= max; ++j) {
        l = static_cast<unsigned long>(i);
        u = static_cast<unsigned long>(j);
        ret.emplace_back(SConstRange({l, u}));
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

static_assert(Domain<SConstRange, 4>);
static_assert(Domain<SConstRange, 8>);
static_assert(Domain<SConstRange, 16>);
static_assert(Domain<SConstRange, 32>);
static_assert(Domain<SConstRange, 64>);
