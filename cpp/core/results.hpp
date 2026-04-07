#pragma once

#include <algorithm>
#include <cstdint>
#include <functional>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

using CaseExample =
    std::tuple<std::vector<std::string>, std::string, std::string, double>;

namespace detail {

template <typename T> std::string toText(const T &v) {
  std::ostringstream oss;
  oss << v;
  std::string s = oss.str();
  if (!s.empty() && s.back() == '\n')
    s.pop_back();
  return s;
}

template <typename ArgsTuple>
std::vector<std::string> argsToText(const ArgsTuple &args) {
  std::vector<std::string> out;
  std::apply([&](const auto &...parts) { (out.push_back(toText(parts)), ...); },
             args);
  return out;
}

template <typename ArgsTuple, typename ResultD>
CaseExample makeCaseExample(const ArgsTuple &args, const ResultD &synth,
                            const ResultD &best, double dis) {
  return CaseExample(argsToText(args), toText(synth), toText(best), dis);
}

} // namespace detail

class Result {
  // The result of evaluating a single transformer on one bitwidth.
public:
  Result() = default;
  friend class Results;

private:
  unsigned long sound;
  double distance;
  unsigned long exact;
  unsigned long unsolved_exact;
  double sound_distance;
  std::vector<CaseExample> unsound_examples;
  std::vector<CaseExample> imprecise_examples;
};

class Results {
  // The result of evaluating a set of transformers on one bitwidth.
private:
  using CaseExamples = std::vector<CaseExample>;
  const unsigned int bw = {};
  std::vector<Result> r;
  unsigned int cases = {};
  unsigned int unsolvedCases = {};
  double base_distance = {};
  unsigned int maxUnsoundExamples = 0;
  unsigned int maxImpreciseExamples = 0;

  template <typename Getter>
  void print_member(
      std::ostream &os, std::string_view name,
      Getter getter) const {
    os << std::left << std::setw(20) << name;
    os << "[";
    for (auto it = r.begin(); it != r.end(); ++it) {
      os << std::right << std::setw(8) << getter(*it);
      if (std::next(it) != r.end())
        os << ", ";
      else
        os << "]\n";
    }
  }

  template <typename Getter>
  std::vector<CaseExamples> collectExampleTuples(Getter getter) const {
    std::vector<CaseExamples> out;
    out.reserve(r.size());
    for (const auto &ri : r) {
      const auto &examples = getter(ri);
      CaseExamples converted;
      converted.reserve(examples.size());
      for (const auto &ex : examples) {
        converted.emplace_back(std::get<0>(ex), std::get<1>(ex),
                               std::get<2>(ex),
                               static_cast<double>(std::get<3>(ex)));
      }
      out.push_back(std::move(converted));
    }
    return out;
  }

public:
  Results(unsigned int numFns, unsigned int bw_,
          unsigned int maxUnsound = 0, unsigned int maxImprecise = 0)
      : bw(bw_), r(std::vector<Result>(numFns)),
        maxUnsoundExamples(maxUnsound), maxImpreciseExamples(maxImprecise) {}

  friend std::ostream &operator<<(std::ostream &os, const Results &x) {
    os << std::left << std::setw(20) << "bw:" << x.bw << "\n";
    os << std::left << std::setw(20) << "num cases:" << x.cases << "\n";
    os << std::left << std::setw(20) << "num unsolved:" << x.unsolvedCases
       << "\n";
    os << std::left << std::setw(20) << "base distance:" << x.base_distance
       << "\n";
    x.print_member(os, "num sound:", [](const Result &x) { return x.sound; });
    x.print_member(os, "distance:", [](const Result &x) { return x.distance; });
    x.print_member(os, "num exact:", [](const Result &x) { return x.exact; });
    x.print_member(os, "num unsolved exact:", [](const Result &x) {
      return x.unsolved_exact;
    });
    x.print_member(os, "sound distance:", [](const Result &x) {
      return x.sound_distance;
    });

    return os << "\n";
  }

  template <typename ArgsTuple, typename ResultD>
  void incResult(bool s, bool e, bool solved, double sd, const ArgsTuple &args,
                 const ResultD &synth, const ResultD &best, double dis,
                 unsigned int i) {
    r[i].sound += s;
    r[i].distance += dis;
    r[i].exact += e;
    r[i].sound_distance += sd;
    r[i].unsolved_exact += !solved ? e : 0;
    if (maxUnsoundExamples > r[i].unsound_examples.size() && !s)
      r[i].unsound_examples.push_back(
          detail::makeCaseExample(args, synth, best, dis));
    // Xuanyu: maybe when the impreciseExamples it too large, do a sort and only
    // keep the top-k
    else if (5 * maxImpreciseExamples > r[i].imprecise_examples.size() && s &&
             !e)
      r[i].imprecise_examples.push_back(
          detail::makeCaseExample(args, synth, best, dis));
  }

  void incCases(bool solved, double distance) {
    cases += 1;
    unsolvedCases += !solved ? 1 : 0;
    base_distance += distance;
  }

  void cleanExamples() {
    for (auto &result : r) {
      // Keep only the first maxUnsoundExamples
      if (maxUnsoundExamples > 0 &&
          result.unsound_examples.size() > maxUnsoundExamples) {
        result.unsound_examples.resize(maxUnsoundExamples);
      }
      // Keep only the top maxImpreciseExamples with maximum distance
      if (maxImpreciseExamples > 0 &&
          result.imprecise_examples.size() > maxImpreciseExamples) {
        // Sort by distance (descending) - the fourth element of the tuple
        std::sort(result.imprecise_examples.begin(),
                  result.imprecise_examples.end(),
                  [](const CaseExample &a, const CaseExample &b) {
                    return std::get<3>(a) > std::get<3>(b);
                  });
        result.imprecise_examples.resize(maxImpreciseExamples);
      }
    }
  }

  std::vector<CaseExamples> getUnsoundExampleTuples() const {
    return collectExampleTuples([](const Result &ri) -> const CaseExamples & {
      return ri.unsound_examples;
    });
  }

  std::vector<CaseExamples> getImpreciseExampleTuples() const {
    return collectExampleTuples([](const Result &ri) -> const CaseExamples & {
      return ri.imprecise_examples;
    });
  }
};
