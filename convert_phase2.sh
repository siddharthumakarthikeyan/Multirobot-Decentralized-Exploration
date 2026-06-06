#!/bin/bash
# Phase 2 conversion: Handle remaining ros:: patterns
set -e
SRC="/home/siddharth/multi_decent_expl/src"

echo "=== Phase 2: Remaining ros:: pattern cleanup ==="

find "$SRC" -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) \
  ! -path "*/ode/*" ! -name "*.cpp~" ! -name "backward.hpp" ! -path "*/msg_gen/*" | while read f; do

  # ros::NodeHandle -> rclcpp::Node::SharedPtr (in class member declarations)
  sed -i 's|ros::NodeHandle node_;|rclcpp::Node::SharedPtr node_;|g' "$f"
  sed -i 's|ros::NodeHandle nh_;|rclcpp::Node::SharedPtr nh_;|g' "$f"
  sed -i 's|ros::NodeHandle& nh|rclcpp::Node::SharedPtr nh|g' "$f"
  sed -i 's|ros::NodeHandle &nh|rclcpp::Node::SharedPtr nh|g' "$f"
  sed -i 's|ros::NodeHandle nh|rclcpp::Node::SharedPtr nh|g' "$f"

  # ros::Publisher -> rclcpp publisher SharedPtr (generic)
  sed -i 's|ros::Publisher |rclcpp::Publisher<std_msgs::msg::Empty>::SharedPtr |g' "$f"

  # ros::Subscriber -> rclcpp subscription SharedPtr (generic)
  sed -i 's|ros::Subscriber |rclcpp::Subscription<std_msgs::msg::Empty>::SharedPtr |g' "$f"

  # ros::Timer -> rclcpp::TimerBase::SharedPtr
  sed -i 's|ros::Timer |rclcpp::TimerBase::SharedPtr |g' "$f"
  sed -i 's|ros::Timer,|rclcpp::TimerBase::SharedPtr,|g' "$f"
  sed -i 's|ros::Timer;|rclcpp::TimerBase::SharedPtr;|g' "$f"

  # ros::init -> rclcpp::init
  sed -i 's|ros::init(argc, argv, "[^"]*")|rclcpp::init(argc, argv)|g' "$f"

  # ros::spin() -> rclcpp::spin
  sed -i 's|ros::spin()|rclcpp::spin(node)|g' "$f"
  sed -i 's|ros::spinOnce()|rclcpp::spin_some(node)|g' "$f"

  # ros::TimerEvent& -> void (remove parameter)
  # Can't fully automate callback signature changes, but fix the type name
  sed -i 's|const ros::TimerEvent& e|/*timer*/|g' "$f"
  sed -i 's|const ros::TimerEvent&e|/*timer*/|g' "$f"
  sed -i 's|const ros::TimerEvent &e|/*timer*/|g' "$f"
  sed -i 's|const ros::TimerEvent& event|/*timer*/|g' "$f"
  sed -i 's|const ros::TimerEvent &event|/*timer*/|g' "$f"
  sed -i 's|ros::TimerEvent|void /*TimerEvent*/|g' "$f"

  # n.param / nh.param patterns -> declare_parameter
  # These need manual attention but at least replace the ros:: prefix
  sed -i 's|ros::param::|// ros2_param::|g' "$f"

  # ros::NodeHandle n( -> already handled above
  # Handle remaining ros::NodeHandle declarations in main functions
  sed -i 's|ros::NodeHandle n(|auto node = std::make_shared<rclcpp::Node>(|g' "$f"

  # Fix publisher advertise pattern: n.advertise<Type>("topic", qos)
  # This is too complex for sed - will be handled manually

  # ros::shutdown
  sed -i 's|ros::shutdown()|rclcpp::shutdown()|g' "$f"

  # ros::WallRate
  sed -i 's|ros::WallRate|rclcpp::WallRate|g' "$f"

  # ros::spinOnce already handled

  # header.stamp = rclcpp::Time(0) patterns
  sed -i 's|\.stamp = rclcpp::Time(0)|.stamp = rclcpp::Clock().now()|g' "$f"

  # Fix any remaining double-msg:: artifacts
  sed -i 's|msg::msg::|msg::|g' "$f"

done

echo "=== Phase 2 complete ==="
echo "Remaining 'ros::' references (excluding comments/ode):"
grep -rn "ros::" "$SRC" --include="*.cpp" --include="*.h" --include="*.hpp" | \
  grep -v "//\|pcl_ros\|cv_bridge\|tf2_ros\|ament_index\|pcl_conversions\|pluginlib\|nodelet removed\|pluginlib removed\|rclcpp\|ode/\|\.cpp~\|msg_gen\|ros2_param\|TimerEvent\|#include" | \
  wc -l || echo "0"
