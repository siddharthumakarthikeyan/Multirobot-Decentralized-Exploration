cmake_minimum_required(VERSION 3.8)
project(multi_map_server)

set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(pose_utils REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Armadillo REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/MultiOccupancyGrid.msg"
  "msg/MultiSparseMap3D.msg"
  "msg/SparseMap3D.msg"
  "msg/VerticalOccupancyGridList.msg"
  DEPENDENCIES geometry_msgs nav_msgs std_msgs
)

include_directories(
  include
  ${ARMADILLO_INCLUDE_DIRS}
)

add_executable(multi_map_visualization src/multi_map_visualization.cc)
ament_target_dependencies(multi_map_visualization
  rclcpp geometry_msgs nav_msgs visualization_msgs
  tf2_ros tf2_geometry_msgs pose_utils quadrotor_msgs
)
target_link_libraries(multi_map_visualization ${ARMADILLO_LIBRARIES})

rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(multi_map_visualization "${cpp_typesupport_target}")

install(TARGETS multi_map_visualization
  DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY include/
  DESTINATION include
)

ament_export_include_directories(include)
ament_export_dependencies(rclcpp geometry_msgs nav_msgs quadrotor_msgs rosidl_default_runtime)

ament_package()
