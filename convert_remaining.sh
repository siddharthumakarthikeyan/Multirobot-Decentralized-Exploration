#!/bin/bash
set -e
SRC="/home/siddharth/multi_decent_expl/src"

# ============================================================
# lkh_tsp_solver
# ============================================================
cat > "$SRC/swarm_exploration/utils/lkh_tsp_solver/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(lkh_tsp_solver)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/SolveTSP.srv"
  DEPENDENCIES std_msgs
)

include_directories(include ${PROJECT_SOURCE_DIR}/include)

file(GLOB SRCS src/*.c)

add_library(lkh_tsp_solver_lib
  ${SRCS}
  src/lkh_interface.cpp
)
target_link_libraries(lkh_tsp_solver_lib -lm)
target_include_directories(lkh_tsp_solver_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS lkh_tsp_solver_lib
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(lkh_tsp_solver_lib)
ament_export_dependencies(rclcpp rosidl_default_runtime)
ament_package()
EOF

# ============================================================
# lkh_mtsp_solver
# ============================================================
cat > "$SRC/swarm_exploration/utils/lkh_mtsp_solver/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>lkh_mtsp_solver</name>
  <version>0.0.0</version>
  <description>LKH MTSP solver</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/utils/lkh_mtsp_solver/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(lkh_mtsp_solver)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/SolveMTSP.srv"
  DEPENDENCIES std_msgs
)

include_directories(include ${PROJECT_SOURCE_DIR}/include)

file(GLOB SRCS src/*.c)

add_library(lkh_mtsp_solver_lib
  ${SRCS}
  src2/lkh3_interface.cpp
)
target_link_libraries(lkh_mtsp_solver_lib -lm)
target_include_directories(lkh_mtsp_solver_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

add_executable(mtsp_node src2/mtsp_node.cpp)
ament_target_dependencies(mtsp_node rclcpp std_msgs)
target_link_libraries(mtsp_node lkh_mtsp_solver_lib -lm)
rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(mtsp_node "${cpp_typesupport_target}")

install(TARGETS lkh_mtsp_solver_lib
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS mtsp_node DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(lkh_mtsp_solver_lib)
ament_export_dependencies(rclcpp rosidl_default_runtime)
ament_package()
EOF

# Update lkh_tsp_solver package.xml (already partially done)
cat > "$SRC/swarm_exploration/utils/lkh_tsp_solver/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>lkh_tsp_solver</name>
  <version>0.0.0</version>
  <description>LKH TSP solver</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

# ============================================================
# plan_manage
# ============================================================
cat > "$SRC/swarm_exploration/plan_manage/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>plan_manage</name>
  <version>0.0.0</version>
  <description>Planning manager</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>plan_env</depend>
  <depend>path_searching</depend>
  <depend>bspline</depend>
  <depend>bspline_opt</depend>
  <depend>active_perception</depend>
  <depend>traj_utils</depend>
  <depend>poly_traj</depend>
  <depend>quadrotor_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/plan_manage/CMakeLists.txt" << 'EOF'
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

set(NLOPT_INCLUDE_DIR "/usr/local/include")
set(NLOPT_LIBRARY "/usr/local/lib/libnlopt.so")

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${NLOPT_INCLUDE_DIR})

set(PLAN_MANAGE_DEPS rclcpp std_msgs visualization_msgs geometry_msgs nav_msgs
  cv_bridge plan_env path_searching bspline bspline_opt active_perception
  traj_utils poly_traj quadrotor_msgs)

add_library(plan_manage
  src/planner_manager.cpp
  src/fast_planner_manager.cpp
)
ament_target_dependencies(plan_manage ${PLAN_MANAGE_DEPS})
target_link_libraries(plan_manage ${NLOPT_LIBRARY} ${PCL_LIBRARIES})
target_include_directories(plan_manage PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

add_executable(traj_server src/traj_server.cpp)
ament_target_dependencies(traj_server ${PLAN_MANAGE_DEPS})
target_link_libraries(traj_server plan_manage)

add_executable(send_cmd src/send_cmd.cpp)
ament_target_dependencies(send_cmd ${PLAN_MANAGE_DEPS})
target_link_libraries(send_cmd plan_manage)

install(TARGETS plan_manage
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS traj_server send_cmd DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
install(DIRECTORY launch/ DESTINATION share/${PROJECT_NAME}/launch)
ament_export_include_directories(include)
ament_export_libraries(plan_manage)
ament_export_dependencies(${PLAN_MANAGE_DEPS})
ament_package()
EOF

# ============================================================
# exploration_manager
# ============================================================
cat > "$SRC/swarm_exploration/exploration_manager/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>exploration_manager</name>
  <version>0.0.0</version>
  <description>Exploration manager</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>quadrotor_msgs</depend>
  <depend>plan_env</depend>
  <depend>path_searching</depend>
  <depend>bspline</depend>
  <depend>bspline_opt</depend>
  <depend>traj_utils</depend>
  <depend>active_perception</depend>
  <depend>lkh_tsp_solver</depend>
  <depend>lkh_mtsp_solver</depend>
  <depend>plan_manage</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/exploration_manager/CMakeLists.txt" << 'EOF'
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

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})

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
target_link_libraries(exploration_node "${cpp_typesupport_target}")

add_executable(ground_node
  src/ground_node.cpp
  src/fast_exploration_manager.cpp
)
ament_target_dependencies(ground_node ${EXPL_DEPS})
target_link_libraries(ground_node "${cpp_typesupport_target}")

install(TARGETS exploration_node ground_node DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
install(DIRECTORY launch/ DESTINATION share/${PROJECT_NAME}/launch)
install(DIRECTORY config/ DESTINATION share/${PROJECT_NAME}/config OPTIONAL)
install(DIRECTORY resource/ DESTINATION share/${PROJECT_NAME}/resource OPTIONAL)

ament_export_include_directories(include)
ament_export_dependencies(${EXPL_DEPS} rosidl_default_runtime)
ament_package()
EOF

# ============================================================
# map_generator
# ============================================================
cat > "$SRC/uav_simulator/map_generator/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>map_generator</name>
  <version>0.0.0</version>
  <description>Map generator</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>sensor_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>pcl_conversions</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/map_generator/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(map_generator)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)

include_directories(${EIGEN3_INCLUDE_DIR} ${PCL_INCLUDE_DIRS})
link_directories(${PCL_LIBRARY_DIRS})

set(MAP_DEPS rclcpp sensor_msgs geometry_msgs nav_msgs visualization_msgs pcl_conversions)

add_executable(map_pub src/map_publisher.cpp)
ament_target_dependencies(map_pub ${MAP_DEPS})
target_link_libraries(map_pub ${PCL_LIBRARIES})

add_executable(click_map src/click_map.cpp)
ament_target_dependencies(click_map ${MAP_DEPS})
target_link_libraries(click_map ${PCL_LIBRARIES})

add_executable(map_recorder src/map_recorder.cpp)
ament_target_dependencies(map_recorder ${MAP_DEPS})
target_link_libraries(map_recorder ${PCL_LIBRARIES})

add_executable(random_forest src/random_forest_sensing.cpp)
ament_target_dependencies(random_forest ${MAP_DEPS})
target_link_libraries(random_forest ${PCL_LIBRARIES})

install(TARGETS map_pub click_map map_recorder random_forest DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY resource/ DESTINATION share/${PROJECT_NAME}/resource)
ament_package()
EOF

# ============================================================
# so3_control
# ============================================================
cat > "$SRC/uav_simulator/so3_control/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>so3_control</name>
  <version>0.0.0</version>
  <description>SO3 controller</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>nav_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>quadrotor_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>tf2_ros</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/so3_control/CMakeLists.txt" << 'EOF'
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
EOF

# ============================================================
# so3_disturbance_generator
# ============================================================
cat > "$SRC/uav_simulator/so3_disturbance_generator/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>so3_disturbance_generator</name>
  <version>0.0.0</version>
  <description>SO3 disturbance generator</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_geometry_msgs</depend>
  <depend>pose_utils</depend>
  <depend>quadrotor_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/so3_disturbance_generator/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(so3_disturbance_generator)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(pose_utils REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Armadillo REQUIRED)

include_directories(include ${ARMADILLO_INCLUDE_DIRS})

add_executable(so3_disturbance_generator src/so3_disturbance_generator.cpp)
ament_target_dependencies(so3_disturbance_generator rclcpp std_msgs sensor_msgs nav_msgs visualization_msgs tf2_ros tf2_geometry_msgs pose_utils quadrotor_msgs)
target_link_libraries(so3_disturbance_generator ${ARMADILLO_LIBRARIES})

install(TARGETS so3_disturbance_generator DESTINATION lib/${PROJECT_NAME})
ament_package()
EOF

# ============================================================
# so3_quadrotor_simulator
# ============================================================
cat > "$SRC/uav_simulator/so3_quadrotor_simulator/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>so3_quadrotor_simulator</name>
  <version>0.0.0</version>
  <description>SO3 quadrotor simulator</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>quadrotor_msgs</depend>
  <depend>uav_utils</depend>
  <depend>nav_msgs</depend>
  <depend>sensor_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/so3_quadrotor_simulator/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(so3_quadrotor_simulator)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(uav_utils REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Armadillo REQUIRED)

include_directories(
  include
  ${CMAKE_CURRENT_SOURCE_DIR}/include/ode
  ${EIGEN3_INCLUDE_DIR}
  ${ARMADILLO_INCLUDE_DIRS}
)

add_library(quadrotor_dynamics src/dynamics/Quadrotor.cpp)
ament_target_dependencies(quadrotor_dynamics rclcpp)
target_include_directories(quadrotor_dynamics PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

add_executable(quadrotor_simulator_so3 src/quadrotor_simulator_so3.cpp)
ament_target_dependencies(quadrotor_simulator_so3 rclcpp quadrotor_msgs uav_utils nav_msgs sensor_msgs)
target_link_libraries(quadrotor_simulator_so3 quadrotor_dynamics)

install(TARGETS quadrotor_dynamics
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS quadrotor_simulator_so3 DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
install(DIRECTORY launch/ DESTINATION share/${PROJECT_NAME}/launch)
ament_package()
EOF

# ============================================================
# poscmd_2_odom
# ============================================================
cat > "$SRC/uav_simulator/poscmd_2_odom/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>poscmd_2_odom</name>
  <version>0.0.0</version>
  <description>Position command to odometry converter</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>nav_msgs</depend>
  <depend>quadrotor_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/poscmd_2_odom/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(poscmd_2_odom)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Eigen3 REQUIRED)

include_directories(${EIGEN3_INCLUDE_DIR})

add_executable(poscmd_2_odom src/poscmd_2_odom.cpp)
ament_target_dependencies(poscmd_2_odom rclcpp nav_msgs quadrotor_msgs)

install(TARGETS poscmd_2_odom DESTINATION lib/${PROJECT_NAME})
ament_package()
EOF

# ============================================================
# local_sensing (non-CUDA path only)
# ============================================================
cat > "$SRC/uav_simulator/local_sensing/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>local_sensing</name>
  <version>0.0.0</version>
  <description>Local sensing simulation</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>sensor_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>quadrotor_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>pcl_conversions</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/local_sensing/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(local_sensing_node)
set(CMAKE_CXX_STANDARD 17)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(PCL REQUIRED)

include_directories(
  ${EIGEN3_INCLUDE_DIRS}
  ${OpenCV_INCLUDE_DIRS}
  ${PCL_INCLUDE_DIRS}
)

add_executable(pcl_render_node src/pointcloud_render_node.cpp)
ament_target_dependencies(pcl_render_node rclcpp sensor_msgs geometry_msgs nav_msgs quadrotor_msgs cv_bridge pcl_conversions)
target_link_libraries(pcl_render_node ${PCL_LIBRARIES} ${OpenCV_LIBS})

install(TARGETS pcl_render_node DESTINATION lib/${PROJECT_NAME})
ament_package()
EOF

# ============================================================
# rviz_plugins (for rviz2)
# ============================================================
cat > "$SRC/uav_simulator/Utils/rviz_plugins/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>rviz_plugins</name>
  <version>0.0.0</version>
  <description>Custom rviz2 plugins</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rviz_common</depend>
  <depend>rviz_default_plugins</depend>
  <depend>rviz_rendering</depend>
  <depend>pluginlib</depend>
  <depend>geometry_msgs</depend>
  <depend>multi_map_server</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_geometry_msgs</depend>
  <export>
    <build_type>ament_cmake</build_type>
    <rviz plugin="${prefix}/plugin_description.xml"/>
  </export>
</package>
EOF

cat > "$SRC/uav_simulator/Utils/rviz_plugins/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(rviz_plugins)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rviz_common REQUIRED)
find_package(rviz_default_plugins REQUIRED)
find_package(rviz_rendering REQUIRED)
find_package(pluginlib REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(multi_map_server REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(Qt5 REQUIRED COMPONENTS Core Widgets)

add_definitions(-DQT_NO_KEYWORDS)

include_directories(include src)

# Note: The rviz plugins source files need significant rewriting for rviz2.
# For now, we create a placeholder library. The actual plugin sources
# need to be ported from rviz to rviz_common API.
# add_library(${PROJECT_NAME} SHARED
#   src/pose_tool.cpp
#   src/goal_tool.cpp
#   src/probmap_display.cpp
#   src/aerialmap_display.cpp
#   src/multi_probmap_display.cpp
# )
# ament_target_dependencies(${PROJECT_NAME} rclcpp rviz_common rviz_default_plugins rviz_rendering pluginlib geometry_msgs multi_map_server tf2_ros tf2_geometry_msgs)
# target_link_libraries(${PROJECT_NAME} Qt5::Widgets)

# install(TARGETS ${PROJECT_NAME}
#   ARCHIVE DESTINATION lib
#   LIBRARY DESTINATION lib
#   RUNTIME DESTINATION bin
# )
# install(FILES plugin_description.xml DESTINATION share/${PROJECT_NAME})

ament_package()
EOF

echo "=== All remaining packages converted ==="
