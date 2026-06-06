cmake_minimum_required(VERSION 3.8)
project(lkh_mtsp_solver)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Wall")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcommon")

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
