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
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

find_package(pybind11 CONFIG REQUIRED)

set(SYNTH_XFER_SOURCES
  cpp/apint.hpp
  cpp/bindings.cpp
  cpp/eval.hpp
  cpp/enum.hpp
  cpp/domain.hpp
  cpp/knownbits.hpp
  cpp/uconst_range.hpp
  cpp/sconst_range.hpp
  cpp/rand.hpp
)

pybind11_add_module(_eval_engine ${SYNTH_XFER_SOURCES})
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

include(CheckCXXCompilerFlag)
check_cxx_compiler_flag(-flto HAS_FLTO)
if(HAS_FLTO)
  target_compile_options(_eval_engine PRIVATE -flto)
  target_link_options(_eval_engine PRIVATE -flto)
endif()

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported OUTPUT ipo_msg)
if(ipo_supported)
  set_property(TARGET _eval_engine PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
  message(STATUS "IPO/LTO not supported: ${ipo_msg}")
endif()

install(TARGETS _eval_engine DESTINATION synth_xfer)
