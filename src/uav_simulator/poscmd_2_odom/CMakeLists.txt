cmake_minimum_required(VERSION 3.8)
project(poscmd_2_odom)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(${EIGEN3_INCLUDE_DIR})

add_executable(poscmd_2_odom src/poscmd_2_odom.cpp)
ament_target_dependencies(poscmd_2_odom rclcpp nav_msgs quadrotor_msgs tf2_ros geometry_msgs)

install(TARGETS poscmd_2_odom DESTINATION lib/${PROJECT_NAME})
ament_package()
