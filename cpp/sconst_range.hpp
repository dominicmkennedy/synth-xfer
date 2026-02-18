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

    return os << "\n";
  }

  bool constexpr isTop() const noexcept {
    return lower() == APInt<BW>::getSignedMinValue() &&
           upper() == APInt<BW>::getSignedMaxValue();
  }
  bool constexpr isBottom() const noexcept { return lower().sgt(upper()); }

  constexpr SConstRange meet(const SConstRange &rhs) const noexcept {
    const BV l = rhs.lower().sgt(lower()) ? rhs.lower() : lower();
    const BV u = rhs.upper().slt(upper()) ? rhs.upper() : upper();
    if (l.sgt(u))
      return bottom();
    return SConstRange({l, u});
  }

  constexpr SConstRange join(const SConstRange &rhs) const noexcept {
    const BV l = rhs.lower().slt(lower()) ? rhs.lower() : lower();
    const BV u = rhs.upper().sgt(upper()) ? rhs.upper() : upper();
    return SConstRange({l, u});
  }

  std::vector<APInt<BW>> toConcrete() const {
    if (lower().sgt(upper()))
      return {};

    std::vector<APInt<BW>> res;
    res.reserve(APIntOps::abds(lower(), upper()).getZExtValue() + 1);

    for (BV x = lower(); x.sle(upper()); x += 1) {
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
      return APIntOps::abds(rhs.lower(), rhs.upper()).getZExtValue();

    if (rhs.isBottom())
      return APIntOps::abds(lower(), upper()).getZExtValue();

    const std::uint64_t ld =
        APIntOps::abds(lower(), rhs.lower()).getZExtValue();
    const std::uint64_t ud =
        APIntOps::abds(upper(), rhs.upper()).getZExtValue();
    return ld + ud;
  }

  constexpr std::uint64_t size() const noexcept {
    return distance(SConstRange::bottom());
  }

  static constexpr SConstRange fromConcrete(const APInt<BW> &x) noexcept {
    return SConstRange({x, x});
  }

  static SConstRange parse(std::string_view s) {
    if (s == "(bottom)") {
      return SConstRange::bottom();
    }

    if (s.size() < 6 || s.front() != '[' || s.back() != ']') {
      throw std::invalid_argument("SConstRange: invalid format");
    }

    const std::size_t comma = s.find(", ");
    if (comma == std::string_view::npos) {
      throw std::invalid_argument("SConstRange: invalid format");
    }

    if (comma == 1 || comma + 2 >= s.size() - 1) {
      throw std::invalid_argument("SConstRange: invalid format");
    }

    const std::string_view low_sv = s.substr(1, comma - 1);
    const std::string_view high_sv =
        s.substr(comma + 2, s.size() - (comma + 2) - 1);

    std::size_t pos = 0;
    const std::int64_t low = std::stoll(std::string(low_sv), &pos, 10);
    if (pos != low_sv.size()) {
      throw std::invalid_argument("SConstRange: invalid format");
    }
    pos = 0;
    const std::int64_t high = std::stoll(std::string(high_sv), &pos, 10);
    if (pos != high_sv.size()) {
      throw std::invalid_argument("SConstRange: invalid format");
    }

    const std::int64_t minv = APInt<BW>::getSignedMinValue().getSExtValue();
    const std::int64_t maxv = APInt<BW>::getSignedMaxValue().getSExtValue();

    if (low < minv || low > maxv || high < minv || high > maxv) {
      throw std::invalid_argument("SConstRange: value out of range");
    }

    return SConstRange({APInt<BW>(static_cast<std::uint64_t>(low)),
                        APInt<BW>(static_cast<std::uint64_t>(high))});
  }

  APInt<BW> sample_concrete(std::mt19937 &rng) const {
    std::uniform_int_distribution<std::int64_t> dist(lower().getSExtValue(),
                                                     upper().getSExtValue());
    return APInt<BW>(static_cast<std::uint64_t>(dist(rng)));
  }

  static SConstRange rand(std::mt19937 &rng, std::uint64_t level) noexcept {
    const __int128_t level128 = static_cast<__int128_t>(level);
    const std::int64_t lb = APInt<BW>::getSignedMinValue().getSExtValue();
    const std::int64_t max = APInt<BW>::getSignedMaxValue().getSExtValue();

    const __int128_t ub128 = static_cast<__int128_t>(max) - level128;

    std::uniform_int_distribution<std::int64_t> dist(
        lb, static_cast<std::int64_t>(ub128));

    const std::int64_t low = dist(rng);

    const __int128_t high128 = static_cast<__int128_t>(low) + level128;
    const std::int64_t high = static_cast<std::int64_t>(high128);
    return SConstRange({APInt<BW>(static_cast<std::uint64_t>(low)),
                        APInt<BW>(static_cast<std::uint64_t>(high))});
  }

  static constexpr SConstRange bottom() noexcept {
    constexpr BV min = APInt<BW>::getSignedMinValue();
    constexpr BV max = APInt<BW>::getSignedMaxValue();
    return SConstRange({max, min});
  }

  static constexpr SConstRange top() noexcept {
    constexpr BV min = APInt<BW>::getSignedMinValue();
    constexpr BV max = APInt<BW>::getSignedMaxValue();
    return SConstRange({min, max});
  }

  // TODO put a reserve call for the vector
  static std::vector<SConstRange> enumLattice() {
    const int min =
        static_cast<int>(APInt<BW>::getSignedMinValue().getSExtValue());
    const int max =
        static_cast<int>(APInt<BW>::getSignedMaxValue().getSExtValue());
    BV l = APInt<BW>::getSignedMinValue();
    BV u = APInt<BW>::getSignedMinValue();
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

  static constexpr std::uint64_t num_levels() noexcept {
    return APInt<BW>::getMaxValue().getZExtValue();
  }

  // TODO make private?
  std::array<BV, arity> v{};

private:
  [[nodiscard]] constexpr const BV &lower() const noexcept { return v[0]; }
  [[nodiscard]] constexpr const BV &upper() const noexcept { return v[1]; }
};

static_assert(Domain<SConstRange, 4>);
static_assert(Domain<SConstRange, 8>);
static_assert(Domain<SConstRange, 16>);
static_assert(Domain<SConstRange, 32>);
static_assert(Domain<SConstRange, 64>);
