#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <ostream>
#include <random>
#include <vector>

#include "apint.hpp"
#include "domain.hpp"
#include "pdep.hpp"

using namespace DomainHelpers;

template <std::size_t BW> class KnownBits {
public:
  using BV = APInt<BW>;
  static constexpr std::size_t arity = 2;
  static constexpr std::string name = "KnownBits";

  // ctor
  constexpr KnownBits(const std::array<BV, arity> &x) : v{x} {}

  constexpr const BV &operator[](std::size_t i) const noexcept { return v[i]; }

  friend std::ostream &operator<<(std::ostream &os, const KnownBits &x) {
    if (x.isBottom()) {
      return os << "(bottom)\n";
    }

    for (unsigned int i = BW; i > 0; --i)
      os << (x.one()[i - 1] ? '1' : x.zero()[i - 1] ? '0' : '?');

    if (x.isConstant())
      os << " const: "
         << static_cast<std::uint64_t>(x.getConstant().getZExtValue());

    if (isTop(x))
      os << " (top)";

    return os << "\n";
  }

  bool constexpr isBottom() const noexcept { return zero().intersects(one()); }

  const constexpr KnownBits meet(const KnownBits &rhs) const noexcept {
    return KnownBits({zero() | rhs.zero(), one() | rhs.one()});
  }

  const constexpr KnownBits join(const KnownBits &rhs) const noexcept {
    return KnownBits({zero() & rhs.zero(), one() & rhs.one()});
  }

  const constexpr std::vector<APInt<BW>> toConcrete() const noexcept {
    std::vector<APInt<BW>> res;
    const APInt<BW> unknown_bits = ~(zero() | one());
    const std::uint32_t num_unknown_bits = unknown_bits.popcount();

    // fast case if *this is top
    if (num_unknown_bits == BW) {
      constexpr const APInt<BW> max = APInt<BW>::getMaxValue();
      res.reserve(max.getZExtValue());

      for (APInt<BW> i = APInt<BW>::getZero();; ++i) {
        res.emplace_back(i);

        if (i == max)
          break;
      }

      return res;
    }

    // fast case if *this is a const
    if (num_unknown_bits == 0) {
      res.emplace_back(one());
      return res;
    }

    const std::uint64_t num_perms = 1ULL << num_unknown_bits;
    res.reserve(num_perms);
    const std::uint64_t mask = unknown_bits.getZExtValue();
    for (std::size_t i = 0; i < num_perms; ++i) {
      std::uint64_t r = pdep<BW>(i, mask);
      res.emplace_back(APInt<BW>(r) | one());
    }

    return res;
  }

  constexpr std::uint64_t distance(const KnownBits &rhs) const noexcept {
    if (isBottom() && rhs.isBottom())
      return 0;

    if (isBottom())
      return BW - (rhs.zero() ^ rhs.one()).popcount();

    if (rhs.isBottom())
      return BW - (zero() ^ one()).popcount();

    return (zero() ^ rhs.zero()).popcount() + (one() ^ rhs.one()).popcount();
  }

  static constexpr const KnownBits fromConcrete(const APInt<BW> &x) noexcept {
    return KnownBits({~x, x});
  }

  const APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<unsigned long> dist(
        0, APInt<BW>::getAllOnes().getZExtValue());

    APInt val = APInt<BW>(dist(rng));
    val &= ~zero();
    val |= one();

    return val;
  }

  static const KnownBits rand(std::mt19937 &rng) noexcept {
    std::uniform_int_distribution<unsigned long> dist(
        0, APInt<BW>::getAllOnes().getZExtValue());

    APInt zeros = APInt<BW>(dist(rng));
    APInt ones = APInt<BW>(dist(rng));
    const APInt makeUnknown = APInt<BW>(dist(rng));
    const APInt resolveTo = APInt<BW>(dist(rng));

    APInt conflicts = zeros & ones;
    zeros &= ~(conflicts & makeUnknown);
    ones &= ~(conflicts & makeUnknown);

    zeros &= ~(resolveTo & (conflicts & ~makeUnknown));
    ones &= ~(~resolveTo & (conflicts & ~makeUnknown));

    return KnownBits({zeros, ones});
  }

  static constexpr const KnownBits bottom() noexcept {
    constexpr const APInt<BW> max = APInt<BW>::getMaxValue();
    return KnownBits{{max, max}};
  }

  static constexpr const KnownBits top() noexcept {
    constexpr const APInt<BW> min = APInt<BW>::getZero();
    return KnownBits{{min, min}};
  }

  static constexpr std::vector<KnownBits> const enumLattice() noexcept {
    constexpr const std::uint64_t max =
        static_cast<std::uint64_t>(APInt<BW>::getMaxValue().getZExtValue());
    APInt<BW> zero = APInt<BW>(0);
    APInt<BW> one = APInt<BW>(0);
    std::vector<KnownBits> ret;
    ret.reserve(max * max);

    for (std::size_t i = 0; i <= max; ++i) {
      std::uint8_t jmp = i % 2 + 1;
      for (std::size_t j = 0; j <= max; j += jmp) {
        if ((i & j) != 0)
          continue;

        zero = i;
        one = j;
        ret.emplace_back(KnownBits({zero, one}));
      }
    }

    return ret;
  }

  static constexpr double maxDist() noexcept { return BW; }

  // TODO make private?
  std::array<BV, arity> v{};

private:
  [[nodiscard]] constexpr const APInt<BW> zero() const noexcept { return v[0]; }
  [[nodiscard]] constexpr const APInt<BW> one() const noexcept { return v[1]; }

  // TODO make public/require in the concept
  [[nodiscard]] constexpr bool isConstant() const noexcept {
    return zero().popcount() + one().popcount() == BW;
  }

  [[nodiscard]] constexpr const APInt<BW> getConstant() const noexcept {
    assert(this.isConstant() && "Can't get constant if val is not const");
    return one();
  }
};

static_assert(Domain<KnownBits, 4>);
static_assert(Domain<KnownBits, 8>);
static_assert(Domain<KnownBits, 16>);
static_assert(Domain<KnownBits, 32>);
static_assert(Domain<KnownBits, 64>);
