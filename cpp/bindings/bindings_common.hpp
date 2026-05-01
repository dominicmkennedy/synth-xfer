#pragma once

#include <algorithm>
#include <cstdint>
#include <memory>
#include <optional>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include "domain.hpp"
#include "enum.hpp"
#include "eval.hpp"
#include "rand.hpp"
#include "results.hpp"

namespace py = pybind11;
using DomainHelpers::ArgsVec;
using DomainHelpers::ToEval;

template <std::size_t BW> class KnownBits;
template <std::size_t BW> class UConstRange;
template <std::size_t BW> class SConstRange;

template <template <std::size_t> class Dom>
struct supports_llvm_pattern_domain : std::false_type {};

template <> struct supports_llvm_pattern_domain<KnownBits> : std::true_type {};
template <> struct supports_llvm_pattern_domain<UConstRange> : std::true_type {};
template <> struct supports_llvm_pattern_domain<SConstRange> : std::true_type {};

void register_rng(py::module_ &m);
void register_results_class(py::module_ &m);

void register_knownbits_bindings(py::module_ &m);
void register_uconst_range_bindings(py::module_ &m);
void register_sconst_range_bindings(py::module_ &m);
void register_mod3_bindings(py::module_ &m);
void register_mod5_bindings(py::module_ &m);
void register_mod7_bindings(py::module_ &m);
void register_mod11_bindings(py::module_ &m);
void register_mod13_bindings(py::module_ &m);

struct ParsedEnumRow {
  std::vector<std::string> args;
  std::string ret;
};

std::vector<ParsedEnumRow> parse_enum_rows(py::sequence rows,
                                           std::size_t arity);
std::vector<std::vector<py::object>> parse_run_rows(py::sequence rows,
                                                    std::size_t arity);
std::string to_lower_ascii(std::string s);

using EnumLowThunk = py::object (*)(std::uintptr_t,
                                    std::optional<std::uintptr_t>);
using EnumMidThunk = py::object (*)(std::uintptr_t,
                                    std::optional<std::uintptr_t>, unsigned int,
                                    unsigned int,
                                    std::shared_ptr<rngdist::Sampler>);
using EnumHighThunk = py::object (*)(std::uintptr_t,
                                     std::optional<std::uintptr_t>,
                                     unsigned int, unsigned int, unsigned int,
                                     std::shared_ptr<rngdist::Sampler>);
using EvalThunk = Results (*)(py::handle, const std::vector<std::uintptr_t> &,
                              const std::vector<std::uintptr_t> &, unsigned int,
                              unsigned int);
using EvalPatternThunk = std::pair<double, double> (*)(py::handle,
                                                       const std::vector<double> &,
                                                       const std::string &,
                                                       std::uintptr_t);
using RunThunk = py::object (*)(py::handle, std::uintptr_t);
using LenThunk = std::size_t (*)(py::handle);
using GetItemThunk = py::object (*)(py::handle, std::size_t);
using IterThunk = py::object (*)(py::handle);

void bind_enum_funcs(py::module_ &m, const std::string &fn_name,
                     EnumLowThunk low, EnumMidThunk mid, EnumHighThunk high);
void bind_eval_func(py::module_ &m, const std::string &fn_name, EvalThunk eval);
void bind_eval_pattern_func(py::module_ &m, const std::string &fn_name,
                            EvalPatternThunk eval);
