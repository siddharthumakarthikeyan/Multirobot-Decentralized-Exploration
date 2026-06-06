#include <iostream>
#include <rclcpp/rclcpp.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <geometry_msgs/msg/pose.hpp>
#include <geometry_msgs/msg/pose_array.hpp>
#include <geometry_msgs/msg/vector3.hpp>
#include <nav_msgs/msg/path.hpp>
#include "sample_waypoints.h"
#include <vector>
#include <deque>
#include <boost/format.hpp>
#include <eigen3/Eigen/Dense>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2/LinearMath/Matrix3x3.h>
#include <tf2_geometry_msgs/tf2_geometry_msgs.hpp>

using namespace std;
using bfmt = boost::format;

static double getYawFromQuat(const geometry_msgs::msg::Quaternion& q) {
  tf2::Quaternion tq(q.x, q.y, q.z, q.w);
  double roll, pitch, yaw;
  tf2::Matrix3x3(tq).getRPY(roll, pitch, yaw);
  return yaw;
}

static geometry_msgs::msg::Quaternion quatFromYaw(double yaw) {
  tf2::Quaternion q;
  q.setRPY(0, 0, yaw);
  geometry_msgs::msg::Quaternion msg;
  msg.x = q.x(); msg.y = q.y(); msg.z = q.z(); msg.w = q.w();
  return msg;
}

class WaypointGenerator : public rclcpp::Node {
public:
  WaypointGenerator() : Node("waypoint_generator") {
    this->declare_parameter("waypoint_type", "manual");
    this->get_parameter("waypoint_type", waypoint_type);

    pub1_ = this->create_publisher<nav_msgs::msg::Path>("waypoints", 50);
    pub2_ = this->create_publisher<geometry_msgs::msg::PoseArray>("waypoints_vis", 10);

    sub1_ = this->create_subscription<nav_msgs::msg::Odometry>(
        "odom", 10, std::bind(&WaypointGenerator::odom_callback, this, std::placeholders::_1));
    sub2_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
        "goal", 10, std::bind(&WaypointGenerator::goal_callback, this, std::placeholders::_1));
    sub3_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
        "traj_start_trigger", 10,
        std::bind(&WaypointGenerator::traj_start_trigger_callback, this, std::placeholders::_1));

    trigged_time_ = rclcpp::Time(0);
    is_odom_ready_ = false;
  }

private:
  rclcpp::Publisher<nav_msgs::msg::Path>::SharedPtr pub1_;
  rclcpp::Publisher<geometry_msgs::msg::PoseArray>::SharedPtr pub2_;
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr sub1_;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr sub2_;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr sub3_;

  string waypoint_type;
  bool is_odom_ready_;
  nav_msgs::msg::Odometry odom_;
  nav_msgs::msg::Path waypoints_;
  std::deque<nav_msgs::msg::Path> waypointSegments_;
  rclcpp::Time trigged_time_;

  void publish_waypoints() {
    waypoints_.header.frame_id = std::string("world");
    waypoints_.header.stamp = this->now();
    pub1_->publish(waypoints_);
    geometry_msgs::msg::PoseStamped init_pose;
    init_pose.header = odom_.header;
    init_pose.pose = odom_.pose.pose;
    waypoints_.poses.insert(waypoints_.poses.begin(), init_pose);
    waypoints_.poses.clear();
  }

  void publish_waypoints_vis() {
    geometry_msgs::msg::PoseArray poseArray;
    poseArray.header.frame_id = std::string("world");
    poseArray.header.stamp = this->now();
    {
      geometry_msgs::msg::Pose init_pose;
      init_pose = odom_.pose.pose;
      poseArray.poses.push_back(init_pose);
    }
    for (auto it = waypoints_.poses.begin(); it != waypoints_.poses.end(); ++it) {
      geometry_msgs::msg::Pose p;
      p = it->pose;
      poseArray.poses.push_back(p);
    }
    pub2_->publish(poseArray);
  }

  void odom_callback(const nav_msgs::msg::Odometry::SharedPtr msg) {
    is_odom_ready_ = true;
    odom_ = *msg;
    if (waypointSegments_.size()) {
      rclcpp::Time expected_time = waypointSegments_.front().header.stamp;
      rclcpp::Time odom_time(odom_.header.stamp);
      if (odom_time >= expected_time) {
        waypoints_ = waypointSegments_.front();
        publish_waypoints_vis();
        publish_waypoints();
        waypointSegments_.pop_front();
      }
    }
  }

  void goal_callback(const geometry_msgs::msg::PoseStamped::SharedPtr msg) {
    trigged_time_ = this->now();
    this->get_parameter("waypoint_type", waypoint_type);

    if (waypoint_type == string("circle")) {
      waypoints_ = circle();
      publish_waypoints_vis();
      publish_waypoints();
    } else if (waypoint_type == string("eight")) {
      waypoints_ = eight();
      publish_waypoints_vis();
      publish_waypoints();
    } else if (waypoint_type == string("point")) {
      waypoints_ = point();
      publish_waypoints_vis();
      publish_waypoints();
    } else if (waypoint_type == string("manual-lonely-waypoint")) {
      if (msg->pose.position.z > -0.1) {
        geometry_msgs::msg::PoseStamped pt = *msg;
        waypoints_.poses.clear();
        waypoints_.poses.push_back(pt);
        publish_waypoints_vis();
        publish_waypoints();
      } else {
        RCLCPP_WARN(this->get_logger(), "[waypoint_generator] invalid goal in manual-lonely-waypoint mode.");
      }
    } else {
      if (msg->pose.position.z > 0) {
        geometry_msgs::msg::PoseStamped pt = *msg;
        if (waypoint_type == string("noyaw")) {
          double yaw = getYawFromQuat(odom_.pose.pose.orientation);
          pt.pose.orientation = quatFromYaw(yaw);
        }
        waypoints_.poses.push_back(pt);
        publish_waypoints_vis();
      } else if (msg->pose.position.z > -1.0) {
        if (waypoints_.poses.size() >= 1) {
          waypoints_.poses.erase(std::prev(waypoints_.poses.end()));
        }
        publish_waypoints_vis();
      } else {
        if (waypoints_.poses.size() >= 1) {
          publish_waypoints_vis();
          publish_waypoints();
        }
      }
    }
  }

  void traj_start_trigger_callback(const geometry_msgs::msg::PoseStamped::SharedPtr msg) {
    if (!is_odom_ready_) {
      RCLCPP_ERROR(this->get_logger(), "[waypoint_generator] No odom!");
      return;
    }
    RCLCPP_WARN(this->get_logger(), "[waypoint_generator] Trigger!");
    trigged_time_ = odom_.header.stamp;

    this->get_parameter("waypoint_type", waypoint_type);

    if (waypoint_type == string("free")) {
      waypoints_ = point();
      publish_waypoints_vis();
      publish_waypoints();
    } else if (waypoint_type == string("circle")) {
      waypoints_ = circle();
      publish_waypoints_vis();
      publish_waypoints();
    } else if (waypoint_type == string("eight")) {
      waypoints_ = eight();
      publish_waypoints_vis();
      publish_waypoints();
    } else if (waypoint_type == string("point")) {
      waypoints_ = point();
      publish_waypoints_vis();
      publish_waypoints();
    }
  }
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<WaypointGenerator>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}
