#pragma once

#include "ConstantRange.h"
#include "KnownBits.h"

#include <array>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <functional>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <vector>

namespace llvm {

using KBXfer = std::function<KnownBits(const KnownBits &, const KnownBits &)>;
using CRXfer =
    std::function<ConstantRange(const ConstantRange &, const ConstantRange &)>;

using OBO = OverflowingBinaryOperator;
using PRT = ConstantRange::PreferredRangeType;
inline static const int nsw = OBO::NoSignedWrap;
inline static const int nuw = OBO::NoUnsignedWrap;

#define KB_OP(e)                                                               \
  [](const llvm::KnownBits &l, const llvm::KnownBits &r) { return e; }

#define CR_OP(e)                                                               \
  [](const llvm::ConstantRange &l, const llvm::ConstantRange &r) { return e; }

inline const std::unordered_map<std::string_view, KBXfer> kb_xfer_table = {
    {"AddNswNuw", KB_OP(KnownBits::add(l, r, /*NSW=*/true, /*NUW=*/true))},
    {"AddNsw", KB_OP(KnownBits::add(l, r, /*NSW=*/true, /*NUW=*/false))},
    {"AddNuw", KB_OP(KnownBits::add(l, r, /*NSW=*/false, /*NUW=*/true))},
    {"Add", KB_OP(KnownBits::add(l, r))},
    {"And", KB_OP(KnownBits(l) &= r)},
    {"AshrExact", KB_OP(KnownBits::ashr(l, r, false, /*Exact=*/true))},
    {"Ashr", KB_OP(KnownBits::ashr(l, r))},
    {"LshrExact", KB_OP(KnownBits::lshr(l, r, false, /*Exact=*/true))},
    {"Lshr", KB_OP(KnownBits::lshr(l, r))},
    {"Mods", KB_OP(KnownBits::srem(l, r))},
    {"Modu", KB_OP(KnownBits::urem(l, r))},
    {"MulNswNuw", KB_OP(KnownBits::mul(l, r))}, // Using flagless fallback
    {"MulNsw", KB_OP(KnownBits::mul(l, r))},    // Using flagless fallback
    {"MulNuw", KB_OP(KnownBits::mul(l, r))},    // Using flagless fallback
    {"Mul", KB_OP(KnownBits::mul(l, r))},
    {"OrDisjoint", KB_OP(KnownBits(l) |= r)}, // Using flagless fallback
    {"Or", KB_OP(KnownBits(l) |= r)},
    {"SdivExact", KB_OP(KnownBits::sdiv(l, r, /*Exact=*/true))},
    {"Sdiv", KB_OP(KnownBits::sdiv(l, r))},
    {"ShlNswNuw", KB_OP(KnownBits::shl(l, r, /*NUW=*/true, /*NSW=*/true))},
    {"ShlNsw", KB_OP(KnownBits::shl(l, r, /*NUW=*/false, /*NSW=*/true))},
    {"ShlNuw", KB_OP(KnownBits::shl(l, r, /*NUW=*/true, /*NSW=*/false))},
    {"Shl", KB_OP(KnownBits::shl(l, r))},
    {"SubNswNuw", KB_OP(KnownBits::sub(l, r, /*NSW=*/true, /*NUW=*/true))},
    {"SubNsw", KB_OP(KnownBits::sub(l, r, /*NSW=*/true, /*NUW=*/false))},
    {"SubNuw", KB_OP(KnownBits::sub(l, r, /*NSW=*/false, /*NUW=*/true))},
    {"Sub", KB_OP(KnownBits::sub(l, r))},
    {"UdivExact", KB_OP(KnownBits::udiv(l, r, /*Exact=*/true))},
    {"Udiv", KB_OP(KnownBits::udiv(l, r))},
    {"Xor", KB_OP(KnownBits(l) ^= r)},
};

inline const std::unordered_map<std::string_view, CRXfer> ucr_xfer_table = {
    {"AddNswNuw", CR_OP(l.addWithNoWrap(r, nsw | nuw, PRT::Unsigned))},
    {"AddNsw", CR_OP(l.addWithNoWrap(r, nsw, PRT::Unsigned))},
    {"AddNuw", CR_OP(l.addWithNoWrap(r, nuw, PRT::Unsigned))},
    {"Add", CR_OP(l.add(r))},
    {"And", CR_OP(l.binaryAnd(r))},
    {"AshrExact", CR_OP(l.ashr(r))}, // NOTE: Using flagless fallback
    {"Ashr", CR_OP(l.ashr(r))},
    {"LshrExact", CR_OP(l.lshr(r))}, // NOTE: Using flagless fallback
    {"Lshr", CR_OP(l.lshr(r))},
    {"Mods", CR_OP(l.srem(r))},
    {"Modu", CR_OP(l.urem(r))},
    {"MulNswNuw", CR_OP(l.multiplyWithNoWrap(r, nsw | nuw, PRT::Unsigned))},
    {"MulNsw", CR_OP(l.multiplyWithNoWrap(r, nsw, PRT::Unsigned))},
    {"MulNuw", CR_OP(l.multiplyWithNoWrap(r, nuw, PRT::Unsigned))},
    {"Mul", CR_OP(l.multiply(r))},
    {"OrDisjoint", CR_OP(l.binaryOr(r))}, // NOTE: Using flagless fallback
    {"Or", CR_OP(l.binaryOr(r))},
    {"SdivExact", CR_OP(l.sdiv(r))}, // NOTE: Using flagless fallback
    {"Sdiv", CR_OP(l.sdiv(r))},
    {"ShlNswNuw", CR_OP(l.shlWithNoWrap(r, nsw | nuw, PRT::Unsigned))},
    {"ShlNsw", CR_OP(l.shlWithNoWrap(r, nsw, PRT::Unsigned))},
    {"ShlNuw", CR_OP(l.shlWithNoWrap(r, nuw, PRT::Unsigned))},
    {"Shl", CR_OP(l.shl(r))},
    {"SubNswNuw", CR_OP(l.subWithNoWrap(r, nsw | nuw, PRT::Unsigned))},
    {"SubNsw", CR_OP(l.subWithNoWrap(r, nsw, PRT::Unsigned))},
    {"SubNuw", CR_OP(l.subWithNoWrap(r, nuw, PRT::Unsigned))},
    {"Sub", CR_OP(l.sub(r))},
    {"UdivExact", CR_OP(l.udiv(r))}, // NOTE: Using flagless fallback
    {"Udiv", CR_OP(l.udiv(r))},
    {"Xor", CR_OP(l.binaryXor(r))},
};

inline const std::unordered_map<std::string_view, CRXfer> scr_xfer_table = {
    {"AddNswNuw", CR_OP(l.addWithNoWrap(r, nsw | nuw, PRT::Signed))},
    {"AddNsw", CR_OP(l.addWithNoWrap(r, nsw, PRT::Signed))},
    {"AddNuw", CR_OP(l.addWithNoWrap(r, nuw, PRT::Signed))},
    {"Add", CR_OP(l.add(r))},
    {"And", CR_OP(l.binaryAnd(r))},
    {"AshrExact", CR_OP(l.ashr(r))}, // NOTE: Using flagless fallback
    {"Ashr", CR_OP(l.ashr(r))},
    {"LshrExact", CR_OP(l.lshr(r))}, // NOTE: Using flagless fallback
    {"Lshr", CR_OP(l.lshr(r))},
    {"Mods", CR_OP(l.srem(r))},
    {"Modu", CR_OP(l.urem(r))},
    {"MulNswNuw", CR_OP(l.multiplyWithNoWrap(r, nsw | nuw, PRT::Signed))},
    {"MulNsw", CR_OP(l.multiplyWithNoWrap(r, nsw, PRT::Signed))},
    {"MulNuw", CR_OP(l.multiplyWithNoWrap(r, nuw, PRT::Signed))},
    {"Mul", CR_OP(l.multiply(r))},
    {"OrDisjoint", CR_OP(l.binaryOr(r))}, // NOTE: Using flagless fallback
    {"Or", CR_OP(l.binaryOr(r))},
    {"SdivExact", CR_OP(l.sdiv(r))}, // NOTE: Using flagless fallback
    {"Sdiv", CR_OP(l.sdiv(r))},
    {"ShlNswNuw", CR_OP(l.shlWithNoWrap(r, nsw | nuw, PRT::Signed))},
    {"ShlNsw", CR_OP(l.shlWithNoWrap(r, nsw, PRT::Signed))},
    {"ShlNuw", CR_OP(l.shlWithNoWrap(r, nuw, PRT::Signed))},
    {"Shl", CR_OP(l.shl(r))},
    {"SubNswNuw", CR_OP(l.subWithNoWrap(r, nsw | nuw, PRT::Signed))},
    {"SubNsw", CR_OP(l.subWithNoWrap(r, nsw, PRT::Signed))},
    {"SubNuw", CR_OP(l.subWithNoWrap(r, nuw, PRT::Signed))},
    {"Sub", CR_OP(l.sub(r))},
    {"UdivExact", CR_OP(l.udiv(r))}, // NOTE: Using flagless fallback
    {"Udiv", CR_OP(l.udiv(r))},
    {"Xor", CR_OP(l.binaryXor(r))},
};

#undef KB_OP
#undef CR_OP

} // namespace llvm

