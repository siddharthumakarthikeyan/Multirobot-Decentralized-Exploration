#!/bin/bash
# Batch convert all remaining package.xml and CMakeLists.txt files
set -e

SRC="/home/siddharth/multi_decent_expl/src"

# ============================================================
# odom_visualization
# ============================================================
cat > "$SRC/uav_simulator/Utils/odom_visualization/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>odom_visualization</name>
  <version>0.0.0</version>
  <description>Odometry visualization</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>sensor_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>quadrotor_msgs</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_geometry_msgs</depend>
  <depend>pose_utils</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/Utils/odom_visualization/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(odom_visualization)
set(CMAKE_CXX_STANDARD 17)
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(pose_utils REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Armadillo REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIR})

add_executable(odom_visualization src/odom_visualization.cpp)
ament_target_dependencies(odom_visualization rclcpp sensor_msgs nav_msgs visualization_msgs quadrotor_msgs tf2_ros tf2_geometry_msgs pose_utils)
target_link_libraries(odom_visualization ${ARMADILLO_LIBRARIES})

install(TARGETS odom_visualization DESTINATION lib/${PROJECT_NAME})
ament_package()
EOF

# ============================================================
# waypoint_generator
# ============================================================
cat > "$SRC/uav_simulator/Utils/waypoint_generator/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>waypoint_generator</name>
  <version>0.0.0</version>
  <description>Waypoint generator</description>
  <maintainer email="todo@todo.todo">todo</maintainer>
  <license>BSD</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>nav_msgs</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_geometry_msgs</depend>
  <depend>geometry_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/uav_simulator/Utils/waypoint_generator/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(waypoint_generator)
set(CMAKE_CXX_STANDARD 17)
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

add_executable(waypoint_generator src/waypoint_generator.cpp)
ament_target_dependencies(waypoint_generator rclcpp nav_msgs tf2_ros tf2_geometry_msgs geometry_msgs)

install(TARGETS waypoint_generator DESTINATION lib/${PROJECT_NAME})
ament_package()
EOF

# ============================================================
# plan_env
# ============================================================
cat > "$SRC/swarm_exploration/plan_env/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>plan_env</name>
  <version>0.0.0</version>
  <description>Planning environment</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>message_filters</depend>
  <depend>sensor_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/plan_env/CMakeLists.txt" << 'EOF'
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

add_library(plan_env
  src/sdf_map.cpp
  src/obj_predictor.cpp
  src/edt_environment.cpp
  src/raycast.cpp
  src/map_ros.cpp
  src/multi_map_manager.cpp
)
ament_target_dependencies(plan_env
  rclcpp std_msgs visualization_msgs cv_bridge message_filters
  sensor_msgs geometry_msgs nav_msgs
)
target_link_libraries(plan_env ${PCL_LIBRARIES} ${OpenCV_LIBS})

rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(plan_env "${cpp_typesupport_target}")

target_include_directories(plan_env PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

add_executable(obj_generator src/obj_generator.cpp)
ament_target_dependencies(obj_generator rclcpp visualization_msgs)

install(TARGETS plan_env
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS obj_generator DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)

ament_export_include_directories(include)
ament_export_libraries(plan_env)
ament_export_dependencies(rclcpp std_msgs visualization_msgs cv_bridge rosidl_default_runtime)
ament_package()
EOF

# ============================================================
# poly_traj
# ============================================================
cat > "$SRC/swarm_exploration/poly_traj/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>poly_traj</name>
  <version>0.0.0</version>
  <description>Polynomial trajectory</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>quadrotor_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/poly_traj/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(poly_traj)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(quadrotor_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})

add_library(poly_traj src/polynomial_traj.cpp)
ament_target_dependencies(poly_traj rclcpp std_msgs quadrotor_msgs)

add_executable(traj_generator src/traj_generator.cpp)
ament_target_dependencies(traj_generator rclcpp std_msgs quadrotor_msgs)
target_link_libraries(traj_generator poly_traj)

target_include_directories(poly_traj PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS poly_traj
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(TARGETS traj_generator DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(poly_traj)
ament_export_dependencies(rclcpp std_msgs quadrotor_msgs)
ament_package()
EOF

# ============================================================
# path_searching
# ============================================================
cat > "$SRC/swarm_exploration/path_searching/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>path_searching</name>
  <version>0.0.0</version>
  <description>Path searching algorithms</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>plan_env</depend>
  <depend>cv_bridge</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/path_searching/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(path_searching)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})

