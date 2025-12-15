#pragma once

#include <cassert>
#include <cmath>
#include <cstdint>
#include <random>

namespace rngdist {

using Engine = std::mt19937;

namespace detail {

[[nodiscard]] inline double uniform01(Engine &g) noexcept {
  return std::generate_canonical<double, 53>(g);
}

[[nodiscard]] inline std::uint64_t map_unit_to_u64(double u, std::uint64_t lo,
                                                   std::uint64_t hi) noexcept {
  assert(lo <= hi);
  if (lo == hi)
    return lo;

  if (!(u >= 0.0))
    u = 0.0;
  else if (u > 1.0)
    u = 1.0;

  const __uint128_t width = static_cast<__uint128_t>(hi) -
                            static_cast<__uint128_t>(lo) +
                            static_cast<__uint128_t>(1);

  __uint128_t idx =
      static_cast<__uint128_t>(u * static_cast<long double>(width));
  if (idx >= width)
    idx = width - static_cast<__uint128_t>(1);

  return static_cast<std::uint64_t>(static_cast<__uint128_t>(lo) + idx);
}

} // namespace detail

struct Sampler {
  virtual ~Sampler() = default;

  [[nodiscard]] virtual std::uint64_t sample(Engine &rng, std::uint64_t lo,
                                             std::uint64_t hi) const = 0;

  [[nodiscard]] std::uint64_t operator()(Engine &rng, std::uint64_t lo,
                                         std::uint64_t hi) const {
    return sample(rng, lo, hi);
  }
};

struct UniformSampler final : Sampler {
  [[nodiscard]] std::uint64_t sample(Engine &rng, std::uint64_t lo,
                                     std::uint64_t hi) const override {
    assert(lo <= hi);
    std::uniform_int_distribution<std::uint64_t> d{lo, hi};
    return d(rng);
  }
};

struct NormalSampler final : Sampler {
  explicit NormalSampler(double sigma_) : sigma(sigma_) {}
  double sigma;

  [[nodiscard]] std::uint64_t sample(Engine &rng, std::uint64_t lo,
                                     std::uint64_t hi) const override {
    assert(lo <= hi);
    assert(std::isfinite(sigma) && sigma > 0.0);

    static thread_local std::normal_distribution<double> nd{0.0, 1.0};

    for (int iter = 0; iter < 10'000; ++iter) {
      const double x = 0.5 + sigma * nd(rng);
      if (x >= 0.0 && x <= 1.0) {
        return detail::map_unit_to_u64(x, lo, hi);
      }
    }
    return detail::map_unit_to_u64(detail::uniform01(rng), lo, hi);
  }
};

struct SkewNormalLeftSampler final : Sampler {
  SkewNormalLeftSampler(double sigma_, double alpha_)
      : sigma(sigma_), alpha(alpha_) {}
  double sigma;
  double alpha; // magnitude

  [[nodiscard]] std::uint64_t sample(Engine &rng, std::uint64_t lo,
                                     std::uint64_t hi) const override {
    assert(lo <= hi);
    assert(std::isfinite(sigma) && sigma > 0.0);
    assert(std::isfinite(alpha));

    static thread_local std::normal_distribution<double> nd{0.0, 1.0};

    const double a = -std::fabs(alpha);
    const double denom = std::sqrt(1.0 + a * a);
    const double delta = a / denom;
    const double s = std::sqrt(1.0 - delta * delta);

    for (int iter = 0; iter < 10'000; ++iter) {
      const double u = nd(rng);
      const double v = nd(rng);
      const double z = delta * std::fabs(u) + s * v;
      const double x = 0.5 + sigma * z;
      if (x >= 0.0 && x <= 1.0) {
        return detail::map_unit_to_u64(x, lo, hi);
      }
    }
    return detail::map_unit_to_u64(detail::uniform01(rng), lo, hi);
  }
};

struct SkewNormalRightSampler final : Sampler {
  SkewNormalRightSampler(double sigma_, double alpha_)
      : sigma(sigma_), alpha(alpha_) {}
  double sigma;
  double alpha; // magnitude

  [[nodiscard]] std::uint64_t sample(Engine &rng, std::uint64_t lo,
                                     std::uint64_t hi) const override {
    assert(lo <= hi);
    assert(std::isfinite(sigma) && sigma > 0.0);
    assert(std::isfinite(alpha));

    static thread_local std::normal_distribution<double> nd{0.0, 1.0};

    const double a = +std::fabs(alpha);
    const double denom = std::sqrt(1.0 + a * a);
    const double delta = a / denom;
    const double s = std::sqrt(1.0 - delta * delta);

    for (int iter = 0; iter < 10'000; ++iter) {
      const double u = nd(rng);
      const double v = nd(rng);
      const double z = delta * std::fabs(u) + s * v;
      const double x = 0.5 + sigma * z;
      if (x >= 0.0 && x <= 1.0) {
        return detail::map_unit_to_u64(x, lo, hi);
      }
    }
    return detail::map_unit_to_u64(detail::uniform01(rng), lo, hi);
  }
};

struct BimodalSymmetricSampler final : Sampler {
  BimodalSymmetricSampler(double sigma_, double separation_)
      : sigma(sigma_), separation(separation_) {}

  double sigma;
  double separation;

  [[nodiscard]] std::uint64_t sample(Engine &rng, std::uint64_t lo,
                                     std::uint64_t hi) const override {
    assert(lo <= hi);
    assert(std::isfinite(sigma) && sigma > 0.0);
    assert(std::isfinite(separation));

    static thread_local std::normal_distribution<double> nd{0.0, 1.0};
    std::bernoulli_distribution pick_right{0.5};

    double sep = separation;
    if (sep < 0.0)
      sep = 0.0;
    else if (sep > 0.49)
      sep = 0.49;

    for (int iter = 0; iter < 10'000; ++iter) {
      const double mu = pick_right(rng) ? (0.5 + sep) : (0.5 - sep);
      const double x = mu + sigma * nd(rng);
      if (x >= 0.0 && x <= 1.0) {
        return detail::map_unit_to_u64(x, lo, hi);
      }
    }
    return detail::map_unit_to_u64(detail::uniform01(rng), lo, hi);
  }
};

} // namespace rngdist
