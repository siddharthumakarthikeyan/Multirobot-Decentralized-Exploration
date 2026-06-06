cmake_minimum_required(VERSION 3.8)
project(so3_control)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(Eigen3 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIR})

add_library(SO3Control src/SO3Control.cpp)
ament_target_dependencies(SO3Control rclcpp)
target_include_directories(SO3Control PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

add_executable(so3_control_node src/so3_control_nodelet.cpp)
ament_target_dependencies(so3_control_node rclcpp nav_msgs sensor_msgs quadrotor_msgs geometry_msgs tf2_ros)
target_link_libraries(so3_control_node SO3Control)

install(TARGETS SO3Control
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS so3_control_node DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(SO3Control)
ament_package()
