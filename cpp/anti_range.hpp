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

template <std::size_t BW> class AntiRange {
public:
  using BV = APInt<BW>;
  static constexpr std::size_t arity = 2;
  static constexpr std::string_view name = "AntiRange";

  // ctor
  constexpr AntiRange() : v{} {}
  constexpr AntiRange(const std::array<BV, arity> &x)
      : AntiRange(x, /*normalize=*/true) {}

  constexpr const BV &operator[](std::size_t i) const noexcept { return v[i]; }

  friend std::ostream &operator<<(std::ostream &os, const AntiRange &x) {
    if (x.isBottom()) {
      return os << "(bottom)\n";
    }

    os << "![" << x.lower().getZExtValue() << ", " << x.upper().getZExtValue()
       << ']';

    if (x.isTop())
      os << " (top)";

    return os << "\n";
  }

  bool constexpr isTop() const noexcept { return lower().ugt(upper()); }
  bool constexpr isBottom() const noexcept {
    return lower() == APInt<BW>::getMinValue() ||
           upper() == APInt<BW>::getMaxValue();
  }

  const constexpr AntiRange meet(const AntiRange &rhs) const noexcept {
    const APInt l = rhs.lower().ult(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().ugt(upper()) ? rhs.upper() : upper();
    AntiRange ar = AntiRange({std::move(l), std::move(u)});
    if (ar.isBottom())
      return bottom();
    return ar;
  }

  const constexpr AntiRange join(const AntiRange &rhs) const noexcept {
    const APInt l = rhs.lower().ugt(lower()) ? rhs.lower() : lower();
    const APInt u = rhs.upper().ult(upper()) ? rhs.upper() : upper();
    AntiRange ar = AntiRange({std::move(l), std::move(u)});
    if (ar.isTop())
      return top();
    return ar;
  }

  const constexpr std::vector<APInt<BW>> toConcrete() const noexcept {
    if (isBottom())
      return {};

    std::vector<APInt<BW>> res;
    res.reserve(get_size().getZExtValue());

    for (APInt x = APInt<BW>::getMinValue(); x.ult(lower()); x += 1) {
      res.push_back(x);
    }

    for (APInt x = upper() + 1;; x += 1) {
      res.push_back(x);

      if (x == APInt<BW>::getMaxValue())
        break;
    }

    return res;
  }


  constexpr std::uint64_t distance(const AntiRange &rhs) const noexcept {
    if (isBottom() && rhs.isBottom())
      return 0;

    if (isBottom())
      return rhs.get_size().getZExtValue();

    if (rhs.isBottom())
      return get_size().getZExtValue();

    const APInt ld = APIntOps::abdu(lower(), rhs.lower());
    const APInt ud = APIntOps::abdu(upper(), rhs.upper());
    return static_cast<unsigned long>((ld + ud).getActiveBits());
  }

  static constexpr const AntiRange fromConcrete(const APInt<BW> &x) noexcept {
    if (x.isSignBitSet()) {
      const APInt l = APInt<BW>::getMinValue() + 1;
      const APInt u = x - 1;

      return AntiRange({l, u});
    } else {
      const APInt l = x + 1;
      const APInt u = APInt<BW>::getMaxValue() - 1;

      return AntiRange({l, u});
    }
  }

  const APInt<BW> sample_concrete(std::mt19937 &rng) const {
    if (isTop()) {
      std::uniform_int_distribution<unsigned long> dist(
          0, APInt<BW>::getMaxValue().getZExtValue());
      return APInt<BW>(dist(rng));
    }

    std::uniform_int_distribution<unsigned long> dist(
        0, (get_size() - 1).getZExtValue());
    const APInt val = APInt<BW>(dist(rng));

    if (val.ult(lower()))
      return APInt<BW>(val);
    else
      return APInt<BW>(val + upper() + 1);
  }

  static const AntiRange rand(std::mt19937 &rng) noexcept {
    std::uniform_int_distribution<unsigned long> dist(
        1, APInt<BW>::getAllOnes().getZExtValue() - 1);

    AntiRange cr({APInt<BW>(dist(rng)), APInt<BW>(dist(rng))});
    if (cr.isTop()) {
      const APInt tmp = cr.v[0];
      cr.v[0] = cr.v[1];
      cr.v[1] = tmp;
    }

    return cr;
  }

  static constexpr const AntiRange bottom() noexcept {
    constexpr APInt min = APInt<BW>::getMinValue();
    constexpr APInt max = APInt<BW>::getMaxValue();
    return AntiRange({min, max});
  }

  static constexpr const AntiRange top() noexcept {
    constexpr APInt min = APInt<BW>::getMinValue();
    constexpr APInt max = APInt<BW>::getMaxValue();
    return AntiRange({max, min});
  }

  // TODO put a reserve call for the vector
  static constexpr std::vector<AntiRange> const enumLattice() noexcept {
    const unsigned int min = 1;
    const unsigned int max =
        static_cast<unsigned int>(APInt<BW>::getMaxValue().getZExtValue()) - 1;
    APInt l = APInt<BW>(0);
    APInt u = APInt<BW>(0);
    std::vector<AntiRange> ret = {top()};

    for (unsigned int i = min; i <= max; ++i) {
      for (unsigned int j = i; j <= max; ++j) {
        l = i;
        u = j;
        ret.emplace_back(AntiRange({l, u}));
      }
    }

    return ret;
  }

  static constexpr double maxDist() noexcept { return BW; }

  // TODO make private?
  std::array<BV, arity> v{};

private:
  constexpr AntiRange(const std::array<BV, arity> &x, bool normalize) : v{x} {
    if (normalize) {
      if (isBottom()) {
        v[0] = APInt<BW>::getMinValue();
        v[1] = APInt<BW>::getMaxValue();
      }

      if (isTop()) {
        v[0] = APInt<BW>::getMaxValue();
        v[1] = APInt<BW>::getMinValue();
      }
    }
  }

  [[nodiscard]] constexpr const APInt<BW> get_size() const noexcept {
    if (isBottom())
      return APInt<BW>::getMinValue();

    if (isTop())
      return APInt<BW>::getMaxValue();

    return APInt<BW>::getMaxValue() - APIntOps::abdu(lower(), upper());
  }

  [[nodiscard]] constexpr const APInt<BW> lower() const noexcept {
    return v[0];
  }
  [[nodiscard]] constexpr const APInt<BW> upper() const noexcept {
    return v[1];
  }
};

static_assert(Domain<AntiRange, 4>);
static_assert(Domain<AntiRange, 8>);
static_assert(Domain<AntiRange, 16>);
static_assert(Domain<AntiRange, 32>);
static_assert(Domain<AntiRange, 64>);