void bind_run_func(py::module_ &m, const std::string &fn_name, RunThunk run);
template <typename PyClass>
void bind_sequence_protocol(PyClass &cls, LenThunk len, GetItemThunk getitem,
                            IterThunk iter) {
  cls.def("__len__", [len](py::handle self) { return len(self); });
  cls.def("__getitem__", [getitem](py::handle self, std::size_t i) {
    return getitem(self, i);
  });
  cls.def(
      "__iter__", [iter](py::handle self) { return iter(self); },
      py::keep_alive<0, 1>());
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
void register_domain_class(py::module_ &m) {
  const std::string cls_name = std::string(D<BW>::name) + std::to_string(BW);

  auto cls = py::class_<D<BW>>(m, cls_name.c_str());
  cls.def_static("arity", []() { return D<BW>::arity; });
  cls.def_static("bw", []() { return BW; });
  cls.def_static("top", []() { return D<BW>::top(); });
  cls.def_static("bottom", []() { return D<BW>::bottom(); });
  cls.def(py::init([](const std::string &s) { return D<BW>::parse(s); }));
  cls.def("norm", [](const D<BW> &self) { return self.norm(); });
  cls.def(
      "dist",
      [](const D<BW> &self, const D<BW> &rhs) { return dist(self, rhs); },
      py::arg("rhs"));
  cls.def("__eq__",
          [](const D<BW> &self, const D<BW> &rhs) { return self == rhs; });
  cls.def("__ne__",
          [](const D<BW> &self, const D<BW> &rhs) { return self != rhs; });
  cls.def("__str__", [](const D<BW> &self) {
    std::ostringstream oss;
    oss << self;
    std::string s = oss.str();
    s.pop_back();
    return s;
  });
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_enum_domain(py::module_ &m) {
  using EvalVec = ToEval<Dom, ResBw, BWs...>;
  using ArgsTuple = std::tuple<Dom<BWs>...>;
  using Row = std::tuple<ArgsTuple, Dom<ResBw>>;
  using EnumT = EnumDomain<Dom, ResBw, BWs...>;

  std::string dname = std::string(Dom<ResBw>::name);
  std::string cls_name =
      std::string("ToEval") + dname + "_" + std::to_string(ResBw);
  ((cls_name += "_" + std::to_string(BWs)), ...);

  constexpr std::size_t Arity = sizeof...(BWs);

  auto cls = py::class_<EvalVec>(m, cls_name.c_str());
  cls.def(py::init([](py::sequence rows) {
    const auto parsed = parse_enum_rows(rows, Arity);
    auto v = std::make_unique<EvalVec>();
    v->reserve(parsed.size());

    for (const auto &row : parsed) {
      auto tup = [&]<std::size_t... Is>(std::index_sequence<Is...>) {
        ArgsTuple args_tuple{Dom<BWs>::parse(row.args[Is])...};
        return Row{std::move(args_tuple), Dom<ResBw>::parse(row.ret)};
      }(std::make_index_sequence<Arity>{});

      v->emplace_back(std::move(tup));
    }

    return v;
  }));

  bind_sequence_protocol(
      cls,
      +[](py::handle self) -> std::size_t {
        return py::cast<const EvalVec &>(self).size();
      },
      +[](py::handle self, std::size_t i) -> py::object {
        const EvalVec &v = py::cast<const EvalVec &>(self);
        if (i >= v.size()) {
          throw py::index_error();
        }
        return py::cast(v[i], py::return_value_policy::reference_internal,
                        self);
      },
      +[](py::handle self) -> py::object {
        const EvalVec &v = py::cast<const EvalVec &>(self);
        return py::make_iterator(v.begin(), v.end());
      });

  dname = to_lower_ascii(std::move(dname));

  std::string fn_name = dname + "_" + std::to_string(ResBw);
  ((fn_name += "_" + std::to_string(BWs)), ...);

  bind_enum_funcs(
      m, fn_name,
      +[](std::uintptr_t crtOpAddr,
          std::optional<std::uintptr_t> opConFnAddr) -> py::object {
        auto out = std::make_unique<EvalVec>();
        {
          py::gil_scoped_release release;
          EnumT ed{crtOpAddr, opConFnAddr};
          *out = ed.genLows();
        }
        return py::cast(std::move(out),
                        py::return_value_policy::take_ownership);
      },
      +[](std::uintptr_t crtOpAddr, std::optional<std::uintptr_t> opConFnAddr,
          unsigned int num_lat_samples, unsigned int seed,
          std::shared_ptr<rngdist::Sampler> sampler) -> py::object {
        auto out = std::make_unique<EvalVec>();
        {
          py::gil_scoped_release release;
          std::mt19937 rng(seed);
          EnumT ed{crtOpAddr, opConFnAddr};
          *out = ed.genMids(num_lat_samples, rng, *sampler);
        }
        return py::cast(std::move(out),
                        py::return_value_policy::take_ownership);
      },
      +[](std::uintptr_t crtOpAddr, std::optional<std::uintptr_t> opConFnAddr,
          unsigned int num_lat_samples, unsigned int num_conc_samples,
          unsigned int seed,
          std::shared_ptr<rngdist::Sampler> sampler) -> py::object {
        auto out = std::make_unique<EvalVec>();
        {
          py::gil_scoped_release release;
          std::mt19937 rng(seed);
          EnumT ed{crtOpAddr, opConFnAddr};
          *out = ed.genHighs(num_lat_samples, num_conc_samples, rng, *sampler);
        }
        return py::cast(std::move(out),
                        py::return_value_policy::take_ownership);
      });
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_eval_domain(py::module_ &m) {
  using EvalVec = ToEval<Dom, ResBw, BWs...>;
  using EvalT = Eval<Dom, ResBw, BWs...>;

  std::string dname = std::string(Dom<ResBw>::name);
  std::string dname_lower = to_lower_ascii(std::move(dname));

  std::string fn_name = "eval_" + dname_lower + "_" + std::to_string(ResBw);
  ((fn_name += "_" + std::to_string(BWs)), ...);

  bind_eval_func(
      m, fn_name,
      +[](py::handle to_eval, const std::vector<std::uintptr_t> &xfers,
          const std::vector<std::uintptr_t> &bases, unsigned int unsound_ex,
          unsigned int imprecise_ex) -> Results {
        const EvalVec &v = py::cast<const EvalVec &>(to_eval);
        py::gil_scoped_release release;
        return EvalT{xfers, bases, unsound_ex, imprecise_ex}.eval(v);
      });
}

template <typename EvalPatternT, typename EvalVec>
std::vector<typename EvalPatternT::ExactRow>
make_exact_pattern_rows(const EvalVec &to_eval,
                        const std::vector<double> &weights) {
  if (to_eval.size() != weights.size()) {
    throw py::value_error("weights length must match to_eval");
  }

  std::vector<typename EvalPatternT::ExactRow> out;
  out.reserve(to_eval.size());
  for (std::size_t i = 0; i < to_eval.size(); ++i) {
    const auto &[args, best] = to_eval[i];
    out.push_back({args, best, weights[i]});
  }
  return out;
}

template <typename EvalPatternT, typename RunVec>
std::vector<typename EvalPatternT::NormRow>
make_norm_pattern_rows(const RunVec &to_run,
                       const std::vector<double> &weights) {
  if (to_run.size() != weights.size()) {
    throw py::value_error("weights length must match to_run");
  }

  std::vector<typename EvalPatternT::NormRow> out;
  out.reserve(to_run.size());
  for (std::size_t i = 0; i < to_run.size(); ++i) {
    out.push_back({to_run[i], weights[i]});
  }
  return out;
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_eval_pattern_domain(py::module_ &m) {
  using EvalVec = ToEval<Dom, ResBw, BWs...>;
  using RunVec = ArgsVec<Dom, BWs...>;
  using EvalPatternT = EvalPattern<Dom, ResBw, BWs...>;

  std::string dname = std::string(Dom<ResBw>::name);
  std::string dname_lower = to_lower_ascii(std::move(dname));

  std::string exact_fn_name =
      "eval_pattern_exact_" + dname_lower + "_" + std::to_string(ResBw);
  std::string norm_fn_name = "eval_pattern_norm_" + dname_lower;
  ((exact_fn_name += "_" + std::to_string(BWs)), ...);
  ((norm_fn_name += "_" + std::to_string(BWs)), ...);

  bind_eval_pattern_func(
      m, exact_fn_name,
      +[](py::handle to_eval, const std::vector<double> &weights,
          const std::string &pattern,
          std::uintptr_t composite_addr) -> std::pair<double, double> {
        const EvalVec &v = py::cast<const EvalVec &>(to_eval);
        auto exact_rows = make_exact_pattern_rows<EvalPatternT>(v, weights);
        py::gil_scoped_release release;
        return EvalPatternT{
            reinterpret_cast<typename EvalPatternT::XferFn>(composite_addr),
            pattern}
            .eval_pattern_exact(exact_rows);
      });

  bind_eval_pattern_func(
      m, norm_fn_name,
      +[](py::handle to_run, const std::vector<double> &weights,
          const std::string &pattern,
          std::uintptr_t composite_addr) -> std::pair<double, double> {
        const RunVec &v = py::cast<const RunVec &>(to_run);
        auto norm_rows = make_norm_pattern_rows<EvalPatternT>(v, weights);
        py::gil_scoped_release release;
        return EvalPatternT{
            reinterpret_cast<typename EvalPatternT::XferFn>(composite_addr),
            pattern}
            .eval_pattern_norm(norm_rows);
      });
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_run_domain(py::module_ &m) {
  using RunVec = ArgsVec<Dom, BWs...>;

  std::string dname = std::string(Dom<ResBw>::name);
  std::string cls_name = std::string("Args") + dname;
  ((cls_name += "_" + std::to_string(BWs)), ...);

  constexpr std::size_t Arity = sizeof...(BWs);

  auto cls = py::class_<RunVec>(m, cls_name.c_str());
  cls.def(py::init([](py::sequence rows) {
    const auto parsed = parse_run_rows(rows, Arity);
    auto v = std::make_unique<RunVec>();
    v->reserve(parsed.size());

    for (const auto &row : parsed) {
      auto tup = [&]<std::size_t... Is>(std::index_sequence<Is...>) {
        return std::tuple<Dom<BWs>...>{
            (py::isinstance<py::str>(row[Is])
                 ? Dom<BWs>::parse(py::cast<std::string>(row[Is]))
                 : py::cast<Dom<BWs>>(row[Is]))...};
      }(std::make_index_sequence<Arity>{});

      v->emplace_back(std::move(tup));
    }

    return v;
  }));

  bind_sequence_protocol(
      cls,
      +[](py::handle self) -> std::size_t {
        return py::cast<const RunVec &>(self).size();
      },
      +[](py::handle self, std::size_t i) -> py::object {
        const RunVec &v = py::cast<const RunVec &>(self);
        if (i >= v.size()) {
          throw py::index_error();
        }
        return py::cast(v[i], py::return_value_policy::reference_internal,
                        self);
      },
      +[](py::handle self) -> py::object {
        const RunVec &v = py::cast<const RunVec &>(self);
        return py::make_iterator(v.begin(), v.end());
      });

  std::string dname_lower = dname;
  dname_lower = to_lower_ascii(std::move(dname_lower));

  std::string fn_name =
      "run_transformer_" + dname_lower + "_" + std::to_string(ResBw);
  ((fn_name += "_" + std::to_string(BWs)), ...);

  bind_run_func(
      m, fn_name,
      +[](py::handle to_run, std::uintptr_t xfer_addr) -> py::object {
        const RunVec &v = py::cast<const RunVec &>(to_run);
        decltype(run_transformer<Dom, ResBw, BWs...>(xfer_addr, v)) out;
        {
          py::gil_scoped_release release;
          out = run_transformer<Dom, ResBw, BWs...>(xfer_addr, v);
        }
        return py::cast(std::move(out));
      });
}

template <template <std::size_t> class Dom, std::size_t BW, std::size_t N>
  requires Domain<Dom, BW>
void register_uniform_arity(py::module_ &m) {
  [&]<std::size_t... Is>(std::index_sequence<Is...>) {
    (void)sizeof...(Is);

    register_enum_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
    register_eval_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
    if constexpr (supports_llvm_pattern_domain<Dom>::value) {
      register_eval_pattern_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
    }
    register_run_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
  }(std::make_index_sequence<N>{});
}

template <template <std::size_t> class Dom, std::size_t BW>
  requires Domain<Dom, BW>
void register_domain(py::module_ &m) {
  register_domain_class<Dom, BW>(m);
#include "build_matrix_arities.inc"
}

template <template <std::size_t> class Dom, std::size_t... BWs>
void register_domain_widths(py::module_ &m) {
  (register_domain<Dom, BWs>(m), ...);
}

#define MAKE_OPAQUE_UNIFORM(DOM, BW)                                           \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ToEval<DOM, BW, BW>);                    \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ToEval<DOM, BW, BW, BW>);                \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ToEval<DOM, BW, BW, BW, BW>);            \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ToEval<DOM, BW, BW, BW, BW, BW>);        \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ArgsVec<DOM, BW>);                       \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ArgsVec<DOM, BW, BW>);                   \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ArgsVec<DOM, BW, BW, BW>);               \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ArgsVec<DOM, BW, BW, BW, BW>);           \
  PYBIND11_MAKE_OPAQUE(DomainHelpers::ArgsVec<DOM, BW, BW, BW, BW, BW>);
