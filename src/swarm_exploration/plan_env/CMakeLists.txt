cmake_minimum_required(VERSION 3.8)
project(plan_env)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(message_filters REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/IdxList.msg"
  "msg/ChunkStamps.msg"
  "msg/ChunkData.msg"
  DEPENDENCIES std_msgs
)

include_directories(
  include
  ${EIGEN3_INCLUDE_DIRS}
  ${PCL_INCLUDE_DIRS}
  ${OpenCV_INCLUDE_DIRS}
)
link_directories(${PCL_LIBRARY_DIRS})

add_library(plan_env_lib
  src/sdf_map.cpp
  src/obj_predictor.cpp
  src/edt_environment.cpp
  src/raycast.cpp
  src/map_ros.cpp
  src/multi_map_manager.cpp
)
ament_target_dependencies(plan_env_lib
  rclcpp std_msgs visualization_msgs cv_bridge message_filters
  sensor_msgs geometry_msgs nav_msgs pcl_conversions
)
target_link_libraries(plan_env_lib ${PCL_LIBRARIES} ${OpenCV_LIBS})

rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(plan_env_lib "${cpp_typesupport_target}")

target_include_directories(plan_env_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

# obj_generator disabled - needs ROS2 conversion
# add_executable(obj_generator src/obj_generator.cpp)
# ament_target_dependencies(obj_generator rclcpp visualization_msgs nav_msgs geometry_msgs sensor_msgs pcl_conversions)
# target_link_libraries(obj_generator ${PCL_LIBRARIES})
# target_include_directories(obj_generator PRIVATE ${PCL_INCLUDE_DIRS})

install(TARGETS plan_env_lib
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
# install(TARGETS obj_generator DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)

ament_export_include_directories(include)
ament_export_libraries(plan_env_lib)
ament_export_dependencies(rclcpp std_msgs visualization_msgs cv_bridge rosidl_default_runtime message_filters nav_msgs sensor_msgs geometry_msgs pcl_conversions)
ament_package()
