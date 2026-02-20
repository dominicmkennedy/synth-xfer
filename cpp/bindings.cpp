#include <cstdint>
#include <optional>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include "domain.hpp"
#include "enum.hpp"
#include "eval.hpp"
#include "knownbits.hpp"
#include "mod.hpp"
#include "rand.hpp"
#include "results.hpp"
#include "sconst_range.hpp"
#include "uconst_range.hpp"

namespace py = pybind11;
using DomainHelpers::Args;
using DomainHelpers::ArgsVec;
using DomainHelpers::ToEval;

void register_rng(py::module_ &m) {
  using SamplerPtr = std::shared_ptr<rngdist::Sampler>;

  py::class_<rngdist::Sampler, SamplerPtr>(m, "Sampler", py::module_local())
      .def("__str__", [](const rngdist::Sampler &) { return "<Sampler>"; });

  m.def("uniform_sampler", []() -> SamplerPtr {
    return std::make_shared<rngdist::UniformSampler>();
  });

  m.def(
      "normal_sampler",
      [](double sigma) -> SamplerPtr {
        return std::make_shared<rngdist::NormalSampler>(sigma);
      },
      py::arg("sigma"));

  m.def(
      "skew_left_sampler",
      [](double sigma, double alpha) -> SamplerPtr {
        return std::make_shared<rngdist::SkewNormalLeftSampler>(sigma, alpha);
      },
      py::arg("sigma"), py::arg("alpha"));

  m.def(
      "skew_right_sampler",
      [](double sigma, double alpha) -> SamplerPtr {
        return std::make_shared<rngdist::SkewNormalRightSampler>(sigma, alpha);
      },
      py::arg("sigma"), py::arg("alpha"));

  m.def(
      "bimodal_sampler",
      [](double sigma, double separation) -> SamplerPtr {
        return std::make_shared<rngdist::BimodalSymmetricSampler>(sigma,
                                                                  separation);
      },
      py::arg("sigma"), py::arg("separation"));
}

