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
#include "to_string.hpp"

template <std::size_t X_> struct ModT {
  static constexpr std::size_t X = X_;

  template <std::size_t BW> class Mod {
  public:
    using BV = APInt<X>;
    static constexpr std::size_t arity = 1;
    static constexpr std::string name = "Mod" + ct::to_string<X>();

    // ctor
    constexpr Mod() : v{} {}
    constexpr Mod(const std::array<BV, arity> &x) : v{x} {}
    constexpr Mod(const std::array<APInt<BW>, arity> &x) : v{} {
      v[0] = APInt<X>{x[0].getZExtValue()};
    }

    constexpr const BV &operator[](std::size_t i) const noexcept {
      return v[i];
    }

    friend std::ostream &operator<<(std::ostream &os, const Mod &x) {
      if (x.isBottom()) {
        return os << "(bottom)\n";
      }

      os << "{";

      bool first = true;
      for (unsigned int i = 0; i < X; ++i) {
        if (x[0][i]) {
          if (!first)
            os << ",";
          os << i;
          first = false;
        }
      }

      os << "} mod" << X << "\n";

      return os;
    }

    bool constexpr isTop() const noexcept { return v[0].isAllOnes(); }
    bool constexpr isBottom() const noexcept { return v[0] == 0; }

    constexpr Mod meet(const Mod &rhs) const noexcept {
      return {{rhs.v[0] & v[0]}};
    }

    constexpr Mod join(const Mod &rhs) const noexcept {
      return Mod({rhs.v[0] | v[0]});
    }

    std::vector<APInt<BW>> toConcrete() const {
      std::vector<APInt<BW>> res;

      if (isTop()) {
        constexpr const unsigned long max =
            APInt<BW>::getMaxValue().getZExtValue();
        res.reserve(max);

        for (APInt<BW> i = APInt<BW>::getZero();; ++i) {
          res.emplace_back(i);

          if (i == max)
            break;
        }

        return res;
      }

      if (isBottom()) {
        return res;
      }

      for (unsigned int i = 0; i < X; ++i) {
        if (v[0][i]) {
          bool ov = false;
          for (APInt<BW> j = APInt<BW>(i);; j = j.uadd_ov(APInt<BW>(X), ov)) {
            if (ov)
              break;

            res.emplace_back(j);
          }
        }
      }

      return res;
    }

    constexpr std::uint64_t distance(const Mod &rhs) const noexcept {
      if (isBottom() && rhs.isBottom())
        return 0;

      if (isBottom()) {
        return rhs.v[0].popcount();
      }

      if (rhs.isBottom()) {
        return v[0].popcount();
      }

      return (v[0] ^ rhs.v[0]).popcount();
    }

    constexpr std::uint64_t size() const noexcept {
      if (isBottom())
        return 0;
      if (isTop())
        return APInt<BW>::getMaxValue().getZExtValue();

      std::uint64_t sz = 0;
      for (unsigned int i = 0; i < X; ++i)
        if (v[0][i])
          sz += Mod::get_cong_class_size(i);

      return sz;
    }

    static constexpr Mod fromConcrete(const APInt<BW> &x) noexcept {
      APInt<X> a(0);
      a.setBit(static_cast<unsigned int>(x.urem(APInt<BW>(X)).getZExtValue()));
      return Mod({a});
    }

    static Mod parse(std::string_view s) {
      if (s == "(bottom)") {
        return Mod::bottom();
      }

      const std::string prefix = "{";
      const std::string suffix = "} mod" + std::to_string(X);

      if (s.size() <= prefix.size() + suffix.size()) {
        throw std::invalid_argument("Mod: invalid format");
      }

      if (!s.starts_with(prefix) || !s.ends_with(suffix)) {
        throw std::invalid_argument("Mod: invalid format");
      }

      const std::string_view list_sv =
          s.substr(prefix.size(), s.size() - prefix.size() - suffix.size());

      if (list_sv.empty()) {
        throw std::invalid_argument("Mod: empty set");
      }

      std::uint64_t mask = 0;
      std::int64_t last = -1;
      std::size_t start = 0;

      while (true) {
        const std::size_t sep = list_sv.find(",", start);
        const std::string_view tok = (sep == std::string_view::npos)
                                         ? list_sv.substr(start)
                                         : list_sv.substr(start, sep - start);

        if (tok.empty()) {
          throw std::invalid_argument("Mod: invalid element");
        }

        std::size_t pos = 0;
        const std::uint64_t val = std::stoull(std::string(tok), &pos, 10);
        if (pos != tok.size()) {
          throw std::invalid_argument("Mod: invalid element");
        }

        if (val >= X) {
          throw std::invalid_argument("Mod: element out of range");
        }
        if (static_cast<std::int64_t>(val) <= last) {
          throw std::invalid_argument("Mod: elements not strictly increasing");
        }

        last = static_cast<std::int64_t>(val);
        mask |= (1ULL << val);

        if (sep == std::string_view::npos) {
          break;
        }
        start = sep + 1;
      }

      if (mask == 0) {
        throw std::invalid_argument("Mod: empty set");
      }

      return Mod({APInt<X>(mask)});
    }

    APInt<BW> sample_concrete(std::mt19937 &rng) const {
      assert(!isBottom());

      std::uniform_int_distribution<std::uint64_t> bit_dist(0, X - 1);

      std::uint64_t bit = bit_dist(rng);
      while (!v[0][static_cast<unsigned int>(bit)])
        bit = bit_dist(rng);

      std::uniform_int_distribution<std::uint64_t> val_dist(
          0, Mod::get_cong_class_size(bit) - 1);

      const APInt<BW> idx(val_dist(rng));
      return APInt<BW>(bit) + idx * APInt<BW>(X);
    }

    static Mod rand(std::mt19937 &rng, std::uint64_t level) noexcept {
      assert(level + 1 <= X);

      std::uniform_int_distribution<unsigned long> dist(0, X - 1);
      APInt<X> x(0);

      while (x.popcount() != level + 1) {
        x.setBit(static_cast<unsigned int>(dist(rng)));
      }

      return {{x}};
    }

    static constexpr Mod bottom() noexcept { return {{APInt<X>(0)}}; }

    static constexpr Mod top() noexcept { return {{APInt<X>::getAllOnes()}}; }

    static std::vector<Mod> enumLattice() {
      std::vector<Mod> ret = {};
      const APInt<X> max = APInt<X>::getMaxValue();

      for (APInt<X> i = APInt<X>(1);; ++i) {
        ret.emplace_back(Mod({i}));

        if (i == max)
          break;
      }

      return ret;
    }

    static constexpr std::uint64_t num_levels() noexcept { return X - 1; }

    std::array<BV, arity> v{};

  private:
    [[nodiscard]] static constexpr std::uint64_t
    get_cong_class_size(std::uint64_t x) noexcept {
      const APInt<BW> d = APInt<BW>::getMaxValue().udiv(X);
      bool ov = false;
      const APInt<BW> _ = (d * X).uadd_ov(APInt<BW>(x), ov);

      return d.getZExtValue() + (ov ? 0 : 1);
    }
  };
};

