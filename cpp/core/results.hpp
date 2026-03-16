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
    std::tuple<std::vector<std::string>, std::string, std::string,
         unsigned long>;

namespace detail {

template <typename T>
std::string toText(const T &v) {
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
                            const ResultD &best, unsigned long dis) {
  return CaseExample(argsToText(args), toText(synth), toText(best), dis);
}

} // namespace detail

class Result {
  // The result of evaluating a single transformer on one bitwidth.
public:
  Result() = default;

  // Result(bool s, unsigned long p, bool e, bool solved, unsigned long sd,
  //        const CaseExample &ex = {})
  //     : sound(s), distance(p), exact(e), soundDistance(sd) {
  //   unsolvedExact = !solved ? e : 0;
  //   if (!s)
  //     unsoundExamples.push_back(ex);
  //   else if (!e)
  //     impreciseExamples.push_back(ex);
  // }

  // Result &operator+=(const Result &rhs) {
  //   sound += rhs.sound;
  //   distance += rhs.distance;
  //   exact += rhs.exact;
  //   unsolvedExact += rhs.unsolvedExact;
  //   soundDistance += rhs.soundDistance;

  //   // Make sure those thershold are 0 when doing synthesis
  //   if (MAX_UNSOUND_EXAMPLES > 0) {
  //     unsoundExamples.insert(unsoundExamples.end(), rhs.unsoundExamples.begin(),
  //                  rhs.unsoundExamples.end());
  //   }
  //   if (MAX_IMPRECISE_EXAMPLES > 0) {
  //     impreciseExamples.insert(impreciseExamples.end(),
  //                  rhs.impreciseExamples.begin(),
  //                  rhs.impreciseExamples.end());
  //   }
  //   return *this;
  // }

  friend class Results;

private:
  unsigned long sound;
  unsigned long distance;
  unsigned long exact;
  unsigned long unsolvedExact;
  unsigned long soundDistance;
  std::vector<CaseExample> unsoundExamples;
  std::vector<CaseExample> impreciseExamples;
};

class Results {
  // The result of evaluating a set of transformers on one bitwidth.
private:
  using CaseExamples = std::vector<CaseExample>;
  const unsigned int bw = {};
  std::vector<Result> r;
  unsigned int cases = {};
  unsigned int unsolvedCases = {};
  unsigned int baseDistance = {};
  std::uint64_t (*maxDist)() = {};
  unsigned int maxUnsoundExamples = 0;
  unsigned int maxImpreciseExamples = 0;

  void printMember(std::ostream &os, std::string_view name,
                   const std::function<unsigned long(const Result &x)> &getter,
                   bool md) const {
    os << std::left << std::setw(20) << name;
    os << "[";
    for (auto it = r.begin(); it != r.end(); ++it) {
      os << std::right << std::setw(8);
      if (md)
        os << static_cast<double>(getter(*it)) / static_cast<double>(maxDist());
      else
        os << getter(*it);
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
                               static_cast<double>(std::get<3>(ex)) / static_cast<double>(maxDist()));
      }
      out.push_back(std::move(converted));
    }
    return out;
  }

public:
  Results(unsigned int numFns, unsigned int bw_, std::uint64_t (*_maxDist)(),
          unsigned int maxUnsound = 0, unsigned int maxImprecise = 0)
      : bw(bw_), r(std::vector<Result>(numFns)), maxDist(_maxDist),
        maxUnsoundExamples(maxUnsound), maxImpreciseExamples(maxImprecise) {}

  friend std::ostream &operator<<(std::ostream &os, const Results &x) {
    os << std::left << std::setw(20) << "bw:" << x.bw << "\n";
    os << std::left << std::setw(20) << "num cases:" << x.cases << "\n";
    os << std::left << std::setw(20) << "num unsolved:" << x.unsolvedCases
       << "\n";
    os << std::left << std::setw(20) << "base distance:"
       << static_cast<double>(x.baseDistance) / static_cast<double>(x.maxDist())
       << "\n";
    x.printMember(
        os, "num sound:", [](const Result &x) { return x.sound; }, false);
    x.printMember(
        os, "distance:", [](const Result &x) { return x.distance; }, true);
    x.printMember(
        os, "num exact:", [](const Result &x) { return x.exact; }, false);
    x.printMember(
        os,
        "num unsolved exact:", [](const Result &x) { return x.unsolvedExact; },
        false);
    x.printMember(
        os, "sound distance:", [](const Result &x) { return x.soundDistance; },
        true);

    return os << "\n";
  }

  template <typename ArgsTuple, typename ResultD>
  void incResult(bool s, unsigned long p, bool e, bool solved, unsigned long sd,
                 const ArgsTuple &args, const ResultD &synth,
                 const ResultD &best, unsigned long dis, unsigned int i) {
    r[i].sound += s;
    r[i].distance += p;
    r[i].exact += e;
    r[i].soundDistance += sd;
    r[i].unsolvedExact += !solved ? e : 0;
    if (maxUnsoundExamples > r[i].unsoundExamples.size() && !s)
      r[i].unsoundExamples.push_back(detail::makeCaseExample(args, synth, best, dis));
    // Xuanyu: maybe when the impreciseExamples it too large, do a sort and only keep the top-k
    else if (5 * maxImpreciseExamples > r[i].impreciseExamples.size() && s && !e)
      r[i].impreciseExamples.push_back(detail::makeCaseExample(args, synth, best, dis));
  }

  void incCases(bool solved, unsigned long dis) {
    cases += 1;
    unsolvedCases += !solved ? 1 : 0;
    baseDistance += dis;
  }

  void cleanExamples(){
    for (auto &result : r) {
      // Keep only the first maxUnsoundExamples
      if (maxUnsoundExamples > 0 && result.unsoundExamples.size() > maxUnsoundExamples) {
        result.unsoundExamples.resize(maxUnsoundExamples);
      }
      // Keep only the top maxImpreciseExamples with maximum distance
      if (maxImpreciseExamples > 0 && result.impreciseExamples.size() > maxImpreciseExamples) {
        // Sort by distance (descending) - the fourth element of the tuple
        std::sort(result.impreciseExamples.begin(), result.impreciseExamples.end(),
                  [](const CaseExample &a, const CaseExample &b) {
                    return std::get<3>(a) > std::get<3>(b);
                  });
        result.impreciseExamples.resize(maxImpreciseExamples);
      }
    }
  }


  std::vector<CaseExamples> getUnsoundExampleTuples() const {

    return collectExampleTuples(
        [](const Result &ri) -> const CaseExamples & {
          return ri.unsoundExamples;
        });
  }

  std::vector<CaseExamples> getImpreciseExampleTuples() const {

    return collectExampleTuples([](const Result &ri) -> const CaseExamples & {
      return ri.impreciseExamples;
    });
  }
};
