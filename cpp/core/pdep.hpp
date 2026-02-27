#pragma once
#include <cstdint>

#if !defined(__clang__)
#error "This header supports only Clang."
#endif

#if !defined(__x86_64__) && !defined(__aarch64__)
#error "This header supports only x86_64 or arm64 (AArch64)."
#endif

#if defined(__x86_64__)
#include <immintrin.h>
#endif

namespace pdep_detail {
template <int I, int BW>
inline void step(uint64_t src, uint64_t &mask, uint64_t &out) {
  if constexpr (I < BW) {
    uint64_t mbit = mask & (~mask + 1);
    out |= 0ull - ((src >> I) & 1ull) & mbit;
    mask ^= mbit;
    step<I + 1, BW>(src, mask, out);
  }
}

template <int BW> inline uint64_t pdep_fallback(uint64_t src, uint64_t mask) {
  static_assert(BW >= 1 && BW <= 64, "BW must be in [0,64]");
  uint64_t out = 0;
  pdep_detail::step<0, BW>(src, mask, out);
  return out;
}

#if defined(__x86_64__)
__attribute__((target("bmi2"))) inline uint64_t pdep_bmi2_only(uint64_t src,
                                                               uint64_t mask) {
  return _pdep_u64(src, mask);
}
#endif
} // namespace pdep_detail

template <int BW> inline uint64_t pdep(uint64_t src, uint64_t mask) {
#if defined(__x86_64__)
  if (__builtin_cpu_supports("bmi2"))
    return pdep_detail::pdep_bmi2_only(src, mask);
  return pdep_detail::pdep_fallback<BW>(src, mask);
#elif defined(__aarch64__)
  return pdep_detail::pdep_fallback<BW>(src, mask);
#endif
}
