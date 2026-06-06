#include <fstream>
#include <iostream>
#include <vector>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <nav_msgs/msg/path.hpp>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <std_msgs/msg/bool.hpp>

#include <pcl_conversions/pcl_conversions.h>
#include "opencv2/highgui/highgui.hpp"
#include <opencv2/opencv.hpp>
#include <opencv2/core/eigen.hpp>
#include <cv_bridge/cv_bridge.h>
#include <image_transport/image_transport.hpp>
#include <Eigen/Eigen>

using namespace cv;
using namespace std;
using namespace Eigen;

class PclRenderNode : public rclcpp::Node
{
public:
  PclRenderNode() : Node("pcl_render_node")
  {
    // Declare parameters
    this->declare_parameter("cam_width", 640);
    this->declare_parameter("cam_height", 480);
    this->declare_parameter("cam_fx", 385.0);
    this->declare_parameter("cam_fy", 385.0);
    this->declare_parameter("cam_cx", 320.0);
    this->declare_parameter("cam_cy", 240.0);
    this->declare_parameter("sensing_horizon", 5.0);
    this->declare_parameter("sensing_rate", 10.0);
    this->declare_parameter("estimation_rate", 10.0);

    // Get parameters
    width_ = this->get_parameter("cam_width").as_int();
    height_ = this->get_parameter("cam_height").as_int();
    fx_ = this->get_parameter("cam_fx").as_double();
    fy_ = this->get_parameter("cam_fy").as_double();
    cx_ = this->get_parameter("cam_cx").as_double();
    cy_ = this->get_parameter("cam_cy").as_double();
    sensing_horizon_ = this->get_parameter("sensing_horizon").as_double();
    sensing_rate_ = this->get_parameter("sensing_rate").as_double();
    estimation_rate_ = this->get_parameter("estimation_rate").as_double();

    // Camera to body transform
    cam02body_ << 0.0, 0.0, 1.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0;
    cam2world_ = Matrix4d::Identity();

    // Publishers
    pub_depth_ = this->create_publisher<sensor_msgs::msg::Image>("depth", 10);
    pub_pose_ = this->create_publisher<geometry_msgs::msg::PoseStamped>("sensor_pose", 10);

    // Subscribers
    global_map_sub_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
      "global_map", 1, std::bind(&PclRenderNode::pointCloudCallback, this, std::placeholders::_1));
    odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
      "odometry", 50, std::bind(&PclRenderNode::odometryCallback, this, std::placeholders::_1));

    // Timers
    int sensing_period_ms = static_cast<int>(1000.0 / sensing_rate_);
    int estimation_period_ms = static_cast<int>(1000.0 / estimation_rate_);
    sensing_timer_ = this->create_wall_timer(
      std::chrono::milliseconds(sensing_period_ms), std::bind(&PclRenderNode::renderSensedPoints, this));
    estimation_timer_ = this->create_wall_timer(
      std::chrono::milliseconds(estimation_period_ms), std::bind(&PclRenderNode::pubCameraPose, this));

    RCLCPP_INFO(this->get_logger(), "PCL render node initialized");
  }

