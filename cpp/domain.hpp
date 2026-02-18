#pragma once

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <random>
#include <string_view>
#include <vector>

#include "apint.hpp"

template <template <std::size_t> class D, std::size_t BW>
concept Domain =
    std::default_initializable<D<BW>> && requires { typename D<BW>::BV; } &&
    requires(const D<BW> d, const APInt<BW> &a, std::size_t i, std::ostream &os,
             std::mt19937 &rng, const typename D<BW>::BV &bv) {
      { bv.getZExtValue() } -> std::convertible_to<std::uint64_t>;

      // Static metadata
      { D<BW>::arity } -> std::convertible_to<std::size_t>;
      { D<BW>::name } -> std::convertible_to<std::string_view>;
      requires(D<BW>::arity >= 1 && D<BW>::arity <= 6);

      // Component access
      { d[i] } noexcept -> std::same_as<const typename D<BW>::BV &>;

      // Static constructors / enumerations
      { D<BW>::rand(rng, i) } -> std::same_as<D<BW>>;
      { D<BW>::bottom() } noexcept -> std::same_as<D<BW>>;
      { D<BW>::top() } noexcept -> std::same_as<D<BW>>;
      { D<BW>::enumLattice() } -> std::same_as<std::vector<D<BW>>>;
      { D<BW>::fromConcrete(a) } noexcept -> std::same_as<D<BW>>;
      { D<BW>::num_levels() } noexcept -> std::same_as<std::uint64_t>;
      { D<BW>::parse(std::string_view{}) } -> std::same_as<D<BW>>;

      // Instance methods
      { d.isTop() } noexcept -> std::same_as<bool>;
      { d.isBottom() } noexcept -> std::same_as<bool>;
      { d.meet(d) } noexcept -> std::same_as<D<BW>>;
      { d.join(d) } noexcept -> std::same_as<D<BW>>;
      { d.toConcrete() } -> std::same_as<std::vector<APInt<BW>>>;
      { d.distance(d) } noexcept -> std::same_as<std::uint64_t>;
      { d.size() } noexcept -> std::same_as<std::uint64_t>;
      { d.sample_concrete(rng) } -> std::same_as<APInt<BW>>;

      { os << d } -> std::same_as<std::ostream &>;
    } &&
    std::constructible_from<D<BW>, const std::array<APInt<BW>, D<BW>::arity> &>;

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
constexpr bool operator==(const D<BW> &lhs, const D<BW> &rhs) {
  for (std::size_t i = 0; i < D<BW>::arity; ++i)
    if (!(lhs[i] == rhs[i]))
      return false;

  return true;
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
constexpr bool operator!=(const D<BW> &lhs, const D<BW> &rhs) {
  return !(lhs == rhs);
}

namespace DomainHelpers {

template <template <std::size_t> class Dom, std::size_t... BWs>
  requires(Domain<Dom, BWs> && ...)
using Args = std::tuple<Dom<BWs>...>;

template <template <std::size_t> class Dom, std::size_t... BWs>
  requires(Domain<Dom, BWs> && ...)
using ArgsVec = std::vector<Args<Dom, BWs...>>;

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
using ToEval = std::vector<std::tuple<Args<Dom, BWs...>, Dom<ResBw>>>;

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
constexpr std::array<APInt<BW>, D<BW>::arity>
unpack(const std::array<std::uint64_t, D<BW>::arity> &value) {
  constexpr std::size_t N = D<BW>::arity;

  return [&]<std::size_t... Is>(std::index_sequence<Is...>) {
    return std::array<APInt<BW>, N>{APInt<BW>{value[Is]}...};
  }(std::make_index_sequence<N>{});
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
constexpr std::array<std::uint64_t, D<BW>::arity>
pack(const std::array<typename D<BW>::BV, D<BW>::arity> &arr) {
  constexpr std::size_t N = D<BW>::arity;

  return [&]<std::size_t... Is>(std::index_sequence<Is...>) {
    return std::array<std::uint64_t, N>{
        static_cast<std::uint64_t>(arr[Is].getZExtValue())...};
  }(std::make_index_sequence<N>{});
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
bool constexpr isSuperset(const D<BW> &lhs, const D<BW> &rhs) {
  return lhs.meet(rhs) == rhs;
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
const D<BW> constexpr joinAll(const std::vector<D<BW>> &v) {
  if (v.empty())
    return D<BW>::bottom();

  D<BW> d = v[0];
  for (std::size_t i = 1; i < v.size(); ++i) {
    d = d.join(v[i]);
  }

  return d;
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
const D<BW> constexpr meetAll(const std::vector<D<BW>> &v) {
  if (v.empty())
    return D<BW>::top();

  D<BW> d = v[0];
  for (unsigned int i = 1; i < v.size(); ++i) {
    d = d.meet(v[i]);
  }

  return d;
}
} // namespace DomainHelpers
