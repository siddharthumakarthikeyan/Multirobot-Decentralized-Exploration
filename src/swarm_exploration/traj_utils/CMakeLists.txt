cmake_minimum_required(VERSION 3.8)
project(traj_utils)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(bspline REQUIRED)
find_package(bspline_opt REQUIRED)
find_package(path_searching REQUIRED)
find_package(poly_traj REQUIRED)
find_package(plan_env REQUIRED)
find_package(active_perception REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${bspline_INCLUDE_DIRS} ${bspline_opt_INCLUDE_DIRS} ${path_searching_INCLUDE_DIRS} ${poly_traj_INCLUDE_DIRS} ${plan_env_INCLUDE_DIRS} ${active_perception_INCLUDE_DIRS})
link_directories(${PCL_LIBRARY_DIRS})

add_library(traj_utils src/planning_visualization.cpp)
ament_target_dependencies(traj_utils rclcpp std_msgs cv_bridge bspline bspline_opt path_searching poly_traj visualization_msgs)
target_include_directories(traj_utils PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS traj_utils
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(traj_utils)
ament_export_dependencies(rclcpp bspline bspline_opt path_searching poly_traj)
ament_package()
