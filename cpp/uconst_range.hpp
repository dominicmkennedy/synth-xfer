#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <ostream>
#include <random>
#include <string>
#include <string_view>
#include <vector>

#include "apint.hpp"
#include "domain.hpp"

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

    return os << "\n";
  }

  bool constexpr isTop() const noexcept {
    return lower() == APInt<BW>::getZero() &&
           upper() == APInt<BW>::getMaxValue();
  }
  bool constexpr isBottom() const noexcept { return lower().ugt(upper()); }

  constexpr UConstRange meet(const UConstRange &rhs) const noexcept {
    const BV l = rhs.lower().ugt(lower()) ? rhs.lower() : lower();
    const BV u = rhs.upper().ult(upper()) ? rhs.upper() : upper();
    if (l.ugt(u))
      return bottom();
    return UConstRange({l, u});
  }

  constexpr UConstRange join(const UConstRange &rhs) const noexcept {
    const BV l = rhs.lower().ult(lower()) ? rhs.lower() : lower();
    const BV u = rhs.upper().ugt(upper()) ? rhs.upper() : upper();
    return UConstRange({l, u});
  }

  std::vector<APInt<BW>> toConcrete() const {
    if (lower().ugt(upper()))
      return {};

    std::vector<APInt<BW>> res;
    res.reserve(APIntOps::abdu(lower(), upper()).getZExtValue() + 1);

    for (APInt<BW> x = lower(); x.ule(upper()); x += 1) {
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
      return APIntOps::abdu(rhs.lower(), rhs.upper()).getZExtValue();

    if (rhs.isBottom())
      return APIntOps::abdu(lower(), upper()).getZExtValue();

    const std::uint64_t ld =
        APIntOps::abdu(lower(), rhs.lower()).getZExtValue();
    const std::uint64_t ud =
        APIntOps::abdu(upper(), rhs.upper()).getZExtValue();
    return ld + ud;
  }

  constexpr std::uint64_t size() const noexcept {
    return distance(UConstRange::bottom());
  }

  static constexpr UConstRange fromConcrete(const APInt<BW> &x) noexcept {
    return UConstRange({x, x});
  }

  static UConstRange parse(std::string_view s) {
    if (s == "(bottom)") {
      return UConstRange::bottom();
    }

    if (s.size() < 5 || s.front() != '[' || s.back() != ']') {
      throw std::invalid_argument("UConstRange: invalid format");
    }

    const std::size_t comma = s.find(", ");
    if (comma == std::string_view::npos) {
      throw std::invalid_argument("UConstRange: invalid format");
    }

    if (comma == 1 || comma + 2 >= s.size() - 1) {
      throw std::invalid_argument("UConstRange: invalid format");
    }

    const std::string_view low_sv = s.substr(1, comma - 1);
    const std::string_view high_sv =
        s.substr(comma + 2, s.size() - (comma + 2) - 1);

    std::size_t pos = 0;
    const std::uint64_t low = std::stoull(std::string(low_sv), &pos, 10);
    if (pos != low_sv.size()) {
      throw std::invalid_argument("UConstRange: invalid format");
    }
    pos = 0;
    const std::uint64_t high = std::stoull(std::string(high_sv), &pos, 10);
    if (pos != high_sv.size()) {
      throw std::invalid_argument("UConstRange: invalid format");
    }

    const std::uint64_t max = APInt<BW>::getMaxValue().getZExtValue();
    if (low > max || high > max) {
      throw std::invalid_argument("UConstRange: value out of range");
    }

    return UConstRange({APInt<BW>(low), APInt<BW>(high)});
  }

  APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<std::uint64_t> dist(lower().getZExtValue(),
                                                      upper().getZExtValue());
    return APInt<BW>(dist(rng));
  }

  static UConstRange rand(std::mt19937 &rng, std::uint64_t level) noexcept {
    const std::uint64_t allOnes = APInt<BW>::getAllOnes().getZExtValue();
    assert(level <= allOnes);

    std::uint64_t ub = allOnes - level;
    std::uniform_int_distribution<std::uint64_t> dist(0, ub);
    std::uint64_t low = dist(rng);

    return UConstRange({APInt<BW>(low), APInt<BW>(low + level)});
  }

  static constexpr UConstRange bottom() noexcept {
    constexpr APInt<BW> min = APInt<BW>::getMinValue();
    constexpr APInt<BW> max = APInt<BW>::getMaxValue();
    return UConstRange({max, min});
  }

  static constexpr UConstRange top() noexcept {
    constexpr APInt<BW> min = APInt<BW>::getMinValue();
    constexpr APInt<BW> max = APInt<BW>::getMaxValue();
    return UConstRange({min, max});
  }

  // TODO put a reserve call for the vector
  static std::vector<UConstRange> enumLattice() {
    const unsigned int min =
        static_cast<unsigned int>(APInt<BW>::getMinValue().getZExtValue());
    const unsigned int max =
        static_cast<unsigned int>(APInt<BW>::getMaxValue().getZExtValue());
    BV l = BV(0);
    BV u = BV(0);
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

  static constexpr std::uint64_t num_levels() noexcept {
    return APInt<BW>::getMaxValue().getZExtValue();
  }

  // TODO make private?
  std::array<BV, arity> v{};

private:
  [[nodiscard]] constexpr const APInt<BW> &lower() const noexcept {
    return v[0];
  }
  [[nodiscard]] constexpr const APInt<BW> &upper() const noexcept {
    return v[1];
  }
};

static_assert(Domain<UConstRange, 4>);
static_assert(Domain<UConstRange, 8>);
static_assert(Domain<UConstRange, 16>);
static_assert(Domain<UConstRange, 32>);
static_assert(Domain<UConstRange, 64>);
