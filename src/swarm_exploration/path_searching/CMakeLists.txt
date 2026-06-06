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

include_directories(include ${EIGEN3_INCLUDE_DIRS} ${PCL_INCLUDE_DIRS} ${plan_env_INCLUDE_DIRS})

add_library(path_searching
  src/kinodynamic_astar.cpp
  src/astar2.cpp
  src/topo_prm.cpp
)
ament_target_dependencies(path_searching rclcpp std_msgs visualization_msgs plan_env cv_bridge)
target_link_libraries(path_searching ${PCL_LIBRARIES} ${plan_env_LIBRARIES})
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
