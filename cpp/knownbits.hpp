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
#include "pdep.hpp"

template <std::size_t BW> class KnownBits {
public:
  using BV = APInt<BW>;
  static constexpr std::size_t arity = 2;
  static constexpr std::string_view name = "KnownBits";

  // ctor
  constexpr KnownBits() : v{} {}
  constexpr KnownBits(const std::array<BV, arity> &x) : v{x} {}

  constexpr const BV &operator[](std::size_t i) const noexcept { return v[i]; }

  friend std::ostream &operator<<(std::ostream &os, const KnownBits &x) {
    if (x.isBottom()) {
      return os << "(bottom)\n";
    }

    for (unsigned int i = BW; i > 0; --i)
      os << (x.one()[i - 1] ? '1' : x.zero()[i - 1] ? '0' : '?');

    return os << "\n";
  }

  bool constexpr isTop() const noexcept {
    return zero() == APInt<BW>::getZero() && one() == APInt<BW>::getZero();
  }
  bool constexpr isBottom() const noexcept { return zero().intersects(one()); }

  constexpr KnownBits meet(const KnownBits &rhs) const noexcept {
    return KnownBits({zero() | rhs.zero(), one() | rhs.one()});
  }

  constexpr KnownBits join(const KnownBits &rhs) const noexcept {
    return KnownBits({zero() & rhs.zero(), one() & rhs.one()});
  }

  constexpr std::vector<APInt<BW>> toConcrete() const {
    std::vector<APInt<BW>> res;
    const APInt<BW> unknown_bits = ~(zero() | one());
    const std::uint32_t num_unknown_bits = unknown_bits.popcount();

    // fast case if *this is top
    if (num_unknown_bits == BW) {
      constexpr APInt<BW> max = APInt<BW>::getMaxValue();
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

  constexpr std::uint64_t size() const noexcept {
    if (isBottom())
      return 0;
    if (isTop())
      return APInt<BW>::getMaxValue().getZExtValue();

    return (1ULL << distance(KnownBits::bottom())) - 1;
  }

  static constexpr KnownBits fromConcrete(const APInt<BW> &x) noexcept {
    return KnownBits({~x, x});
  }

  static KnownBits parse(std::string_view s) {
    if (s == "(bottom)") {
      return KnownBits::bottom();
    }

    if (s.size() != BW) {
      throw std::invalid_argument("KnownBits: invalid bitstring length");
    }

    std::uint64_t zero_mask = 0;
    std::uint64_t one_mask = 0;

    for (std::size_t i = 0; i < BW; ++i) {
      const char c = s[i];
      const std::size_t bit = BW - 1 - i;
      switch (c) {
      case '0':
        zero_mask |= (1ULL << bit);
        break;
      case '1':
        one_mask |= (1ULL << bit);
        break;
      case '?':
        break;
      default:
        throw std::invalid_argument("KnownBits: invalid character");
      }
    }

    return KnownBits({APInt<BW>(zero_mask), APInt<BW>(one_mask)});
  }

  APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<unsigned long> dist(
        0, APInt<BW>::getAllOnes().getZExtValue());

    APInt<BW> val = APInt<BW>(dist(rng));
    val &= ~zero();
    val |= one();

    return val;
  }

  static KnownBits rand(std::mt19937 &rng, std::uint64_t level) noexcept {
    assert(level <= BW);

    auto rand_bounded = [&rng](std::uint32_t bound) -> std::uint32_t {
      const std::uint32_t threshold =
          static_cast<std::uint32_t>(-bound) % bound;
      for (;;) {
        std::uint32_t x = static_cast<std::uint32_t>(rng());
        if (x >= threshold) {
          return x % bound;
        }
      }
    };

    std::uint64_t unknownMask = 0;
    std::uint64_t remaining = level;

    for (std::uint32_t i = 0; i < BW && remaining > 0; ++i) {
      std::uint32_t positions_left = BW - i;
      std::uint32_t r = rand_bounded(positions_left);
      if (r < remaining) {
        unknownMask |= (std::uint64_t(1) << i);
        --remaining;
      }
    }

    auto random_u64 = [&rng]() -> std::uint64_t {
      std::uint64_t hi = static_cast<std::uint64_t>(rng());
      std::uint64_t lo = static_cast<std::uint64_t>(rng());
      return (hi << 32) ^ lo;
    };

    const std::uint64_t choice = random_u64();

    const std::uint64_t onesMask = choice & ~unknownMask;
    const std::uint64_t zerosMask = (~choice) & ~unknownMask;

    const APInt<BW> zeros(zerosMask);
    const APInt<BW> ones(onesMask);

    assert((zeros & ones) == APInt<BW>(0));
    assert((zeros | ones) == ~APInt<BW>(unknownMask));
    assert((~(zeros | ones)).popcount() == level);

    return KnownBits({zeros, ones});
  }

  static constexpr KnownBits bottom() noexcept {
    constexpr APInt<BW> max = APInt<BW>::getMaxValue();
    return KnownBits{{max, max}};
  }

  static constexpr KnownBits top() noexcept {
    constexpr APInt<BW> min = APInt<BW>::getZero();
    return KnownBits{{min, min}};
  }

  static constexpr std::vector<KnownBits> enumLattice() {
    constexpr std::uint64_t max =
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

  static constexpr std::uint64_t num_levels() noexcept { return BW; }

  // TODO make private?
  std::array<BV, arity> v{};

private:
  [[nodiscard]] constexpr const APInt<BW> &zero() const noexcept {
    return v[0];
  }
  [[nodiscard]] constexpr const APInt<BW> &one() const noexcept { return v[1]; }

  [[nodiscard]] constexpr bool isConstant() const noexcept {
    return zero().popcount() + one().popcount() == BW;
  }

  [[nodiscard]] constexpr const APInt<BW> getConstant() const noexcept {
    assert(this->isConstant() && "Can't get constant if val is not const");
    return one();
  }
};

static_assert(Domain<KnownBits, 4>);
static_assert(Domain<KnownBits, 8>);
static_assert(Domain<KnownBits, 16>);
static_assert(Domain<KnownBits, 32>);
static_assert(Domain<KnownBits, 64>);