private:
  void odometryCallback(const nav_msgs::msg::Odometry::SharedPtr odom)
  {
    has_odom_ = true;
    odom_ = *odom;
    Matrix4d Pose_receive = Matrix4d::Identity();

    Eigen::Vector3d request_position;
    Eigen::Quaterniond request_pose;
    request_position.x() = odom->pose.pose.position.x;
    request_position.y() = odom->pose.pose.position.y;
    request_position.z() = odom->pose.pose.position.z;
    request_pose.x() = odom->pose.pose.orientation.x;
    request_pose.y() = odom->pose.pose.orientation.y;
    request_pose.z() = odom->pose.pose.orientation.z;
    request_pose.w() = odom->pose.pose.orientation.w;
    Pose_receive.block<3, 3>(0, 0) = request_pose.toRotationMatrix();
    Pose_receive(0, 3) = request_position(0);
    Pose_receive(1, 3) = request_position(1);
    Pose_receive(2, 3) = request_position(2);

    Matrix4d body_pose = Pose_receive;
    cam2world_ = body_pose * cam02body_;
    cam2world_quat_ = cam2world_.block<3, 3>(0, 0);
    last_odom_stamp_ = odom->header.stamp;

    last_pose_world_(0) = odom->pose.pose.position.x;
    last_pose_world_(1) = odom->pose.pose.position.y;
    last_pose_world_(2) = odom->pose.pose.position.z;
  }

  void pubCameraPose()
  {
    if (!has_odom_) return;
    
    geometry_msgs::msg::PoseStamped camera_pose;
    camera_pose.header = odom_.header;
    camera_pose.header.frame_id = "world";
    camera_pose.pose.position.x = cam2world_(0, 3);
    camera_pose.pose.position.y = cam2world_(1, 3);
    camera_pose.pose.position.z = cam2world_(2, 3);
    camera_pose.pose.orientation.w = cam2world_quat_.w();
    camera_pose.pose.orientation.x = cam2world_quat_.x();
    camera_pose.pose.orientation.y = cam2world_quat_.y();
    camera_pose.pose.orientation.z = cam2world_quat_.z();
    pub_pose_->publish(camera_pose);
  }

  void pointCloudCallback(const sensor_msgs::msg::PointCloud2::SharedPtr pointcloud_map)
  {
    if (has_global_map_) return;

    RCLCPP_WARN(this->get_logger(), "Global Pointcloud received..");
    pcl::fromROSMsg(*pointcloud_map, cloud_in_);
    RCLCPP_INFO(this->get_logger(), "Global map has %zu points", cloud_in_.points.size());
    has_global_map_ = true;
  }

  void renderDepth()
  {
    depth_mat_ = cv::Mat::zeros(height_, width_, CV_32FC1);

    Eigen::Matrix4d Tcw = cam2world_.inverse();
    Eigen::Matrix3d Rcw = Tcw.block<3, 3>(0, 0);
    Eigen::Vector3d tcw = Tcw.block<3, 1>(0, 3);

    Eigen::Vector3d pos = cam2world_.block<3, 1>(0, 3);
    int points_in_range = 0;
    int points_projected = 0;
    int points_in_image = 0;
    for (auto pt : cloud_in_.points) {
      Eigen::Vector3d pw(pt.x, pt.y, pt.z);
      if ((pos - pw).norm() > sensing_horizon_) continue;
      points_in_range++;

      Eigen::Vector3d pc = Rcw * pw + tcw;

      if (pc[2] <= 0.0) continue;
      points_projected++;

      float projected_x, projected_y;
      projected_x = pc[0] / pc[2] * fx_ + cx_;
      projected_y = pc[1] / pc[2] * fy_ + cy_;
      if (projected_x < 0 || projected_x >= width_ || projected_y < 0 || projected_y >= height_)
        continue;
      points_in_image++;

      float dist = pc[2];
      int r = 0.0573 * fx_ / dist + 0.5;
      int min_x = std::max(int(projected_x - r), 0);
      int max_x = std::min(int(projected_x + r), width_ - 1);
      int min_y = std::max(int(projected_y - r), 0);
      int max_y = std::min(int(projected_y + r), height_ - 1);

      for (int to_x = min_x; to_x <= max_x; to_x++)
        for (int to_y = min_y; to_y <= max_y; to_y++) {
          float value = depth_mat_.at<float>(to_y, to_x);
          if (value < 1e-3) {
            depth_mat_.at<float>(to_y, to_x) = dist;
          } else {
            depth_mat_.at<float>(to_y, to_x) = std::min(value, dist);
          }
        }
    }

    cv_bridge::CvImage out_msg;
    out_msg.header.stamp = last_odom_stamp_;
    out_msg.header.frame_id = "world";
    out_msg.encoding = sensor_msgs::image_encodings::TYPE_32FC1;
    out_msg.image = depth_mat_.clone();
    
    // Debug output
    static int debug_count = 0;
    if (debug_count++ % 100 == 0) {
      // Count non-zero pixels
      int non_zero = 0;
      for (int i = 0; i < height_; i++)
        for (int j = 0; j < width_; j++)
          if (depth_mat_.at<float>(i, j) > 0.01) non_zero++;
      RCLCPP_INFO(this->get_logger(), "Render: pos=(%.1f,%.1f,%.1f) range=%d proj=%d in_img=%d pixels=%d",
        pos[0], pos[1], pos[2], points_in_range, points_projected, points_in_image, non_zero);
    }
    
    pub_depth_->publish(*out_msg.toImageMsg());
  }

  void renderSensedPoints()
  {
    if (!has_global_map_ || !has_odom_) return;
    renderDepth();
    pubCameraPose();  // Publish pose immediately after depth for better synchronization
  }

  // Publishers and subscribers
  rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr pub_depth_;
  rclcpp::Publisher<geometry_msgs::msg::PoseStamped>::SharedPtr pub_pose_;
  rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr global_map_sub_;
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  rclcpp::TimerBase::SharedPtr sensing_timer_, estimation_timer_;

  // Camera parameters
  int width_, height_;
  double fx_, fy_, cx_, cy_;
  double sensing_horizon_, sensing_rate_, estimation_rate_;

  // Transform matrices
  Matrix4d cam02body_;
  Matrix4d cam2world_;
  Eigen::Quaterniond cam2world_quat_;

  // State
  bool has_global_map_ = false;
  bool has_odom_ = false;
  nav_msgs::msg::Odometry odom_;
  builtin_interfaces::msg::Time last_odom_stamp_;
  Eigen::Vector3d last_pose_world_;
  pcl::PointCloud<pcl::PointXYZ> cloud_in_;
  cv::Mat depth_mat_;
};

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<PclRenderNode>());
  rclcpp::shutdown();
  return 0;
}