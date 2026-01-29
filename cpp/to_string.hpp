#pragma once

#include <cstdint>
#include <string>

namespace ct {

template <std::uint64_t N> constexpr std::string to_string() {
  static_assert(N <= 999, "ct::to_string<N>: N must be in [0, 999].");

  std::string s;

  if constexpr (N >= 100) {
    s.push_back(static_cast<char>('0' + (N / 100)));
    s.push_back(static_cast<char>('0' + ((N / 10) % 10)));
    s.push_back(static_cast<char>('0' + (N % 10)));
  } else if constexpr (N >= 10) {
    s.push_back(static_cast<char>('0' + (N / 10)));
    s.push_back(static_cast<char>('0' + (N % 10)));
  } else {
    s.push_back(static_cast<char>('0' + N));
  }

  return s;
}

} // namespace ct