template <std::size_t BW> using Mod3 = ModT<3>::Mod<BW>;
template <std::size_t BW> using Mod5 = ModT<5>::Mod<BW>;
template <std::size_t BW> using Mod7 = ModT<7>::Mod<BW>;
template <std::size_t BW> using Mod11 = ModT<11>::Mod<BW>;
template <std::size_t BW> using Mod13 = ModT<13>::Mod<BW>;

static_assert(Domain<Mod3, 4>);
static_assert(Domain<Mod3, 8>);
static_assert(Domain<Mod3, 16>);
static_assert(Domain<Mod3, 32>);
static_assert(Domain<Mod3, 64>);

static_assert(Domain<Mod5, 4>);
static_assert(Domain<Mod5, 8>);
static_assert(Domain<Mod5, 16>);
static_assert(Domain<Mod5, 32>);
static_assert(Domain<Mod5, 64>);

static_assert(Domain<Mod7, 4>);
static_assert(Domain<Mod7, 8>);
static_assert(Domain<Mod7, 16>);
static_assert(Domain<Mod7, 32>);
static_assert(Domain<Mod7, 64>);

static_assert(Domain<Mod11, 4>);
static_assert(Domain<Mod11, 8>);
static_assert(Domain<Mod11, 16>);
static_assert(Domain<Mod11, 32>);
static_assert(Domain<Mod11, 64>);

static_assert(Domain<Mod13, 4>);
static_assert(Domain<Mod13, 8>);
static_assert(Domain<Mod13, 16>);
static_assert(Domain<Mod13, 32>);
static_assert(Domain<Mod13, 64>);
