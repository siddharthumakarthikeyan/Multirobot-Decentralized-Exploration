cmake_minimum_required(VERSION 3.8)
project(local_sensing)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(image_transport REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(PCL REQUIRED)

include_directories(
  ${EIGEN3_INCLUDE_DIRS}
  ${OpenCV_INCLUDE_DIRS}
  ${PCL_INCLUDE_DIRS}
)

add_executable(pcl_render_node src/pointcloud_render_node.cpp)
ament_target_dependencies(pcl_render_node rclcpp sensor_msgs geometry_msgs nav_msgs quadrotor_msgs cv_bridge pcl_conversions image_transport)
target_link_libraries(pcl_render_node ${PCL_LIBRARIES} ${OpenCV_LIBS})

install(TARGETS pcl_render_node DESTINATION lib/${PROJECT_NAME})
ament_package()
