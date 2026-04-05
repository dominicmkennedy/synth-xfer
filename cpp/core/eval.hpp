#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <tuple>
#include <type_traits>
#include <utility>
#include <vector>

#include "domain.hpp"
#include "results.hpp"

using namespace DomainHelpers;

namespace detail {

template <std::size_t N, std::size_t Arity, std::size_t... Is>
auto xfer_fn_ptr(std::index_sequence<Is...>)
    -> std::array<std::uint64_t, Arity> (*)(
        std::conditional_t<true, std::array<std::uint64_t, Arity>,
                           std::integral_constant<std::size_t, Is>>...);

template <std::size_t N, std::size_t Arity>
using xfer_fn_t =
    decltype(xfer_fn_ptr<N, Arity>(std::make_index_sequence<N>{}));

} // namespace detail

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
std::vector<Dom<ResBw>> run_transformer(const std::uintptr_t &xfer_addr,
                                        const ArgsVec<Dom, BWs...> &to_run) {
  using ResultD = Dom<ResBw>;
  static constexpr std::size_t N = sizeof...(BWs);
  using XferFn = detail::xfer_fn_t<N, ResultD::arity>;
  using BWConstTuple = std::tuple<std::integral_constant<std::size_t, BWs>...>;
  constexpr auto idxs = std::make_index_sequence<N>{};

  XferFn xfer_fn = reinterpret_cast<XferFn>(xfer_addr);

  std::vector<ResultD> out;
  out.reserve(to_run.size());

  for (const auto &row : to_run) {
    auto packed_res = [&]<std::size_t... Is>(std::index_sequence<Is...>) {
      return xfer_fn(pack<Dom, std::tuple_element_t<Is, BWConstTuple>::value>(
          std::get<Is>(row).v)...);
    }(idxs);

    out.emplace_back(ResultD(unpack<Dom, ResBw>(packed_res)));
  }

  return out;
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
class EvalPattern {
public:
  static constexpr std::size_t num_args = sizeof...(BWs);

  using ResultD = Dom<ResBw>;
  using ArgsT = Args<Dom, BWs...>;
  using XferFn = detail::xfer_fn_t<num_args, ResultD::arity>;

  struct ExactRow {
    ArgsT args;
    ResultD best;
    double weight;
  };

  struct NormRow {
    ArgsT args;
    double weight;
  };

  EvalPattern(XferFn sequential, XferFn composite)
      : sequential_xfer_(std::move(sequential)),
        composite_xfer_(std::move(composite)) {}

  [[nodiscard]] std::pair<double, double>
  eval_pattern_exact(const std::vector<ExactRow> &rows) const {
    long double total_weight = 0.0L;
    long double sequential_correct_weight = 0.0L;
    long double composite_correct_weight = 0.0L;

    for (const auto &row : rows) {
      const long double inv_weight =
          1.0L / static_cast<long double>(row.weight);
      total_weight += inv_weight;

      const auto [sequential_result, composite_result] = eval_both(row.args);

      if (sequential_result == row.best) {
        sequential_correct_weight += inv_weight;
      }
      if (composite_result == row.best) {
        composite_correct_weight += inv_weight;
      }
    }

    if (total_weight == 0.0L) {
      return {0.0, 0.0};
    }

    return {
        static_cast<double>(100.0L * sequential_correct_weight / total_weight),
        static_cast<double>(100.0L * composite_correct_weight / total_weight),
    };
  }

  [[nodiscard]] std::pair<double, double>
  eval_pattern_norm(const std::vector<NormRow> &rows) const {
    long double total_weight = 0.0L;
    long double sequential_norm_weight = 0.0L;
    long double composite_norm_weight = 0.0L;

    for (const auto &row : rows) {
      const long double inv_weight =
          1.0L / static_cast<long double>(row.weight);
      total_weight += inv_weight;

      const auto [sequential_result, composite_result] = eval_both(row.args);

      sequential_norm_weight +=
          static_cast<long double>(sequential_result.norm()) * inv_weight;

      composite_norm_weight +=
          static_cast<long double>(composite_result.norm()) * inv_weight;
    }

    if (total_weight == 0.0L) {
      return {0.0, 0.0};
    }

    return {
        static_cast<double>(sequential_norm_weight / total_weight),
        static_cast<double>(composite_norm_weight / total_weight),
    };
  }

private:
  [[nodiscard]] static ResultD eval_one(const XferFn &fn, const ArgsT &args) {
    return [&]<std::size_t... Is>(std::index_sequence<Is...>) -> ResultD {
      return ResultD(
          unpack<Dom, ResBw>(fn(pack<Dom, BWs>(std::get<Is>(args).v)...)));
    }(std::make_index_sequence<num_args>{});
  }

  [[nodiscard]] std::pair<ResultD, ResultD> eval_both(const ArgsT &args) const {
    return {
        eval_one(sequential_xfer_, args),
        eval_one(composite_xfer_, args),
    };
  }

  XferFn sequential_xfer_;
  XferFn composite_xfer_;
};

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
class Eval {
public:
  static constexpr std::size_t N = sizeof...(BWs);

  using ResultD = Dom<ResBw>;
  static constexpr std::size_t arity = ResultD::arity;

  using ArgsTuple = std::tuple<Dom<BWs>...>;
  using Row = std::tuple<Args<Dom, BWs...>, ResultD>;
  using XferFn = detail::xfer_fn_t<N, arity>;

private:
  std::vector<XferFn> xfrFns;
  std::vector<XferFn> refFns;
  unsigned int maxUnsoundExamples;
  unsigned int maxImpreciseExamples;

public:
  constexpr Eval(const std::vector<std::uintptr_t> &xfrAddrs,
                 const std::vector<std::uintptr_t> &refAddrs,
                 unsigned int maxUnsound = 0, unsigned int maxImprecise = 0)
      : xfrFns(xfrAddrs.size(), nullptr), refFns(refAddrs.size(), nullptr),
        maxUnsoundExamples(maxUnsound), maxImpreciseExamples(maxImprecise) {
    for (std::size_t i = 0; i < xfrFns.size(); ++i)
      xfrFns[i] = reinterpret_cast<XferFn>(xfrAddrs[i]);
    for (std::size_t i = 0; i < refFns.size(); ++i)
      refFns[i] = reinterpret_cast<XferFn>(refAddrs[i]);
  }

  Results eval(const std::vector<Row> &to_eval) const {
    Results r{static_cast<unsigned int>(xfrFns.size()), ResBw,
              maxUnsoundExamples, maxImpreciseExamples};

    for (const Row &row : to_eval) {
      const ArgsTuple &args = std::get<0>(row);
      const ResultD &best = std::get<1>(row);
      evalSingle(args, best, r);
    }
    r.cleanExamples();
    return r;
  }

private:
  void evalSingle(const ArgsTuple &args, const ResultD &best,
                  Results &r) const {
    using BWConstTuple =
        std::tuple<std::integral_constant<std::size_t, BWs>...>;
    constexpr auto idxs = std::make_index_sequence<N>{};

    auto run_fns = [&](const std::vector<XferFn> &fns) {
      std::vector<ResultD> out;
      out.reserve(fns.size());

      for (XferFn f : fns) {
        auto packedRes = [&]<std::size_t... Is>(std::index_sequence<Is...>) {
          return f(pack<Dom, std::tuple_element_t<Is, BWConstTuple>::value>(
              std::get<Is>(args).v)...);
        }(idxs);

        out.emplace_back(ResultD(unpack<Dom, ResBw>(packedRes)));
      }

      return out;
    };

    std::vector<ResultD> synth_results = run_fns(xfrFns);
    ResultD ref = DomainHelpers::meetAll(run_fns(refFns));

    bool solved = (ref == best);
    double base_distance = dist(ref, best);

    for (unsigned int i = 0; i < synth_results.size(); ++i) {
      ResultD synth_after_meet = ref.meet(synth_results[i]);
      bool sound = DomainHelpers::isSuperset(synth_after_meet, best);
      bool exact = (synth_after_meet == best);
      double distance = dist(synth_after_meet, best);
      double sound_distance = sound ? distance : base_distance;
      // Xuanyu: Creating a CaseExample is expensive, so we passed things to
      // incResult and create it only when necessary.
      r.incResult(sound, exact, solved, sound_distance, args, synth_after_meet,
                  best, distance, i);
    }

    r.incCases(solved, base_distance);
  }
};
