#pragma once

#include <array>
#include <cstdint>
#include <string_view>

namespace ct {

template <std::size_t N> struct fixed_string {
  std::array<char, N> buf{};
  constexpr std::string_view view() const noexcept {
    return std::string_view(buf.data(), N - 1);
  }
};

template <std::uint64_t N> constexpr std::size_t digits() {
  static_assert(N <= 999, "ct::to_string<N>: N must be in [0, 999].");
  if constexpr (N >= 100)
    return 3;
  if constexpr (N >= 10)
    return 2;
  return 1;
}

template <std::uint64_t N>
constexpr fixed_string<digits<N>() + 1> to_fixed_string() {
  fixed_string<digits<N>() + 1> s{};
  if constexpr (N >= 100) {
    s.buf[0] = static_cast<char>('0' + (N / 100));
    s.buf[1] = static_cast<char>('0' + ((N / 10) % 10));
    s.buf[2] = static_cast<char>('0' + (N % 10));
    s.buf[3] = '\0';
  } else if constexpr (N >= 10) {
    s.buf[0] = static_cast<char>('0' + (N / 10));
    s.buf[1] = static_cast<char>('0' + (N % 10));
    s.buf[2] = '\0';
  } else {
    s.buf[0] = static_cast<char>('0' + N);
    s.buf[1] = '\0';
  }
  return s;
}

template <std::size_t PrefixN, std::size_t SuffixN>
constexpr std::array<char, (PrefixN - 1) + (SuffixN - 1) + 1>
concat_fixed(const char (&prefix)[PrefixN],
             const fixed_string<SuffixN> &suffix) {
  constexpr std::size_t prefix_len = PrefixN - 1;
  constexpr std::size_t suffix_len = SuffixN - 1;
  std::array<char, prefix_len + suffix_len + 1> out{};
  for (std::size_t i = 0; i < prefix_len; ++i)
    out[i] = prefix[i];
  for (std::size_t i = 0; i < suffix_len; ++i)
    out[prefix_len + i] = suffix.buf[i];
  out[prefix_len + suffix_len] = '\0';
  return out;
}

} // namespace ct