// TODO integrate this class more tightly with PerBitRes
void register_results_class(py::module_ &m) {
  auto cls = py::class_<Results>(m, "Results");

  cls.def("__str__", [](const Results &self) {
    std::ostringstream oss;
    oss << self;
    std::string s = oss.str();
    s.pop_back();
    return s;
  });
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
  cls.def("size", [](const D<BW> &self) { return self.size(); });
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

  py::class_<EvalVec>(m, cls_name.c_str())
      .def(py::init([](py::sequence rows) {
        auto v = std::make_unique<EvalVec>();
        v->reserve(py::len(rows));

        for (py::handle row_h : rows) {
          if (!py::isinstance<py::tuple>(row_h)) {
            throw py::value_error("row must be a tuple");
          }
          py::tuple row = py::reinterpret_borrow<py::tuple>(row_h);
          if (row.size() != 2) {
            throw py::value_error("row must be (args, ret)");
          }

          if (!py::isinstance<py::tuple>(row[0])) {
            throw py::value_error("args must be a tuple");
          }
          py::tuple args = py::reinterpret_borrow<py::tuple>(row[0]);
          if (args.size() != Arity) {
            throw py::value_error("args tuple has wrong arity");
          }

          if (!py::isinstance<py::str>(row[1])) {
            throw py::value_error("ret must be a string");
          }
          const std::string ret_s = py::cast<std::string>(row[1]);

          auto tup = [&]<std::size_t... Is>(std::index_sequence<Is...>) {
            ArgsTuple args_tuple{
                Dom<BWs>::parse(py::cast<std::string>(args[Is]))...};
            return Row{std::move(args_tuple), Dom<ResBw>::parse(ret_s)};
          }(std::make_index_sequence<Arity>{});

          v->emplace_back(std::move(tup));
        }

        return v;
      }))
      .def("__len__", [](const EvalVec &v) { return v.size(); })
      .def(
          "__getitem__",
          [](const EvalVec &v, std::size_t i) -> const Row & {
            if (i >= v.size())
              throw py::index_error();
            return v[i];
          },
          py::return_value_policy::reference_internal)
      .def(
          "__iter__",
          [](const EvalVec &v) {
            return py::make_iterator(v.begin(), v.end());
          },
          py::keep_alive<0, 1>());

  std::transform(dname.begin(), dname.end(), dname.begin(), ::tolower);

  std::string fn_name = dname + "_" + std::to_string(ResBw);
  ((fn_name += "_" + std::to_string(BWs)), ...);

  m.def(
      ("enum_low_" + fn_name).c_str(),
      [](std::uintptr_t crtOpAddr, std::optional<std::uintptr_t> opConFnAddr) {
        py::gil_scoped_release release;
        EnumT ed{crtOpAddr, opConFnAddr};
        return std::make_unique<EvalVec>(ed.genLows());
      },
      py::arg("crtOpAddr"), py::arg("opConFnAddr"),
      py::return_value_policy::take_ownership);

  using SamplerPtr = std::shared_ptr<rngdist::Sampler>;

  m.def(("enum_mid_" + fn_name).c_str(),
        [](std::uintptr_t crtOpAddr, std::optional<std::uintptr_t> opConFnAddr,
           unsigned int num_lat_samples, unsigned int seed,
           SamplerPtr sampler) {
          py::gil_scoped_release release;

          std::mt19937 rng(seed);
          EnumT ed{crtOpAddr, opConFnAddr};
          return std::make_unique<EvalVec>(
              ed.genMids(num_lat_samples, rng, *sampler));
        },
        py::arg("crtOpAddr"), py::arg("opConFnAddr"),
        py::arg("num_lat_samples"), py::arg("seed"), py::arg("sampler"),
        py::return_value_policy::take_ownership);

  m.def(("enum_high_" + fn_name).c_str(),
        [](std::uintptr_t crtOpAddr, std::optional<std::uintptr_t> opConFnAddr,
           unsigned int num_lat_samples, unsigned int num_conc_samples,
           unsigned int seed, SamplerPtr sampler) {
          py::gil_scoped_release release;

          std::mt19937 rng(seed);
          EnumT ed{crtOpAddr, opConFnAddr};
          return std::make_unique<EvalVec>(
              ed.genHighs(num_lat_samples, num_conc_samples, rng, *sampler));
        },
        py::arg("crtOpAddr"), py::arg("opConFnAddr"),
        py::arg("num_lat_samples"), py::arg("num_conc_samples"),
        py::arg("seed"), py::arg("sampler"),
        py::return_value_policy::take_ownership);
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_eval_domain(py::module_ &m) {
  using EvalVec = ToEval<Dom, ResBw, BWs...>;
  using EvalT = Eval<Dom, ResBw, BWs...>;

  std::string dname = std::string(Dom<ResBw>::name);
  std::string dname_lower = dname;
  std::transform(dname_lower.begin(), dname_lower.end(), dname_lower.begin(),
                 ::tolower);

  std::string fn_name = "eval_" + dname_lower + "_" + std::to_string(ResBw);
  ((fn_name += "_" + std::to_string(BWs)), ...);

  m.def(
      fn_name.c_str(),
      [](const EvalVec &v, const std::vector<std::uintptr_t> &xfers,
         const std::vector<std::uintptr_t> &bases) -> Results {
        py::gil_scoped_release release;
        return EvalT{xfers, bases}.eval(v);
      },
      py::arg("to_eval"), py::arg("xfers"), py::arg("bases"));
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_run_domain(py::module_ &m) {
  using RunVec = ArgsVec<Dom, BWs...>;
  using Row = std::tuple<Dom<BWs>...>;

  std::string dname = std::string(Dom<ResBw>::name);
  std::string cls_name = std::string("Args") + dname;
  ((cls_name += "_" + std::to_string(BWs)), ...);

  constexpr std::size_t Arity = sizeof...(BWs);

  py::class_<RunVec>(m, cls_name.c_str())
      .def(py::init([](py::sequence rows) {
        auto v = std::make_unique<RunVec>();
        v->reserve(py::len(rows));

        for (py::handle row_h : rows) {
          if (!py::isinstance<py::tuple>(row_h)) {
            throw py::value_error("row must be a tuple");
          }
          py::tuple row = py::reinterpret_borrow<py::tuple>(row_h);
          if (row.size() != Arity) {
            throw py::value_error("row has wrong arity");
          }

          auto tup = [&]<std::size_t... Is>(std::index_sequence<Is...>) {
            return std::tuple<Dom<BWs>...>{
                (py::isinstance<py::str>(row[Is])
                     ? Dom<BWs>::parse(py::cast<std::string>(row[Is]))
                     : py::cast<Dom<BWs>>(row[Is]))...};
          }(std::make_index_sequence<Arity>{});

          v->emplace_back(std::move(tup));
        }

        return v;
      }))
      .def("__len__", [](const RunVec &v) { return v.size(); })
      .def(
          "__getitem__",
          [](const RunVec &v, std::size_t i) -> const Row & {
            if (i >= v.size())
              throw py::index_error();
            return v[i];
          },
          py::return_value_policy::reference_internal)
      .def(
          "__iter__",
          [](const RunVec &v) {
            return py::make_iterator(v.begin(), v.end());
          },
          py::keep_alive<0, 1>());

  std::string dname_lower = dname;
  std::transform(dname_lower.begin(), dname_lower.end(), dname_lower.begin(),
                 ::tolower);

  std::string fn_name =
      "run_transformer_" + dname_lower + "_" + std::to_string(ResBw);
  ((fn_name += "_" + std::to_string(BWs)), ...);

  m.def(
      fn_name.c_str(),
      [](const RunVec &v, std::uintptr_t xfer_addr) {
        py::gil_scoped_release release;
        return run_transformer<Dom, ResBw, BWs...>(xfer_addr, v);
      },
      py::arg("to_run"), py::arg("xfer_addr"));
}

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_enum_domain(py::module_ &m);

template <template <std::size_t> class Dom, std::size_t ResBw,
          std::size_t... BWs>
  requires(Domain<Dom, ResBw> && (Domain<Dom, BWs> && ...))
void register_eval_domain(py::module_ &m);

template <template <std::size_t> class Dom, std::size_t BW, std::size_t N>
  requires Domain<Dom, BW>
void register_uniform_arity(py::module_ &m) {
  [&]<std::size_t... Is>(std::index_sequence<Is...>) {
    (void)sizeof...(Is); // silence warning if needed

    register_enum_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
    register_eval_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
    register_run_domain<Dom, BW, (static_cast<void>(Is), BW)...>(m);
  }(std::make_index_sequence<N>{});
}

template <template <std::size_t> class Dom, std::size_t BW>
  requires Domain<Dom, BW>
void register_domain(py::module_ &m) {
  register_domain_class<Dom, BW>(m);

  register_uniform_arity<Dom, BW, 1>(m);
  register_uniform_arity<Dom, BW, 2>(m);
  register_uniform_arity<Dom, BW, 3>(m);
  register_uniform_arity<Dom, BW, 4>(m);
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

// Register domain classes here
MAKE_OPAQUE_UNIFORM(KnownBits, 4);
MAKE_OPAQUE_UNIFORM(KnownBits, 8);
MAKE_OPAQUE_UNIFORM(KnownBits, 16);
MAKE_OPAQUE_UNIFORM(KnownBits, 32);
MAKE_OPAQUE_UNIFORM(KnownBits, 64);

MAKE_OPAQUE_UNIFORM(UConstRange, 4);
MAKE_OPAQUE_UNIFORM(UConstRange, 8);
MAKE_OPAQUE_UNIFORM(UConstRange, 16);
MAKE_OPAQUE_UNIFORM(UConstRange, 32);
MAKE_OPAQUE_UNIFORM(UConstRange, 64);

MAKE_OPAQUE_UNIFORM(SConstRange, 4);
MAKE_OPAQUE_UNIFORM(SConstRange, 8);
MAKE_OPAQUE_UNIFORM(SConstRange, 16);
MAKE_OPAQUE_UNIFORM(SConstRange, 32);
MAKE_OPAQUE_UNIFORM(SConstRange, 64);

MAKE_OPAQUE_UNIFORM(Mod3, 4);
MAKE_OPAQUE_UNIFORM(Mod3, 8);
MAKE_OPAQUE_UNIFORM(Mod3, 16);
MAKE_OPAQUE_UNIFORM(Mod3, 32);
MAKE_OPAQUE_UNIFORM(Mod3, 64);

MAKE_OPAQUE_UNIFORM(Mod5, 4);
MAKE_OPAQUE_UNIFORM(Mod5, 8);
MAKE_OPAQUE_UNIFORM(Mod5, 16);
MAKE_OPAQUE_UNIFORM(Mod5, 32);
MAKE_OPAQUE_UNIFORM(Mod5, 64);

MAKE_OPAQUE_UNIFORM(Mod7, 4);
MAKE_OPAQUE_UNIFORM(Mod7, 8);
MAKE_OPAQUE_UNIFORM(Mod7, 16);
MAKE_OPAQUE_UNIFORM(Mod7, 32);
MAKE_OPAQUE_UNIFORM(Mod7, 64);

MAKE_OPAQUE_UNIFORM(Mod11, 4);
MAKE_OPAQUE_UNIFORM(Mod11, 8);
MAKE_OPAQUE_UNIFORM(Mod11, 16);
MAKE_OPAQUE_UNIFORM(Mod11, 32);
MAKE_OPAQUE_UNIFORM(Mod11, 64);

MAKE_OPAQUE_UNIFORM(Mod13, 4);
MAKE_OPAQUE_UNIFORM(Mod13, 8);
MAKE_OPAQUE_UNIFORM(Mod13, 16);
MAKE_OPAQUE_UNIFORM(Mod13, 32);
MAKE_OPAQUE_UNIFORM(Mod13, 64);

PYBIND11_MODULE(_eval_engine, m) {
  m.doc() = "Evaluation engine for synth_xfer";

  register_rng(m);
  register_results_class(m);

  register_domain_widths<KnownBits, 4, 8, 16, 32, 64>(m);
  register_domain_widths<UConstRange, 4, 8, 16, 32, 64>(m);
  register_domain_widths<SConstRange, 4, 8, 16, 32, 64>(m);
  register_domain_widths<Mod3, 4, 8, 16, 32, 64>(m);
  register_domain_widths<Mod5, 4, 8, 16, 32, 64>(m);
  register_domain_widths<Mod7, 4, 8, 16, 32, 64>(m);
  register_domain_widths<Mod11, 4, 8, 16, 32, 64>(m);
  register_domain_widths<Mod13, 4, 8, 16, 32, 64>(m);
}
