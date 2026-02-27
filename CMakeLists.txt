cmake_minimum_required(VERSION 3.20)
project(synth_xfer LANGUAGES CXX)

if(NOT CMAKE_CXX_COMPILER_ID)
  message(FATAL_ERROR "CMAKE_CXX_COMPILER_ID is not set; cannot detect C++ compiler.")
endif()

if(NOT (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"))
  message(FATAL_ERROR
    "synth_xfer must be built with Clang or AppleClang, "
    "but CMAKE_CXX_COMPILER_ID='${CMAKE_CXX_COMPILER_ID}'.")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(SYNTH_XFER_WIDTHS_PER_SHARD "8" CACHE STRING
    "Number of widths compiled per generated shard TU")

find_package(pybind11 CONFIG REQUIRED)

set(_SYNTH_XFER_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${_SYNTH_XFER_GENERATED_DIR}")

set(_SYNTH_XFER_ARITIES_INC "${_SYNTH_XFER_GENERATED_DIR}/build_matrix_arities.inc")
set(_arities_inc_content "")
foreach(_arity IN LISTS SYNTH_XFER_ARITIES)
  string(APPEND _arities_inc_content
    "  register_uniform_arity<Dom, BW, ${_arity}>(m);\n")
endforeach()
file(WRITE "${_SYNTH_XFER_ARITIES_INC}" "${_arities_inc_content}")

set(SYNTH_XFER_DOMAIN_SPECS
  "knownbits|KnownBits|knownbits.hpp|register_knownbits_bindings"
  "uconst_range|UConstRange|uconst_range.hpp|register_uconst_range_bindings"
  "sconst_range|SConstRange|sconst_range.hpp|register_sconst_range_bindings"
  "mod3|Mod3|mod.hpp|register_mod3_bindings"
  "mod5|Mod5|mod.hpp|register_mod5_bindings"
  "mod7|Mod7|mod.hpp|register_mod7_bindings"
  "mod11|Mod11|mod.hpp|register_mod11_bindings"
  "mod13|Mod13|mod.hpp|register_mod13_bindings")

function(synth_xfer_generate_opaque_lines DOMAIN_TYPE WIDTHS ARITIES OUT_VAR)
  set(_opaque_lines "")
  foreach(_opaque_width IN LISTS WIDTHS)
    foreach(_arity IN LISTS ARITIES)
      set(_toeval_bw_list "${_opaque_width}")
      foreach(_n RANGE 1 ${_arity})
        string(APPEND _toeval_bw_list ", ${_opaque_width}")
      endforeach()

      set(_argsvec_bw_list "")
      foreach(_n RANGE 1 ${_arity})
        if(_n EQUAL 1)
          set(_argsvec_bw_list "${_opaque_width}")
        else()
          string(APPEND _argsvec_bw_list ", ${_opaque_width}")
        endif()
      endforeach()

      string(APPEND _opaque_lines
        "PYBIND11_MAKE_OPAQUE(DomainHelpers::ToEval<${DOMAIN_TYPE}, ${_toeval_bw_list}>);\n")
      string(APPEND _opaque_lines
        "PYBIND11_MAKE_OPAQUE(DomainHelpers::ArgsVec<${DOMAIN_TYPE}, ${_argsvec_bw_list}>);\n")
    endforeach()
  endforeach()
  set(${OUT_VAR} "${_opaque_lines}" PARENT_SCOPE)
endfunction()

function(synth_xfer_emit_domain_shard
    GENERATED_BINDINGS_DIR
    DOMAIN_KEY
    DOMAIN_HEADER
    DOMAIN_TYPE
    REGISTER_FN
    SHARD_IDX
    WIDTHS
    ARITIES
    OUT_SHARD_SRC
    OUT_DECL_LINE
    OUT_CALL_LINE)
  set(_shard_fn "${REGISTER_FN}_shard_${SHARD_IDX}")
  set(_shard_src "${GENERATED_BINDINGS_DIR}/bindings_${DOMAIN_KEY}_shard_${SHARD_IDX}.cpp")
  string(JOIN ", " _width_csv ${WIDTHS})
  synth_xfer_generate_opaque_lines("${DOMAIN_TYPE}" "${WIDTHS}" "${ARITIES}" _opaque_lines)

  set(_tpl_domain_header "${DOMAIN_HEADER}")
  set(_tpl_opaque_lines "${_opaque_lines}")
  set(_tpl_shard_fn "${_shard_fn}")
  set(_tpl_width_csv "${_width_csv}")
  set(_tpl_domain_type "${DOMAIN_TYPE}")
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/templates/binding_domain_shard.cpp.in"
    "${_shard_src}"
    @ONLY)

  set(${OUT_SHARD_SRC} "${_shard_src}" PARENT_SCOPE)
  set(${OUT_DECL_LINE} "void ${_shard_fn}(py::module_ &m);\n" PARENT_SCOPE)
  set(${OUT_CALL_LINE} "  ${_shard_fn}(m);\n" PARENT_SCOPE)
endfunction()

set(SYNTH_XFER_GENERATED_DOMAIN_BINDING_SOURCES "")
set(_SYNTH_XFER_GENERATED_BINDINGS_DIR
    "${_SYNTH_XFER_GENERATED_DIR}/bindings/domains")
file(MAKE_DIRECTORY "${_SYNTH_XFER_GENERATED_BINDINGS_DIR}")

foreach(_domain_spec IN LISTS SYNTH_XFER_DOMAIN_SPECS)
  string(REPLACE "|" ";" _domain_fields "${_domain_spec}")
  list(GET _domain_fields 0 _domain_key)
  list(GET _domain_fields 1 _domain_type)
  list(GET _domain_fields 2 _domain_header)
  list(GET _domain_fields 3 _register_fn)

  set(_base_src "${_SYNTH_XFER_GENERATED_BINDINGS_DIR}/bindings_${_domain_key}.cpp")
  list(APPEND SYNTH_XFER_GENERATED_DOMAIN_BINDING_SOURCES "${_base_src}")

  list(FIND SYNTH_XFER_DOMAINS "${_domain_key}" _domain_enabled_idx)
  if(_domain_enabled_idx EQUAL -1)
    set(_tpl_register_fn "${_register_fn}")
    configure_file(
      "${CMAKE_CURRENT_SOURCE_DIR}/cmake/templates/binding_domain_stub.cpp.in"
      "${_base_src}"
      @ONLY)
    continue()
  endif()

  set(_decl_lines "")
  set(_call_lines "")
  set(_shard_idx 0)
  set(_current_shard_widths "")

  foreach(_width IN LISTS SYNTH_XFER_WIDTHS)
    list(APPEND _current_shard_widths "${_width}")
    list(LENGTH _current_shard_widths _current_shard_len)

    if(_current_shard_len EQUAL SYNTH_XFER_WIDTHS_PER_SHARD)
      synth_xfer_emit_domain_shard(
        "${_SYNTH_XFER_GENERATED_BINDINGS_DIR}"
        "${_domain_key}"
        "${_domain_header}"
        "${_domain_type}"
        "${_register_fn}"
        "${_shard_idx}"
        "${_current_shard_widths}"
        "${SYNTH_XFER_ARITIES}"
        _shard_src
        _decl_line
        _call_line)
      list(APPEND SYNTH_XFER_GENERATED_DOMAIN_BINDING_SOURCES "${_shard_src}")
      string(APPEND _decl_lines "${_decl_line}")
      string(APPEND _call_lines "${_call_line}")

      set(_current_shard_widths "")
      math(EXPR _shard_idx "${_shard_idx} + 1")
    endif()
  endforeach()

  if(_current_shard_widths)
    synth_xfer_emit_domain_shard(
      "${_SYNTH_XFER_GENERATED_BINDINGS_DIR}"
      "${_domain_key}"
      "${_domain_header}"
      "${_domain_type}"
      "${_register_fn}"
      "${_shard_idx}"
      "${_current_shard_widths}"
      "${SYNTH_XFER_ARITIES}"
      _shard_src
      _decl_line
      _call_line)
    list(APPEND SYNTH_XFER_GENERATED_DOMAIN_BINDING_SOURCES "${_shard_src}")
    string(APPEND _decl_lines "${_decl_line}")
    string(APPEND _call_lines "${_call_line}")
  endif()

  set(_tpl_decl_lines "${_decl_lines}")
  set(_tpl_register_fn "${_register_fn}")
  set(_tpl_call_lines "${_call_lines}")
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/templates/binding_domain_base.cpp.in"
    "${_base_src}"
    @ONLY)
endforeach()

message(STATUS "Build matrix domains: ${SYNTH_XFER_DOMAINS}")
message(STATUS "Build matrix function arities: ${SYNTH_XFER_ARITIES}")
message(STATUS "Build matrix widths: ${SYNTH_XFER_WIDTHS}")
message(STATUS "Widths per shard: ${SYNTH_XFER_WIDTHS_PER_SHARD}")

set(SYNTH_XFER_SOURCES
  cpp/core/apint.hpp
  cpp/core/apint_inst.cpp
  cpp/core/domain.hpp
  cpp/core/enum.hpp
  cpp/core/eval.hpp
  cpp/core/rand.hpp

  cpp/domains/knownbits.hpp
  cpp/domains/mod.hpp
  cpp/domains/uconst_range.hpp
  cpp/domains/sconst_range.hpp

  cpp/bindings/bindings.cpp
  cpp/bindings/bindings_common.hpp
  cpp/bindings/bindings_helpers.cpp
  ${SYNTH_XFER_GENERATED_DOMAIN_BINDING_SOURCES}
)

pybind11_add_module(_eval_engine NO_EXTRAS ${SYNTH_XFER_SOURCES})
target_include_directories(_eval_engine PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/cpp/core
  ${CMAKE_CURRENT_SOURCE_DIR}/cpp/domains
  ${CMAKE_CURRENT_SOURCE_DIR}/cpp/bindings
  ${_SYNTH_XFER_GENERATED_DIR}
)
target_link_libraries(_eval_engine PRIVATE pybind11::headers)
target_compile_features(_eval_engine PRIVATE cxx_std_20)
set_target_properties(_eval_engine PROPERTIES CXX_EXTENSIONS OFF)

target_compile_options(_eval_engine PRIVATE
  -Wall
  -Wextra
  -Wpedantic
  -Werror
  -Wshadow
  -Wconversion
  -Wsign-conversion
  -Wold-style-cast
  -Wcast-qual
  -Wformat=2
  -Wno-unused-command-line-argument
  -O3
  -DNDEBUG
  -fstrict-enums
)

# Add BMI2 when available on x86_64
include(CheckCXXCompilerFlag)
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
  check_cxx_compiler_flag(-mbmi2 HAS_MBMI2)
  if(HAS_MBMI2)
    target_compile_options(_eval_engine PRIVATE -mbmi2)
  endif()
endif()

if(APPLE AND CMAKE_OSX_ARCHITECTURES MATCHES ".+;.+")
  message(STATUS "Skipping -march=native for universal (multi-arch) build.")
else()
  target_compile_options(_eval_engine PRIVATE -march=native)
endif()

install(TARGETS _eval_engine DESTINATION synth_xfer)
