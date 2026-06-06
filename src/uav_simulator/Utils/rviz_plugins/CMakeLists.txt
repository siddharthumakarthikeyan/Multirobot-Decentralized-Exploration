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
