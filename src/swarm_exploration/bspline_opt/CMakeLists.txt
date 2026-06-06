cmake_minimum_required(VERSION 3.8)
project(bspline_opt)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(active_perception REQUIRED)
find_package(bspline REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

set(NLOPT_INCLUDE_DIR "/usr/local/include")
set(NLOPT_LIBRARY "/usr/local/lib/libnlopt.so")

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${NLOPT_INCLUDE_DIR} ${plan_env_INCLUDE_DIRS} ${active_perception_INCLUDE_DIRS} ${bspline_INCLUDE_DIRS})

add_library(bspline_opt src/bspline_optimizer.cpp)
ament_target_dependencies(bspline_opt rclcpp std_msgs visualization_msgs plan_env active_perception bspline cv_bridge)
target_link_libraries(bspline_opt ${NLOPT_LIBRARY})
target_include_directories(bspline_opt PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS bspline_opt
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(bspline_opt)
ament_export_dependencies(rclcpp plan_env active_perception)
ament_package()
