cmake_minimum_required(VERSION 3.8)
project(cmake_utils)

find_package(ament_cmake REQUIRED)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

install(DIRECTORY cmake/
  DESTINATION share/${PROJECT_NAME}/cmake
)

ament_package()
