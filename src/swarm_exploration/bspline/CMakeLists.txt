cmake_minimum_required(VERSION 3.8)
project(bspline)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(builtin_interfaces REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Bspline.msg"
  DEPENDENCIES std_msgs geometry_msgs builtin_interfaces
)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})

add_library(bspline_lib src/non_uniform_bspline.cpp)
ament_target_dependencies(bspline_lib rclcpp std_msgs visualization_msgs plan_env cv_bridge)
target_include_directories(bspline_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(bspline_lib "${cpp_typesupport_target}")

install(TARGETS bspline_lib
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(bspline_lib)
ament_export_dependencies(rclcpp rosidl_default_runtime)
ament_package()
