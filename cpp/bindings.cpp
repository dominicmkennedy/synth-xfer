#include <cstdint>
#include <optional>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <utility>

#include "anti_range.hpp"
#include "domain.hpp"
#include "eval.hpp"
#include "knownbits.hpp"
#include "results.hpp"
#include "sconst_range.hpp"
#include "uconst_range.hpp"

namespace py = pybind11;

// TODO join all should take a vec of uint64_t and do everything in bulk for
// better perf

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
  const std::string cls_name = D<BW>::name + std::to_string(BW);

  auto cls = py::class_<D<BW>>(m, cls_name.c_str());
  cls.def_static("arity", []() { return D<BW>::arity; });
  cls.def_static("bw", []() { return BW; });
  cls.def("__str__", [](const D<BW> &self) {
    std::ostringstream oss;
    oss << self;
    std::string s = oss.str();
    s.pop_back();
    return s;
  });
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
void register_enum_domain(py::module_ &m) {
  std::string dname = D<BW>::name;
  const std::string cls_name =
      std::string("ToEval") + dname + std::to_string(BW);

  py::class_<ToEval<D, BW>>(m, cls_name.c_str())
      .def("__len__", [](const ToEval<D, BW> &v) { return v.size(); })
      .def(
          "__getitem__",
          [](const ToEval<D, BW> &v,
             std::size_t i) -> const std::tuple<D<BW>, D<BW>, D<BW>> & {
            if (i >= v.size())
              throw py::index_error();
            return v[i];
          },
          py::return_value_policy::reference_internal)
      .def(
          "__iter__",
          [](const ToEval<D, BW> &v) {
            return py::make_iterator(v.begin(), v.end());
          },
          py::keep_alive<0, 1>());

  std::transform(dname.begin(), dname.end(), dname.begin(), ::tolower);
  const std::string fn_name = dname + "_" + std::to_string(BW);

  m.def((std::string("enum_low_") + fn_name).c_str(),
        [](const std::uintptr_t crtOpAddr,
           const std::optional<std::uint64_t> opConFnAddr) {
          py::gil_scoped_release release;

          return std::make_unique<ToEval<D, BW>>(
              std::move(EnumDomain<D, BW>{crtOpAddr, opConFnAddr}.genLows()));
        },
        py::arg("crtOpAddr"), py::arg("opConFnAddr") = py::none(),
        py::return_value_policy::take_ownership);

  m.def((std::string("enum_mid_") + fn_name).c_str(),
        [](const std::uintptr_t crtOpAddr,
           const std::optional<std::uint64_t> opConFnAddr,
           const unsigned int num_lat_samples, const unsigned int seed) {
          py::gil_scoped_release release;

          std::mt19937 rng(seed);
          return std::make_unique<ToEval<D, BW>>(
              std::move(EnumDomain<D, BW>{crtOpAddr, opConFnAddr}.genMids(
                  num_lat_samples, rng)));
        },
        py::arg("crtOpAddr"), py::arg("opConFnAddr") = py::none(),
        py::arg("num_lat_samples"), py::arg("seed"),
        py::return_value_policy::take_ownership);

  m.def((std::string("enum_high_") + fn_name).c_str(),
        [](const std::uintptr_t crtOpAddr,
           const std::optional<std::uint64_t> opConFnAddr,
           const unsigned int num_lat_samples,
           const unsigned int num_crt_samples, const unsigned int seed) {
          py::gil_scoped_release release;

          std::mt19937 rng(seed);
          return std::make_unique<ToEval<D, BW>>(
              std::move(EnumDomain<D, BW>{crtOpAddr, opConFnAddr}.genHighs(
                  num_crt_samples, num_lat_samples, rng)));
        },
        py::arg("crtOpAddr"), py::arg("opConFnAddr") = py::none(),
        py::arg("num_lat_samples"), py::arg("num_crt_samples"), py::arg("seed"),
        py::return_value_policy::take_ownership);
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
void register_eval_domain(py::module_ &m) {
  std::string dname = D<BW>::name;
  std::transform(dname.begin(), dname.end(), dname.begin(), ::tolower);
  const std::string fn_name =
      std::string("eval_") + dname + "_" + std::to_string(BW);

  m.def(
      fn_name.c_str(),
      [](const ToEval<D, BW> &v, const std::vector<std::uintptr_t> xfers,
         const std::vector<std::uintptr_t> bases) -> Results {
        py::gil_scoped_release release;
        return Eval<D, BW>{xfers, bases}.eval(v);
      },
      py::arg("to_eval"), py::arg("xfers"), py::arg("bases"));
}

template <template <std::size_t> class D, std::size_t BW>
  requires Domain<D, BW>
void register_domain(py::module_ &m) {
  register_domain_class<D, BW>(m);
  register_enum_domain<D, BW>(m);
  register_eval_domain<D, BW>(m);
}

// Register domains and widths here
PYBIND11_MAKE_OPAQUE(ToEval<KnownBits, 4>);
PYBIND11_MAKE_OPAQUE(ToEval<KnownBits, 8>);
PYBIND11_MAKE_OPAQUE(ToEval<KnownBits, 16>);
PYBIND11_MAKE_OPAQUE(ToEval<KnownBits, 32>);
PYBIND11_MAKE_OPAQUE(ToEval<KnownBits, 64>);
PYBIND11_MAKE_OPAQUE(ToEval<UConstRange, 4>);
PYBIND11_MAKE_OPAQUE(ToEval<UConstRange, 8>);
PYBIND11_MAKE_OPAQUE(ToEval<UConstRange, 16>);
PYBIND11_MAKE_OPAQUE(ToEval<UConstRange, 32>);
PYBIND11_MAKE_OPAQUE(ToEval<UConstRange, 64>);
PYBIND11_MAKE_OPAQUE(ToEval<SConstRange, 4>);
PYBIND11_MAKE_OPAQUE(ToEval<SConstRange, 8>);
PYBIND11_MAKE_OPAQUE(ToEval<SConstRange, 16>);
PYBIND11_MAKE_OPAQUE(ToEval<SConstRange, 32>);
PYBIND11_MAKE_OPAQUE(ToEval<SConstRange, 64>);
PYBIND11_MAKE_OPAQUE(ToEval<AntiRange, 4>);
PYBIND11_MAKE_OPAQUE(ToEval<AntiRange, 8>);
PYBIND11_MAKE_OPAQUE(ToEval<AntiRange, 16>);
PYBIND11_MAKE_OPAQUE(ToEval<AntiRange, 32>);
PYBIND11_MAKE_OPAQUE(ToEval<AntiRange, 64>);

PYBIND11_MODULE(_eval_engine, m) {
  m.doc() = "Evaluation engine for synth_xfer";

  register_results_class(m);
  register_domain<KnownBits, 4>(m);
  register_domain<KnownBits, 8>(m);
  register_domain<KnownBits, 16>(m);
  register_domain<KnownBits, 32>(m);
  register_domain<KnownBits, 64>(m);
  register_domain<UConstRange, 4>(m);
  register_domain<UConstRange, 8>(m);
  register_domain<UConstRange, 16>(m);
  register_domain<UConstRange, 32>(m);
  register_domain<UConstRange, 64>(m);
  register_domain<SConstRange, 4>(m);
  register_domain<SConstRange, 8>(m);
  register_domain<SConstRange, 16>(m);
  register_domain<SConstRange, 32>(m);
  register_domain<SConstRange, 64>(m);
  register_domain<AntiRange, 4>(m);
  register_domain<AntiRange, 8>(m);
  register_domain<AntiRange, 16>(m);
  register_domain<AntiRange, 32>(m);
  register_domain<AntiRange, 64>(m);
}
