cmake_minimum_required(VERSION 3.8)
project(active_perception)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(bspline REQUIRED)
find_package(path_searching REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(PCL 1.7 REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(pcl_conversions REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${plan_env_INCLUDE_DIRS} ${path_searching_INCLUDE_DIRS} ${bspline_INCLUDE_DIRS})

add_library(active_perception
  src/traj_visibility.cpp
  src/heading_planner.cpp
  src/frontier_finder.cpp
  src/graph_node.cpp
  src/perception_utils.cpp
  src/uniform_grid.cpp
  src/hgrid.cpp
)
ament_target_dependencies(active_perception rclcpp std_msgs visualization_msgs plan_env bspline path_searching cv_bridge pcl_conversions)
target_link_libraries(active_perception ${PCL_LIBRARIES})
target_include_directories(active_perception PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS active_perception
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(active_perception)
ament_export_dependencies(rclcpp plan_env bspline path_searching)
ament_package()
