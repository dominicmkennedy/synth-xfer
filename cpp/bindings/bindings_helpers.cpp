#include "bindings_common.hpp"

#include <cctype>

std::vector<ParsedEnumRow> parse_enum_rows(py::sequence rows,
                                           const std::size_t arity) {
  std::vector<ParsedEnumRow> parsed;
  parsed.reserve(py::len(rows));

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
    if (args.size() != arity) {
      throw py::value_error("args tuple has wrong arity");
    }

    if (!py::isinstance<py::str>(row[1])) {
      throw py::value_error("ret must be a string");
    }

    ParsedEnumRow parsed_row;
    parsed_row.args.reserve(arity);
    for (std::size_t i = 0; i < arity; ++i) {
      if (!py::isinstance<py::str>(args[i])) {
        throw py::value_error("each arg must be a string");
      }
      parsed_row.args.emplace_back(py::cast<std::string>(args[i]));
    }
    parsed_row.ret = py::cast<std::string>(row[1]);
    parsed.push_back(std::move(parsed_row));
  }

  return parsed;
}

std::vector<std::vector<py::object>> parse_run_rows(py::sequence rows,
                                                    const std::size_t arity) {
  std::vector<std::vector<py::object>> parsed;
  parsed.reserve(py::len(rows));

  for (py::handle row_h : rows) {
    if (!py::isinstance<py::tuple>(row_h)) {
      throw py::value_error("row must be a tuple");
    }

    py::tuple row = py::reinterpret_borrow<py::tuple>(row_h);
    if (row.size() != arity) {
      throw py::value_error("row has wrong arity");
    }

    std::vector<py::object> parsed_row;
    parsed_row.reserve(arity);
    for (std::size_t i = 0; i < arity; ++i) {
      parsed_row.push_back(py::reinterpret_borrow<py::object>(row[i]));
    }
    parsed.push_back(std::move(parsed_row));
  }

  return parsed;
}

std::string to_lower_ascii(std::string s) {
  std::transform(s.begin(), s.end(), s.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return s;
}

void bind_enum_funcs(py::module_ &m, const std::string &fn_name,
                     EnumLowThunk low, EnumMidThunk mid,
                     EnumHighThunk high) {
  m.def(("enum_low_" + fn_name).c_str(), low, py::arg("crtOpAddr"),
        py::arg("opConFnAddr"));
  m.def(("enum_mid_" + fn_name).c_str(), mid, py::arg("crtOpAddr"),
        py::arg("opConFnAddr"), py::arg("num_lat_samples"), py::arg("seed"),
        py::arg("sampler"));
  m.def(("enum_high_" + fn_name).c_str(), high, py::arg("crtOpAddr"),
        py::arg("opConFnAddr"), py::arg("num_lat_samples"),
        py::arg("num_conc_samples"), py::arg("seed"), py::arg("sampler"));
}

void bind_eval_func(py::module_ &m, const std::string &fn_name,
                    EvalThunk eval) {
  m.def(fn_name.c_str(), eval, py::arg("to_eval"), py::arg("xfers"),
        py::arg("bases"), py::arg("unsound_ex") = 0, py::arg("imprecise_ex") = 0);
}

void bind_eval_pattern_func(py::module_ &m, const std::string &fn_name,
                            EvalPatternThunk eval) {
  m.def(fn_name.c_str(), eval, py::arg("rows"), py::arg("weights"),
        py::arg("sequential"), py::arg("composite"));
}

void bind_run_func(py::module_ &m, const std::string &fn_name, RunThunk run) {
  m.def(fn_name.c_str(), run, py::arg("to_run"), py::arg("xfer_addr"));
}
