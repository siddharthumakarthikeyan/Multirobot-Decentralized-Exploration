cmake_minimum_required(VERSION 3.8)
project(plan_manage)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(plan_env REQUIRED)
find_package(path_searching REQUIRED)
find_package(bspline REQUIRED)
find_package(bspline_opt REQUIRED)
find_package(active_perception REQUIRED)
find_package(traj_utils REQUIRED)
find_package(poly_traj REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)
find_package(pcl_conversions REQUIRED)

set(NLOPT_INCLUDE_DIR "/usr/local/include")
set(NLOPT_LIBRARY "/usr/local/lib/libnlopt.so")

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${NLOPT_INCLUDE_DIR}
  ${plan_env_INCLUDE_DIRS} ${path_searching_INCLUDE_DIRS} ${bspline_INCLUDE_DIRS}
  ${bspline_opt_INCLUDE_DIRS} ${active_perception_INCLUDE_DIRS} ${traj_utils_INCLUDE_DIRS}
  ${poly_traj_INCLUDE_DIRS})

set(PLAN_MANAGE_DEPS rclcpp std_msgs visualization_msgs geometry_msgs nav_msgs
  cv_bridge pcl_conversions plan_env path_searching bspline bspline_opt active_perception
  traj_utils poly_traj quadrotor_msgs)

add_library(plan_manage
  src/planner_manager.cpp
)
ament_target_dependencies(plan_manage ${PLAN_MANAGE_DEPS})
target_link_libraries(plan_manage ${NLOPT_LIBRARY} ${PCL_LIBRARIES})
target_include_directories(plan_manage PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

add_executable(traj_server src/traj_server.cpp)
ament_target_dependencies(traj_server ${PLAN_MANAGE_DEPS})
target_link_libraries(traj_server plan_manage ${bspline_LIBRARIES} ${plan_env_LIBRARIES})

# Disabled: needs swarmtal_msgs which is not in the workspace
#add_executable(send_cmd src/send_cmd.cpp)
#ament_target_dependencies(send_cmd ${PLAN_MANAGE_DEPS})
#target_link_libraries(send_cmd plan_manage)

install(TARGETS plan_manage
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS traj_server DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
install(DIRECTORY launch/ DESTINATION share/${PROJECT_NAME}/launch)
ament_export_include_directories(include)
ament_export_libraries(plan_manage)
ament_export_dependencies(${PLAN_MANAGE_DEPS})
ament_package()
