#pragma once

#include <array>
#include <optional>
#include <random>
#include <tuple>
#include <utility>
#include <vector>

#include "apint.hpp"
#include "domain.hpp"
#include "rand.hpp"

using namespace DomainHelpers;

namespace detail {

template <std::size_t N, std::size_t... Is>
auto nary_fn_ptr(std::index_sequence<Is...>) -> std::uint64_t (*)(
    std::conditional_t<true, std::uint64_t,
                       std::integral_constant<std::size_t, Is>>...);

template <std::size_t N>
using nary_fn_t = decltype(nary_fn_ptr<N>(std::make_index_sequence<N>{}));

} // namespace detail

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
class EnumDomain {
public:
  static constexpr std::size_t N = sizeof...(BWs);

  using ResD = Dom<ResBw>;
  using ArgsTuple = std::tuple<Dom<BWs>...>;
  using EvalVec = ToEval<Dom, ResBw, BWs...>;
  using ConcOpFn = detail::nary_fn_t<N>;
  using OpConFn = detail::nary_fn_t<N>;

  constexpr EnumDomain(const std::uintptr_t concOpAddr,
                       const std::optional<std::uintptr_t> opConAddr)
      : concOp(reinterpret_cast<ConcOpFn>(concOpAddr)),
        opCon(opConAddr ? std::optional<OpConFn>(
                              reinterpret_cast<OpConFn>(*opConAddr))
                        : std::nullopt) {}

  EvalVec genLows() const {
    EvalVec r;

    auto lattices =
        std::tuple<std::vector<Dom<BWs>>...>{Dom<BWs>::enumLattice()...};

    ArgsTuple current{};
    for_each_combination<0>(lattices, current, [&](const ArgsTuple &args) {
      r.emplace_back(std::tuple_cat(args, std::tuple<ResD>{toBestAbst(args)}));
    });

    return r;
  }

  EvalVec genMids(unsigned int num_lat_samples, std::mt19937 &rng,
                  const rngdist::Sampler &sampler) {
    EvalVec r;
    r.reserve(num_lat_samples);

    for (unsigned int i = 0; i < num_lat_samples; ++i) {
      ArgsTuple args = make_random_args(rng, sampler);
      ResD res = toBestAbst(args);

      r.emplace_back(std::tuple_cat(args, std::tuple<ResD>{res}));
    }

    return r;
  }

  EvalVec genHighs(unsigned int num_lat_samples, unsigned int num_conc_samples,
                   std::mt19937 &rng, const rngdist::Sampler &sampler) {
    EvalVec r;
    r.reserve(num_lat_samples);

    for (unsigned int i = 0; i < num_lat_samples; ++i) {
      ArgsTuple args = make_random_args(rng, sampler);
      ResD res = ResD::bottom();

      const std::uint64_t cap = static_cast<std::uint64_t>(num_conc_samples);
      const std::uint64_t total_space = capped_concrete_space(args, cap);
      if (total_space <= cap) {
        res = toBestAbst(args);
      } else {
        for (unsigned int j = 0; j < num_conc_samples; ++j) {
          std::array<std::uint64_t, N> concretes{};
          fill_sampled_concretes(args, rng, concretes);

          if (opCon && apply_n_ary(*opCon, concretes) == 0)
            continue;

          auto out = apply_n_ary(concOp, concretes);
          res = res.join(ResD::fromConcrete(APInt<ResBw>(out)));
        }
      }

      r.emplace_back(std::tuple_cat(args, std::tuple<ResD>{res}));
    }

    return r;
  }

private:
  ConcOpFn concOp;
  std::optional<OpConFn> opCon;

  ResD toBestAbst(const ArgsTuple &args) const {
    auto concSets = build_concrete_sets(args);
    ResD res = ResD::bottom();
    std::array<std::uint64_t, N> current{};

    for_each_conc_combination<0>(
        concSets, current, [&](const std::array<std::uint64_t, N> &vals) {
          if (opCon && apply_n_ary(*opCon, vals) == 0)
            return;

          auto out = apply_n_ary(concOp, vals);
          res = res.join(ResD::fromConcrete(APInt<ResBw>(out)));
        });

    return res;
  }

  ArgsTuple make_random_args(std::mt19937 &rng,
                             const rngdist::Sampler &sampler) const {
    ArgsTuple res{};
    std::apply(
        [&](auto &...elems) {
          (
              [&] {
                using D = std::decay_t<decltype(elems)>;
                const std::uint64_t hi = D::num_levels();
                const std::uint64_t level = sampler(rng, 0ULL, hi);
                elems = D::rand(rng, level);
              }(),
              ...);
        },
        res);
    return res;
  }

  void fill_sampled_concretes(const ArgsTuple &args, std::mt19937 &rng,
                              std::array<std::uint64_t, N> &out) const {
    std::size_t i = 0;
    std::apply(
        [&](auto const &...elems) {
          ((out[i++] = elems.sample_concrete(rng).getZExtValue()), ...);
        },
        args);
  }

  template <typename F>
  static std::uint64_t apply_n_ary(F f,
                                   const std::array<std::uint64_t, N> &vals) {
    return [&]<std::size_t... Is>(std::index_sequence<Is...>) {
      return f(vals[Is]...);
    }(std::make_index_sequence<N>{});
  }

  // lattice Cartesian product for genLows
  template <std::size_t I, typename LatticeTuple, typename CurrentTuple,
            typename Body>
  static void for_each_combination(const LatticeTuple &lattices,
                                   CurrentTuple &current, Body &&body) {
    if constexpr (I == N) {
      body(current);
    } else {
      const auto &vec = std::get<I>(lattices);
      for (const auto &v : vec) {
        std::get<I>(current) = v;
        for_each_combination<I + 1>(lattices, current,
                                    std::forward<Body>(body));
      }
    }
  }

  // concrete Cartesian product for toBestAbst
  template <std::size_t I, typename ConcSetsTuple, typename Body>
  static void for_each_conc_combination(const ConcSetsTuple &concSets,
                                        std::array<std::uint64_t, N> &current,
                                        Body &&body) {
    if constexpr (I == N) {
      body(current);
    } else {
      const auto &vec = std::get<I>(concSets);
      for (const auto &bv : vec) {
        current[I] = bv.getZExtValue();
        for_each_conc_combination<I + 1>(concSets, current,
                                         std::forward<Body>(body));
      }
    }
  }

  static auto build_concrete_sets(const ArgsTuple &args) {
    return [&]<std::size_t... Is>(std::index_sequence<Is...>) {
      return std::tuple<std::vector<APInt<BWs>>...>{
          std::get<Is>(args).toConcrete()...};
    }(std::make_index_sequence<N>{});
  }

  static std::uint64_t capped_concrete_space(const ArgsTuple &args,
                                             std::uint64_t cap) {
    std::uint64_t product = 1;
    bool exceeded = false;

    std::apply(
        [&](auto const &...elems) {
          auto handle = [&](auto const &elem) {
            if (exceeded)
              return;

            std::uint64_t s = elem.size();

            if (s == 0) {
              s = 1;
            }

            if (product > cap / s) {
              exceeded = true;
              return;
            }

            product *= s;
          };

          (handle(elems), ...);
        },
        args);

    return exceeded ? (cap + 1) : product;
  }
};