add_library(path_searching
  src/kinodynamic_astar.cpp
  src/astar2.cpp
  src/topo_prm.cpp
)
ament_target_dependencies(path_searching rclcpp std_msgs visualization_msgs plan_env cv_bridge)
target_include_directories(path_searching PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS path_searching
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(path_searching)
ament_export_dependencies(rclcpp plan_env)
ament_package()
EOF

# ============================================================
# bspline
# ============================================================
cat > "$SRC/swarm_exploration/bspline/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>bspline</name>
  <version>0.0.0</version>
  <description>B-spline library</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>plan_env</depend>
  <depend>cv_bridge</depend>
  <depend>geometry_msgs</depend>
  <depend>builtin_interfaces</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/bspline/CMakeLists.txt" << 'EOF'
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
EOF

# ============================================================
# bspline_opt
# ============================================================
cat > "$SRC/swarm_exploration/bspline_opt/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>bspline_opt</name>
  <version>0.0.0</version>
  <description>B-spline optimization</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>plan_env</depend>
  <depend>active_perception</depend>
  <depend>cv_bridge</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/bspline_opt/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(bspline_opt)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(active_perception REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

set(NLOPT_INCLUDE_DIR "/usr/local/include")
set(NLOPT_LIBRARY "/usr/local/lib/libnlopt.so")

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${NLOPT_INCLUDE_DIR})

add_library(bspline_opt src/bspline_optimizer.cpp)
ament_target_dependencies(bspline_opt rclcpp std_msgs visualization_msgs plan_env active_perception cv_bridge)
target_link_libraries(bspline_opt ${NLOPT_LIBRARY})
target_include_directories(bspline_opt PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS bspline_opt
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(bspline_opt)
ament_export_dependencies(rclcpp plan_env active_perception)
ament_package()
EOF

# ============================================================
# active_perception
# ============================================================
cat > "$SRC/swarm_exploration/active_perception/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>active_perception</name>
  <version>0.0.0</version>
  <description>Active perception</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>plan_env</depend>
  <depend>bspline</depend>
  <depend>path_searching</depend>
  <depend>cv_bridge</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/active_perception/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(active_perception)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(bspline REQUIRED)
find_package(path_searching REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(PCL 1.7 REQUIRED)
find_package(Eigen3 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})

add_library(active_perception
  src/traj_visibility.cpp
  src/heading_planner.cpp
  src/frontier_finder.cpp
  src/graph_node.cpp
  src/perception_utils.cpp
  src/uniform_grid.cpp
  src/hgrid.cpp
)
ament_target_dependencies(active_perception rclcpp std_msgs visualization_msgs plan_env bspline path_searching cv_bridge)
target_link_libraries(active_perception ${PCL_LIBRARIES})
target_include_directories(active_perception PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS active_perception
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(active_perception)
ament_export_dependencies(rclcpp plan_env bspline path_searching)
ament_package()
EOF

# ============================================================
# traj_utils
# ============================================================
cat > "$SRC/swarm_exploration/traj_utils/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>traj_utils</name>
  <version>0.0.0</version>
  <description>Trajectory utilities</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>bspline</depend>
  <depend>bspline_opt</depend>
  <depend>path_searching</depend>
  <depend>poly_traj</depend>
  <depend>visualization_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$SRC/swarm_exploration/traj_utils/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(traj_utils)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(bspline REQUIRED)
find_package(bspline_opt REQUIRED)
find_package(path_searching REQUIRED)
find_package(poly_traj REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL 1.7 REQUIRED)

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS})
link_directories(${PCL_LIBRARY_DIRS})

add_library(traj_utils src/planning_visualization.cpp)
ament_target_dependencies(traj_utils rclcpp std_msgs cv_bridge bspline bspline_opt path_searching poly_traj visualization_msgs)
target_include_directories(traj_utils PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

install(TARGETS traj_utils
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
ament_export_include_directories(include)
ament_export_libraries(traj_utils)
ament_export_dependencies(rclcpp bspline bspline_opt path_searching poly_traj)
ament_package()
EOF

# ============================================================
# lkh_tsp_solver
# ============================================================
cat > "$SRC/swarm_exploration/utils/lkh_tsp_solver/package.xml" << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>lkh_tsp_solver</name>
  <version>0.0.0</version>
  <description>LKH TSP solver</description>
  <maintainer email="bzhouai@todo.todo">bzhouai</maintainer>
  <license>TODO</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

# Check lkh_tsp_solver CMakeLists for details
echo "=== Done creating packages Phase 2-3 ==="
