cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "rust_lib_nasbeat")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} ../../../../../../rust rust_lib_nasbeat "")

set(rust_lib_nasbeat_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