enum class LLVMDomain { KnownBits, UConstRange, SConstRange };

template <LLVMDomain Kind, size_t NumArgs> class LLVMPattern {
  using ValueT = std::conditional_t<Kind == LLVMDomain::KnownBits,
                                    llvm::KnownBits, llvm::ConstantRange>;

  using Xfer = std::conditional_t<Kind == LLVMDomain::KnownBits, llvm::KBXfer,
                                  llvm::CRXfer>;

  struct ArgNode {
    size_t arg;
  };

  struct OpNode {
    std::reference_wrapper<const Xfer> xfer;
    size_t left;
    size_t right;
  };

  using Node = std::variant<ArgNode, OpNode>;

public:
  using ArgArray = std::array<ValueT, NumArgs>;

  ValueT operator()(const ArgArray &args) const {
    assert(!nodes_.empty());
    return eval(nodes_.size() - 1, args);
  }

  std::array<std::uint64_t, 2>
  operator()(const std::array<std::array<std::uint64_t, 2>, NumArgs> &args,
             std::size_t bitwidth) const {
    const ArgArray llvm_args =
        [&]<std::size_t... Is>(std::index_sequence<Is...>) {
          return ArgArray{convert_arg(
              {llvm::APInt(static_cast<unsigned>(bitwidth), args[Is][0]),
               llvm::APInt(static_cast<unsigned>(bitwidth), args[Is][1])})...};
        }(std::make_index_sequence<NumArgs>{});

    return llvm_to_arr((*this)(llvm_args));
  }

  static LLVMPattern parse(std::string_view str) {
    Parser parser{str};
    return LLVMPattern{parser.parse()};
  }

private:
  explicit LLVMPattern(std::vector<Node> nodes) : nodes_(std::move(nodes)) {}

  static const auto &xfer_table() {
    if constexpr (Kind == LLVMDomain::KnownBits)
      return llvm::kb_xfer_table;
    else if constexpr (Kind == LLVMDomain::UConstRange)
      return llvm::ucr_xfer_table;
    else if constexpr (Kind == LLVMDomain::SConstRange)
      return llvm::scr_xfer_table;
  }

  static std::array<uint64_t, 2> llvm_to_arr(ValueT value) {
    if constexpr (Kind == LLVMDomain::KnownBits) {
      return {value.Zero.getZExtValue(), value.One.getZExtValue()};
    } else if constexpr (Kind == LLVMDomain::UConstRange) {
      const unsigned bw = value.getLower().getBitWidth();
      if (value.isFullSet() || value.isWrappedSet())
        return {llvm::APInt::getMinValue(bw).getZExtValue(),
                llvm::APInt::getMaxValue(bw).getZExtValue()};
      if (value.isEmptySet())
        return {llvm::APInt::getMaxValue(bw).getZExtValue(),
                llvm::APInt::getMinValue(bw).getZExtValue()};

      return {value.getLower().getZExtValue(),
              (value.getUpper() - 1).getZExtValue()};
    } else if constexpr (Kind == LLVMDomain::SConstRange) {
      const unsigned bw = value.getLower().getBitWidth();
      if (value.isFullSet() || value.isSignWrappedSet())
        return {llvm::APInt::getSignedMinValue(bw).getZExtValue(),
                llvm::APInt::getSignedMaxValue(bw).getZExtValue()};
      if (value.isEmptySet())
        return {llvm::APInt::getSignedMaxValue(bw).getZExtValue(),
                llvm::APInt::getSignedMinValue(bw).getZExtValue()};

      return {value.getLower().getZExtValue(),
              (value.getUpper() - 1).getZExtValue()};
    }
  }

  static ValueT convert_arg(std::array<llvm::APInt, 2> arg) {
    if constexpr (Kind == LLVMDomain::KnownBits) {
      llvm::KnownBits x = llvm::KnownBits(arg[0].getBitWidth());
      x.Zero = arg[0];
      x.One = arg[1];
      return x;
    } else if constexpr (Kind == LLVMDomain::UConstRange) {
      const unsigned bw = arg[0].getBitWidth();
      if (arg[0].isMinValue() && arg[1].isMaxValue())
        return llvm::ConstantRange::getFull(bw);
      if (arg[0].isMaxValue() && arg[1].isMinValue())
        return llvm::ConstantRange::getEmpty(bw);

      return llvm::ConstantRange(arg[0], arg[1] + 1);
    } else if constexpr (Kind == LLVMDomain::SConstRange) {
      const unsigned bw = arg[0].getBitWidth();
      if (arg[0].isMinSignedValue() && arg[1].isMaxSignedValue())
        return llvm::ConstantRange::getFull(bw);
      if (arg[0].isMaxSignedValue() && arg[1].isMinSignedValue())
        return llvm::ConstantRange::getEmpty(bw);

      return llvm::ConstantRange(arg[0], arg[1] + 1);
    }
  }

  class Parser {
  public:
    explicit Parser(std::string_view str) : str_(str) {}

    std::vector<Node> parse() {
      [[maybe_unused]] const size_t root = parse_expr();

      assert(pos_ == str_.size());
      assert(root + 1 == nodes_.size());

      return std::move(nodes_);
    }

  private:
    std::string_view str_;
    size_t pos_ = 0;
    std::vector<Node> nodes_;

    static bool is_ident_char(char c) {
      const auto uc = static_cast<unsigned char>(c);
      return std::isalnum(uc) != 0 || c == '_';
    }

    void expect(char _) {
      assert(pos_ < str_.size());
      assert(str_[pos_] == _);
      ++pos_;
    }

    std::string_view parse_ident() {
      const size_t start = pos_;

      while (pos_ < str_.size() && is_ident_char(str_[pos_]))
        ++pos_;

      assert(start != pos_);
      return str_.substr(start, pos_ - start);
    }

    static bool is_arg_name(std::string_view name) {
      return name.starts_with("arg");
    }

    static size_t parse_arg_index(std::string_view name) {
      assert(is_arg_name(name));

      size_t arg = 0;
      for (char c : name.substr(3))
        arg = arg * 10 + static_cast<size_t>(c - '0');

      return arg;
    }

    size_t add_node(Node node) {
      const size_t idx = nodes_.size();
      nodes_.push_back(std::move(node));
      return idx;
    }

    size_t parse_expr() {
      const std::string_view name = parse_ident();

      if (is_arg_name(name)) {
        const size_t arg = parse_arg_index(name);
        assert(arg < NumArgs);
        return add_node(ArgNode{arg});
      }

      const auto &table = xfer_table();
      const auto it = table.find(name);
      assert(it != table.end());

      expect('(');
      const size_t left = parse_expr();
      expect(',');
      expect(' ');
      const size_t right = parse_expr();
      expect(')');

      return add_node(OpNode{
          .xfer = std::cref(it->second),
          .left = left,
          .right = right,
      });
    }
  };

  std::vector<Node> nodes_;

  ValueT eval(size_t node_idx, const ArgArray &args) const {
    assert(node_idx < nodes_.size());

    const Node &node = nodes_[node_idx];

    if (const auto *arg = std::get_if<ArgNode>(&node))
      return args[arg->arg];

    const auto &op = std::get<OpNode>(node);

    return op.xfer.get()(eval(op.left, args), eval(op.right, args));
  }
};
