#!/bin/bash
# ROS 1 -> ROS 2 Humble: Bulk C++ source file conversion
# This script handles common include/type replacements across ALL .cpp/.h files
# CMakeLists.txt and package.xml are converted separately per-package

set -e
SRC_DIR="/home/siddharth/multi_decent_expl/src"

echo "=== ROS1 -> ROS2 C++ Source Conversion ==="

# --- Header includes ---
find "$SRC_DIR" -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) \
  ! -path "*/ode/*" ! -path "*backward.hpp" ! -name "*.cpp~" | while read f; do

  # Core ROS include
  sed -i 's|#include <ros/ros.h>|#include <rclcpp/rclcpp.hpp>|g' "$f"
  sed -i 's|#include "ros/ros.h"|#include <rclcpp/rclcpp.hpp>|g' "$f"
  sed -i 's|#include <ros/console.h>|#include <rclcpp/rclcpp.hpp>|g' "$f"
  sed -i 's|#include <ros/package.h>|#include <ament_index_cpp/get_package_share_directory.hpp>|g' "$f"

  # Standard message includes
  sed -i 's|#include <std_msgs/Empty.h>|#include <std_msgs/msg/empty.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/Bool.h>|#include <std_msgs/msg/bool.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/Float64.h>|#include <std_msgs/msg/float64.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/Int32.h>|#include <std_msgs/msg/int32.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/String.h>|#include <std_msgs/msg/string.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/ColorRGBA.h>|#include <std_msgs/msg/color_rgba.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/UInt8.h>|#include <std_msgs/msg/u_int8.hpp>|g' "$f"
  sed -i 's|#include <std_msgs/Int8.h>|#include <std_msgs/msg/int8.hpp>|g' "$f"

  # Geometry message includes
  sed -i 's|#include <geometry_msgs/PoseStamped.h>|#include <geometry_msgs/msg/pose_stamped.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/Pose.h>|#include <geometry_msgs/msg/pose.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/Point.h>|#include <geometry_msgs/msg/point.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/Vector3.h>|#include <geometry_msgs/msg/vector3.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/Quaternion.h>|#include <geometry_msgs/msg/quaternion.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/Wrench.h>|#include <geometry_msgs/msg/wrench.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/WrenchStamped.h>|#include <geometry_msgs/msg/wrench_stamped.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/TransformStamped.h>|#include <geometry_msgs/msg/transform_stamped.hpp>|g' "$f"
  sed -i 's|#include <geometry_msgs/PointStamped.h>|#include <geometry_msgs/msg/point_stamped.hpp>|g' "$f"

  # Nav message includes
  sed -i 's|#include <nav_msgs/Odometry.h>|#include <nav_msgs/msg/odometry.hpp>|g' "$f"
  sed -i 's|#include <nav_msgs/Path.h>|#include <nav_msgs/msg/path.hpp>|g' "$f"
  sed -i 's|#include <nav_msgs/OccupancyGrid.h>|#include <nav_msgs/msg/occupancy_grid.hpp>|g' "$f"

  # Sensor message includes
  sed -i 's|#include <sensor_msgs/PointCloud2.h>|#include <sensor_msgs/msg/point_cloud2.hpp>|g' "$f"
  sed -i 's|#include <sensor_msgs/PointCloud.h>|#include <sensor_msgs/msg/point_cloud.hpp>|g' "$f"
  sed -i 's|#include <sensor_msgs/Image.h>|#include <sensor_msgs/msg/image.hpp>|g' "$f"
  sed -i 's|#include <sensor_msgs/Joy.h>|#include <sensor_msgs/msg/joy.hpp>|g' "$f"
  sed -i 's|#include <sensor_msgs/Imu.h>|#include <sensor_msgs/msg/imu.hpp>|g' "$f"
  sed -i 's|#include <sensor_msgs/point_cloud_conversion.h>|#include <sensor_msgs/point_cloud_conversion.hpp>|g' "$f"

  # Visualization message includes
  sed -i 's|#include <visualization_msgs/Marker.h>|#include <visualization_msgs/msg/marker.hpp>|g' "$f"
  sed -i 's|#include <visualization_msgs/MarkerArray.h>|#include <visualization_msgs/msg/marker_array.hpp>|g' "$f"

  # TF includes
  sed -i 's|#include <tf/transform_broadcaster.h>|#include <tf2_ros/transform_broadcaster.h>|g' "$f"
  sed -i 's|#include <tf/transform_listener.h>|#include <tf2_ros/transform_listener.h>\n#include <tf2_ros/buffer.h>|g' "$f"
  sed -i 's|#include <tf/tf.h>|#include <tf2/LinearMath/Quaternion.h>\n#include <tf2/LinearMath/Matrix3x3.h>|g' "$f"
  sed -i 's|#include <tf/transform_datatypes.h>|#include <tf2_geometry_msgs/tf2_geometry_msgs.hpp>|g' "$f"

  # cv_bridge
  sed -i 's|#include <cv_bridge/cv_bridge.h>|#include <cv_bridge/cv_bridge.h>|g' "$f"

  # message_filters
  sed -i 's|#include <message_filters/subscriber.h>|#include <message_filters/subscriber.h>|g' "$f"

  # Custom message includes - quadrotor_msgs
  sed -i 's|#include <quadrotor_msgs/PositionCommand.h>|#include <quadrotor_msgs/msg/position_command.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/SO3Command.h>|#include <quadrotor_msgs/msg/so3_command.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/Corrections.h>|#include <quadrotor_msgs/msg/corrections.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/Gains.h>|#include <quadrotor_msgs/msg/gains.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/OutputData.h>|#include <quadrotor_msgs/msg/output_data.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/StatusData.h>|#include <quadrotor_msgs/msg/status_data.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/TRPYCommand.h>|#include <quadrotor_msgs/msg/trpy_command.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/AuxCommand.h>|#include <quadrotor_msgs/msg/aux_command.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/Serial.h>|#include <quadrotor_msgs/msg/serial.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/PPROutputData.h>|#include <quadrotor_msgs/msg/ppr_output_data.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/Odometry.h>|#include <quadrotor_msgs/msg/odometry.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/PolynomialTrajectory.h>|#include <quadrotor_msgs/msg/polynomial_trajectory.hpp>|g' "$f"
  sed -i 's|#include <quadrotor_msgs/LQRTrajectory.h>|#include <quadrotor_msgs/msg/lqr_trajectory.hpp>|g' "$f"

  # Custom message includes - bspline
  sed -i 's|#include <bspline/Bspline.h>|#include <bspline/msg/bspline.hpp>|g' "$f"

  # Custom message includes - exploration_manager
  sed -i 's|#include <exploration_manager/DroneState.h>|#include <exploration_manager/msg/drone_state.hpp>|g' "$f"
  sed -i 's|#include <exploration_manager/PairOpt.h>|#include <exploration_manager/msg/pair_opt.hpp>|g' "$f"
  sed -i 's|#include <exploration_manager/PairOptResponse.h>|#include <exploration_manager/msg/pair_opt_response.hpp>|g' "$f"
  sed -i 's|#include <exploration_manager/HGrid.h>|#include <exploration_manager/msg/h_grid.hpp>|g' "$f"
  sed -i 's|#include <exploration_manager/GridTour.h>|#include <exploration_manager/msg/grid_tour.hpp>|g' "$f"

  # Custom message includes - plan_env
  sed -i 's|#include <plan_env/IdxList.h>|#include <plan_env/msg/idx_list.hpp>|g' "$f"
  sed -i 's|#include <plan_env/ChunkStamps.h>|#include <plan_env/msg/chunk_stamps.hpp>|g' "$f"
  sed -i 's|#include <plan_env/ChunkData.h>|#include <plan_env/msg/chunk_data.hpp>|g' "$f"

  # Custom message includes - multi_map_server
  sed -i 's|#include <multi_map_server/MultiOccupancyGrid.h>|#include <multi_map_server/msg/multi_occupancy_grid.hpp>|g' "$f"
  sed -i 's|#include <multi_map_server/MultiSparseMap3D.h>|#include <multi_map_server/msg/multi_sparse_map3_d.hpp>|g' "$f"
  sed -i 's|#include <multi_map_server/SparseMap3D.h>|#include <multi_map_server/msg/sparse_map3_d.hpp>|g' "$f"
  sed -i 's|#include <multi_map_server/VerticalOccupancyGridList.h>|#include <multi_map_server/msg/vertical_occupancy_grid_list.hpp>|g' "$f"

  # --- Message type names ---
  # std_msgs
  sed -i 's|std_msgs::Empty|std_msgs::msg::Empty|g' "$f"
  sed -i 's|std_msgs::Bool|std_msgs::msg::Bool|g' "$f"
  sed -i 's|std_msgs::Float64|std_msgs::msg::Float64|g' "$f"
  sed -i 's|std_msgs::Int32|std_msgs::msg::Int32|g' "$f"
  sed -i 's|std_msgs::Int8|std_msgs::msg::Int8|g' "$f"
  sed -i 's|std_msgs::UInt8|std_msgs::msg::UInt8|g' "$f"
  sed -i 's|std_msgs::String|std_msgs::msg::String|g' "$f"
  sed -i 's|std_msgs::ColorRGBA|std_msgs::msg::ColorRGBA|g' "$f"
  sed -i 's|std_msgs::Header|std_msgs::msg::Header|g' "$f"

  # geometry_msgs
  sed -i 's|geometry_msgs::PoseStamped|geometry_msgs::msg::PoseStamped|g' "$f"
  sed -i 's|geometry_msgs::Pose\b|geometry_msgs::msg::Pose|g' "$f"
  sed -i 's|geometry_msgs::Point\b|geometry_msgs::msg::Point|g' "$f"
  sed -i 's|geometry_msgs::Vector3\b|geometry_msgs::msg::Vector3|g' "$f"
  sed -i 's|geometry_msgs::Quaternion\b|geometry_msgs::msg::Quaternion|g' "$f"
  sed -i 's|geometry_msgs::Wrench\b|geometry_msgs::msg::Wrench|g' "$f"
  sed -i 's|geometry_msgs::WrenchStamped|geometry_msgs::msg::WrenchStamped|g' "$f"
  sed -i 's|geometry_msgs::TransformStamped|geometry_msgs::msg::TransformStamped|g' "$f"
  sed -i 's|geometry_msgs::PointStamped|geometry_msgs::msg::PointStamped|g' "$f"

  # nav_msgs
  sed -i 's|nav_msgs::Odometry|nav_msgs::msg::Odometry|g' "$f"
  sed -i 's|nav_msgs::Path\b|nav_msgs::msg::Path|g' "$f"
  sed -i 's|nav_msgs::OccupancyGrid|nav_msgs::msg::OccupancyGrid|g' "$f"

  # sensor_msgs
  sed -i 's|sensor_msgs::PointCloud2|sensor_msgs::msg::PointCloud2|g' "$f"
  sed -i 's|sensor_msgs::PointCloud\b|sensor_msgs::msg::PointCloud|g' "$f"
  sed -i 's|sensor_msgs::Image\b|sensor_msgs::msg::Image|g' "$f"
  sed -i 's|sensor_msgs::Joy\b|sensor_msgs::msg::Joy|g' "$f"
  sed -i 's|sensor_msgs::Imu\b|sensor_msgs::msg::Imu|g' "$f"

  # visualization_msgs
  sed -i 's|visualization_msgs::Marker\b|visualization_msgs::msg::Marker|g' "$f"
  sed -i 's|visualization_msgs::MarkerArray|visualization_msgs::msg::MarkerArray|g' "$f"

  # quadrotor_msgs
  sed -i 's|quadrotor_msgs::PositionCommand|quadrotor_msgs::msg::PositionCommand|g' "$f"
  sed -i 's|quadrotor_msgs::SO3Command|quadrotor_msgs::msg::SO3Command|g' "$f"
  sed -i 's|quadrotor_msgs::Corrections|quadrotor_msgs::msg::Corrections|g' "$f"
  sed -i 's|quadrotor_msgs::Gains|quadrotor_msgs::msg::Gains|g' "$f"
  sed -i 's|quadrotor_msgs::OutputData|quadrotor_msgs::msg::OutputData|g' "$f"
  sed -i 's|quadrotor_msgs::StatusData|quadrotor_msgs::msg::StatusData|g' "$f"
  sed -i 's|quadrotor_msgs::TRPYCommand|quadrotor_msgs::msg::TRPYCommand|g' "$f"
  sed -i 's|quadrotor_msgs::AuxCommand|quadrotor_msgs::msg::AuxCommand|g' "$f"
  sed -i 's|quadrotor_msgs::Serial\b|quadrotor_msgs::msg::Serial|g' "$f"
  sed -i 's|quadrotor_msgs::PPROutputData|quadrotor_msgs::msg::PPROutputData|g' "$f"
  sed -i 's|quadrotor_msgs::Odometry|quadrotor_msgs::msg::Odometry|g' "$f"
  sed -i 's|quadrotor_msgs::PolynomialTrajectory|quadrotor_msgs::msg::PolynomialTrajectory|g' "$f"
  sed -i 's|quadrotor_msgs::LQRTrajectory|quadrotor_msgs::msg::LQRTrajectory|g' "$f"

  # bspline custom msgs
  sed -i 's|bspline::Bspline\b|bspline::msg::Bspline|g' "$f"

  # exploration_manager custom msgs
  sed -i 's|exploration_manager::DroneState\b|exploration_manager::msg::DroneState|g' "$f"
  sed -i 's|exploration_manager::PairOpt\b|exploration_manager::msg::PairOpt|g' "$f"
  sed -i 's|exploration_manager::PairOptResponse\b|exploration_manager::msg::PairOptResponse|g' "$f"
  sed -i 's|exploration_manager::HGrid\b|exploration_manager::msg::HGrid|g' "$f"
  sed -i 's|exploration_manager::GridTour\b|exploration_manager::msg::GridTour|g' "$f"

  # plan_env custom msgs
  sed -i 's|plan_env::IdxList\b|plan_env::msg::IdxList|g' "$f"
  sed -i 's|plan_env::ChunkStamps\b|plan_env::msg::ChunkStamps|g' "$f"
  sed -i 's|plan_env::ChunkData\b|plan_env::msg::ChunkData|g' "$f"

  # multi_map_server custom msgs
  sed -i 's|multi_map_server::MultiOccupancyGrid|multi_map_server::msg::MultiOccupancyGrid|g' "$f"
  sed -i 's|multi_map_server::MultiSparseMap3D|multi_map_server::msg::MultiSparseMap3D|g' "$f"
  sed -i 's|multi_map_server::SparseMap3D|multi_map_server::msg::SparseMap3D|g' "$f"
  sed -i 's|multi_map_server::VerticalOccupancyGridList|multi_map_server::msg::VerticalOccupancyGridList|g' "$f"

  # --- ConstPtr patterns ---
  # Standard msgs ConstPtr -> SharedPtr  
  sed -i 's|ConstPtr|::ConstSharedPtr|g' "$f"
  # Fix double ::
  sed -i 's|::::ConstSharedPtr|::ConstSharedPtr|g' "$f"

  # --- ROS logging ---
  sed -i 's|ROS_INFO(|RCLCPP_INFO(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_WARN(|RCLCPP_WARN(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_ERROR(|RCLCPP_ERROR(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_INFO_STREAM(|RCLCPP_INFO_STREAM(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_WARN_STREAM(|RCLCPP_WARN_STREAM(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_ERROR_STREAM(|RCLCPP_ERROR_STREAM(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_FATAL(|RCLCPP_FATAL(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_DEBUG(|RCLCPP_DEBUG(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_INFO_ONCE(|RCLCPP_INFO_ONCE(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_WARN_ONCE(|RCLCPP_WARN_ONCE(rclcpp::get_logger("racer"), |g' "$f"
  sed -i 's|ROS_ASSERT(|assert(|g' "$f"

  # --- ros::Time ---
  sed -i 's|ros::Time::now()|this->now()|g' "$f"
  sed -i 's|ros::Time()|rclcpp::Time(0)|g' "$f"
  sed -i 's|ros::Time\b|rclcpp::Time|g' "$f"

  # --- ros::Duration ---
  sed -i 's|ros::Duration|rclcpp::Duration|g' "$f"

  # --- ros::Rate ---
  sed -i 's|ros::Rate|rclcpp::Rate|g' "$f"

  # --- ros::ok() ---
  sed -i 's|ros::ok()|rclcpp::ok()|g' "$f"

  # --- ros::package::getPath ---
  sed -i 's|ros::package::getPath|ament_index_cpp::get_package_share_directory|g' "$f"

  # --- Nodelet to component (for so3_control etc.) ---
  sed -i 's|#include <nodelet/nodelet.h>|// nodelet removed for ROS2 component|g' "$f"
  sed -i 's|#include <pluginlib/class_list_macros.h>|// pluginlib removed for ROS2|g' "$f"

  # Fix header.stamp = rclcpp::Time(0) -> use rclcpp::Clock
  # (will need manual fixup in some files)

  # Fix double msg::msg:: if it happens
  sed -i 's|msg::msg::|msg::|g' "$f"

done

echo "=== C++ source conversion complete ==="
echo "NOTE: Manual fixups still needed for:"
echo "  - ros::NodeHandle -> rclcpp::Node (class-level refactoring)"
echo "  - ros::Publisher/Subscriber/Timer declarations"
echo "  - Callback signatures (TimerEvent removal)"
echo "  - ros::param / nh.param -> declare_parameter"
echo "  - nodelet -> component node conversions"
