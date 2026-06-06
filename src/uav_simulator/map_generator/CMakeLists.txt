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

# add_executable(click_map src/click_map.cpp)
# ament_target_dependencies(click_map ${MAP_DEPS})
# target_link_libraries(click_map ${PCL_LIBRARIES})

# add_executable(map_recorder src/map_recorder.cpp)
# ament_target_dependencies(map_recorder ${MAP_DEPS})
# target_link_libraries(map_recorder ${PCL_LIBRARIES})

add_executable(random_forest src/random_forest_sensing.cpp)
ament_target_dependencies(random_forest ${MAP_DEPS})
target_link_libraries(random_forest ${PCL_LIBRARIES})

install(TARGETS map_pub random_forest DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY resource/ DESTINATION share/${PROJECT_NAME}/resource)
ament_package()
