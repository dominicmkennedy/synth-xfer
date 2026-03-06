#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <sstream>
#include <string>
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
class Eval {
public:
  static constexpr std::size_t N = sizeof...(BWs);

  using ResultD = Dom<ResBw>;
  static constexpr std::size_t arity = ResultD::arity;

  using ArgsTuple = std::tuple<Dom<BWs>...>;
  using Row = std::tuple<Args<Dom, BWs...>, ResultD>;
  using EvalVec = ToEval<Dom, ResBw, BWs...>;
  using XferFn = detail::xfer_fn_t<N, arity>;

private:
  std::vector<XferFn> xfrFns;
  std::vector<XferFn> refFns;
  unsigned int maxUnsoundExamples;
  unsigned int maxImpreciseExamples;

  template <typename T> static std::string toText(const T &value) {
    std::ostringstream oss;
    oss << value;
    std::string result = oss.str();
    // Remove trailing newline if present
    if (!result.empty() && result.back() == '\n') {
      result.pop_back();
    }
    return result;
  }

  static std::vector<std::string> argsToText(const ArgsTuple &args) {
    std::vector<std::string> out;
    out.reserve(N);

    std::apply(
        [&](const auto &...parts) {
          (out.push_back(toText(parts)), ...);
        },
        args);

    return out;
  }

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

  Results eval(const EvalVec &toEval) const {
    Results r{static_cast<unsigned int>(xfrFns.size()), ResBw,
              ResultD::num_levels, maxUnsoundExamples, maxImpreciseExamples};

    for (const Row &row : toEval) {
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
    unsigned long baseDis = ref.distance(best);

    for (unsigned int i = 0; i < synth_results.size(); ++i) {
      ResultD synth_after_meet = ref.meet(synth_results[i]);
      bool sound = DomainHelpers::isSuperset(synth_after_meet, best);
      bool exact = (synth_after_meet == best);
      unsigned long dis = synth_after_meet.distance(best);
      unsigned long soundDis = sound ? dis : baseDis;

      CaseExample example(argsToText(args), toText(synth_after_meet),
                          toText(best), static_cast<double>(dis));

      r.incResult(sound, dis, exact, solved, soundDis, example, i);
    }

    r.incCases(solved, baseDis);
  }
};
