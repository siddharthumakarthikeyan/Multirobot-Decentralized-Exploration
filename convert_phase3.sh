#!/bin/bash
# Phase 3: Final ros:: pattern cleanup
set -e
SRC="/home/siddharth/multi_decent_expl/src"

echo "=== Phase 3: Final ros:: cleanup ==="

find "$SRC" -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) \
  ! -path "*/ode/*" ! -name "*.cpp~" ! -path "*/msg_gen/*" | while read f; do

  # ros::NodeHandle node -> auto node = std::make_shared<rclcpp::Node>
  sed -i 's|ros::NodeHandle node;|rclcpp::Node::SharedPtr node;|g' "$f"
  sed -i 's|ros::NodeHandle node(|auto node = std::make_shared<rclcpp::Node>(|g' "$f"

  # ros::TransportHints().tcpNoDelay() -> rclcpp::QoS(10) (remove)
  sed -i 's|, ros::TransportHints().tcpNoDelay()||g' "$f"
  sed -i 's|ros::TransportHints().tcpNoDelay()||g' "$f"

  # ros::ServiceClient -> rclcpp::Client
  sed -i 's|ros::ServiceClient |rclcpp::ClientBase::SharedPtr |g' "$f"
  sed -i 's|ros::ServiceServer |rclcpp::ServiceBase::SharedPtr |g' "$f"

  # ros::message_traits::datatype -> remove (rviz2 uses different API)
  sed -i 's|ros::message_traits::datatype<[^>]*>()||g' "$f"

  # ros::Exception -> std::exception
  sed -i 's|ros::Exception|std::exception|g' "$f"

  # vector<ros::Publisher> -> can't fully fix generically but mark
  sed -i 's|vector<ros::Publisher>|std::vector<rclcpp::PublisherBase::SharedPtr>|g' "$f"
  sed -i 's|vector<ros::Subscriber>|std::vector<rclcpp::SubscriptionBase::SharedPtr>|g' "$f"

  # ros::NodeHandle& node -> rclcpp::Node::SharedPtr node
  sed -i 's|ros::NodeHandle& node|rclcpp::Node::SharedPtr node|g' "$f"

  # remaining ros::init that didn't match the pattern
  sed -i 's|ros::init *(argc, *argv, *"[^"]*")|rclcpp::init(argc, argv)|g' "$f"

  # ros::NodeHandle node_handle_
  sed -i 's|ros::NodeHandle node_handle_;|rclcpp::Node::SharedPtr node_handle_;|g' "$f"

done

echo "=== Phase 3 complete ==="
echo "Remaining 'ros::' count:"
grep -rn "ros::" "$SRC" --include="*.cpp" --include="*.h" --include="*.hpp" | \
  grep -v "//\|pcl_ros\|cv_bridge\|tf2_ros\|ament_index\|pcl_conversions\|pluginlib\|nodelet removed\|pluginlib removed\|rclcpp\|ode/\|\.cpp~\|msg_gen\|ros2_param\|TimerEvent\|#include" | \
  wc -l || echo "0"
