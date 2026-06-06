cmake_minimum_required(VERSION 3.8)
project(exploration_manager)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(path_searching REQUIRED)
find_package(bspline REQUIRED)
find_package(bspline_opt REQUIRED)
find_package(traj_utils REQUIRED)
find_package(active_perception REQUIRED)
find_package(lkh_tsp_solver REQUIRED)
find_package(lkh_mtsp_solver REQUIRED)
find_package(plan_manage REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/DroneState.msg"
  "msg/PairOpt.msg"
  "msg/PairOptResponse.msg"
  "msg/HGrid.msg"
  "msg/GridTour.msg"
  DEPENDENCIES geometry_msgs std_msgs
)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS}
  ${plan_env_INCLUDE_DIRS} ${path_searching_INCLUDE_DIRS} ${bspline_INCLUDE_DIRS}
  ${bspline_opt_INCLUDE_DIRS} ${traj_utils_INCLUDE_DIRS} ${active_perception_INCLUDE_DIRS}
  ${plan_manage_INCLUDE_DIRS} ${lkh_tsp_solver_INCLUDE_DIRS} ${lkh_mtsp_solver_INCLUDE_DIRS})

find_package(NLopt REQUIRED)

set(EXPL_DEPS rclcpp std_msgs geometry_msgs nav_msgs visualization_msgs cv_bridge
  quadrotor_msgs plan_env path_searching bspline bspline_opt traj_utils
  active_perception lkh_tsp_solver lkh_mtsp_solver plan_manage)

add_executable(exploration_node
  src/exploration_node.cpp
  src/fast_exploration_fsm.cpp
  src/fast_exploration_manager.cpp
)
ament_target_dependencies(exploration_node ${EXPL_DEPS})
rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(exploration_node "${cpp_typesupport_target}"
  ${plan_env_LIBRARIES}
  ${path_searching_LIBRARIES}
  ${active_perception_LIBRARIES}
  ${bspline_LIBRARIES}
  ${bspline_opt_LIBRARIES}
  ${traj_utils_LIBRARIES}
  ${plan_manage_LIBRARIES}
  NLopt::nlopt
)

# Disabled: needs extensive ROS2 conversion
#add_executable(ground_node
#  src/ground_node.cpp
#  src/fast_exploration_manager.cpp
#)
#ament_target_dependencies(ground_node ${EXPL_DEPS})
#target_link_libraries(ground_node "${cpp_typesupport_target}")

install(TARGETS exploration_node DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
install(DIRECTORY launch/ DESTINATION share/${PROJECT_NAME}/launch)
install(DIRECTORY config/ DESTINATION share/${PROJECT_NAME}/config OPTIONAL)
install(DIRECTORY resource/ DESTINATION share/${PROJECT_NAME}/resource OPTIONAL)

ament_export_include_directories(include)
ament_export_dependencies(${EXPL_DEPS} rosidl_default_runtime)
ament_package()
