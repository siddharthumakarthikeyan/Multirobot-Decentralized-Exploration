cmake_minimum_required(VERSION 3.8)
project(poly_traj)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})

add_library(poly_traj src/polynomial_traj.cpp)
ament_target_dependencies(poly_traj rclcpp std_msgs quadrotor_msgs visualization_msgs)

# traj_generator disabled - requires swarmtal_msgs
# add_executable(traj_generator src/traj_generator.cpp)
# ament_target_dependencies(traj_generator rclcpp std_msgs quadrotor_msgs visualization_msgs)
# target_link_libraries(traj_generator poly_traj)

target_include_directories(poly_traj PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS poly_traj
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
# install(TARGETS traj_generator DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(poly_traj)
ament_export_dependencies(rclcpp std_msgs quadrotor_msgs)
ament_package()
