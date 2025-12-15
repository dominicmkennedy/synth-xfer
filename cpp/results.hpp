#pragma once

#include <functional>
#include <iomanip>
#include <iostream>
#include <string_view>
#include <vector>

class Result {
public:
  Result() = default;

  Result(bool s, unsigned long p, bool e, bool solved, unsigned long sd)
      : sound(s), distance(p), exact(e), soundDistance(sd) {
    unsolvedExact = !solved ? e : 0;
  }

  Result &operator+=(const Result &rhs) {
    sound += rhs.sound;
    distance += rhs.distance;
    exact += rhs.exact;
    unsolvedExact += rhs.unsolvedExact;
    soundDistance += rhs.soundDistance;

    return *this;
  }

  friend class Results;

private:
  unsigned long sound;
  unsigned long distance;
  unsigned long exact;
  unsigned long unsolvedExact;
  unsigned long soundDistance;
};

class Results {
private:
  const unsigned int bw = {};
  std::vector<Result> r;
  unsigned int cases = {};
  unsigned int unsolvedCases = {};
  unsigned int baseDistance = {};
  std::uint64_t (*maxDist)() = {};

  void printMember(std::ostream &os, std::string_view name,
                   const std::function<unsigned int(const Result &x)> &getter,
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

public:
  Results(unsigned int numFns, unsigned int bw_, std::uint64_t (*_maxDist)())
      : bw(bw_), r(std::vector<Result>(numFns)), maxDist(_maxDist) {}

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

  void incResult(const Result &newR, unsigned int i) { r[i] += newR; }

  void incCases(bool solved, unsigned long dis) {
    cases += 1;
    unsolvedCases += !solved ? 1 : 0;
    baseDistance += dis;
  }
};
