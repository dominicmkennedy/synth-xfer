#pragma once

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <random>
#include <string_view>
#include <vector>

#include "apint.hpp"

// TODO rand should take latice_level as a param so we can change the dist of
// the abst vals we sample

template <template <std::size_t> class D, std::size_t BW>
concept Domain =
    std::default_initializable<D<BW>> &&
    requires(const D<BW> d, const APInt<BW> &a, std::size_t i, std::ostream &os,
             std::mt19937 &rng) {
      typename D<BW>::BV;
      requires std::same_as<typename D<BW>::BV, APInt<BW>>;

      { D<BW>::arity } -> std::convertible_to<std::size_t>;
      { D<BW>::name } -> std::convertible_to<const std::string_view>;
      requires(D<BW>::arity >= 2 && D<BW>::arity <= 6);
      { d[i] } noexcept -> std::same_as<const APInt<BW> &>;

      // Static methods
      { D<BW>::rand(rng, i) } -> std::same_as<const D<BW>>;
      { D<BW>::bottom() } noexcept -> std::same_as<const D<BW>>;
      { D<BW>::top() } noexcept -> std::same_as<const D<BW>>;
      {
        D<BW>::enumLattice()
      } noexcept -> std::same_as<const std::vector<D<BW>>>;
      { D<BW>::fromConcrete(a) } noexcept -> std::same_as<const D<BW>>;
      { D<BW>::num_levels() } noexcept -> std::same_as<std::uint64_t>;

      // Instance methods
      { d.isTop() } noexcept -> std::same_as<bool>;
      { d.isBottom() } noexcept -> std::same_as<bool>;
      { d.meet(d) } noexcept -> std::same_as<const D<BW>>;
      { d.join(d) } noexcept -> std::same_as<const D<BW>>;
      { d.toConcrete() } noexcept -> std::same_as<const std::vector<APInt<BW>>>;
      { d.distance(d) } noexcept -> std::same_as<std::uint64_t>;
      { d.size() } noexcept -> std::same_as<std::uint64_t>;
      { d.sample_concrete(rng) } -> std::same_as<const APInt<BW>>;
      { os << d } -> std::same_as<std::ostream &>;
    } &&
    std::constructible_from<D<BW>, const std::array<APInt<BW>, D<BW>::arity> &>;
;

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

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
using ToEval = std::vector<std::tuple<Dom<BWs>..., Dom<ResBw>>>;

// TODO specialized to arity 2 domains
template <std::size_t BW>
inline const constexpr std::array<std::uint64_t, 2>
pack(const std::array<APInt<BW>, 2> &arr) {
  return std::array<std::uint64_t, 2>{arr[0].getZExtValue(),
                                      arr[1].getZExtValue()};
}

// TODO specialized to arity 2 domains
template <std::size_t BW>
inline const constexpr std::array<APInt<BW>, 2>
unpack(const std::array<std::uint64_t, 2> &value) {
  return {APInt<BW>{value[0]}, APInt<BW>{value[1]}};
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
