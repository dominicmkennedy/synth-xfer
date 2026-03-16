#include "bindings_common.hpp"

namespace {

template <typename NestedExamples>
py::list to_py_examples(const NestedExamples &all_examples) {
  py::list outer;
  for (const auto &per_xfer : all_examples) {
    py::list inner;
    for (const auto &[args, synth, best, distance] : per_xfer) {
      inner.append(py::make_tuple(py::cast(args), synth, best, distance));
    }
    outer.append(std::move(inner));
  }
  return outer;
}

} // namespace

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

  cls.def("get_unsound_examples", [](const Results &self) {
    return to_py_examples(self.getUnsoundExampleTuples());
  });

  cls.def("get_imprecise_examples", [](const Results &self) {
    return to_py_examples(self.getImpreciseExampleTuples());
  });
}

PYBIND11_MODULE(_eval_engine, m) {
  m.doc() = "Evaluation engine for synth_xfer";

  register_rng(m);
  register_results_class(m);

  register_knownbits_bindings(m);
  register_uconst_range_bindings(m);
  register_sconst_range_bindings(m);
  register_mod3_bindings(m);
  register_mod5_bindings(m);
  register_mod7_bindings(m);
  register_mod11_bindings(m);
  register_mod13_bindings(m);
}
