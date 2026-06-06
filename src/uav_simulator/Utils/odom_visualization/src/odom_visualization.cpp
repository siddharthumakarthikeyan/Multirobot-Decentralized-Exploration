#include <string>
#include <Eigen/Eigen>
#include <iostream>

#include <geometry_msgs/msg/pose_stamped.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <nav_msgs/msg/path.hpp>
#include <quadrotor_msgs/msg/position_command.hpp>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/range.hpp>
#include <visualization_msgs/msg/marker.hpp>

using namespace std;

class OdomVisualization : public rclcpp::Node
{
public:
  OdomVisualization() : Node("odom_visualization")
  {
    // Declare parameters
    this->declare_parameter("mesh_resource", string("package://odom_visualization/meshes/hummingbird.mesh"));
    this->declare_parameter("color.r", 1.0);
    this->declare_parameter("color.g", 0.0);
    this->declare_parameter("color.b", 0.0);
    this->declare_parameter("color.a", 1.0);
    this->declare_parameter("robot_scale", 2.0);
    this->declare_parameter("frame_id", string("world"));
    this->declare_parameter("drone_id", 1);
    this->declare_parameter("drone_num", 1);
    this->declare_parameter("covariance_scale", 100.0);

    // Get parameters
    mesh_resource_ = this->get_parameter("mesh_resource").as_string();
    color_r_ = this->get_parameter("color.r").as_double();
    color_g_ = this->get_parameter("color.g").as_double();
    color_b_ = this->get_parameter("color.b").as_double();
    color_a_ = this->get_parameter("color.a").as_double();
    scale_ = this->get_parameter("robot_scale").as_double();
    frame_id_ = this->get_parameter("frame_id").as_string();
    drone_id_ = this->get_parameter("drone_id").as_int();
    drone_num_ = this->get_parameter("drone_num").as_int();

    // Publishers
    pose_pub_ = this->create_publisher<geometry_msgs::msg::PoseStamped>("pose", 100);
    path_pub_ = this->create_publisher<nav_msgs::msg::Path>("path", 100);
    mesh_pub_ = this->create_publisher<visualization_msgs::msg::Marker>("robot", 100);

    // Subscribers
    odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
      "odom", 100, std::bind(&OdomVisualization::odomCallback, this, std::placeholders::_1));
    cmd_sub_ = this->create_subscription<quadrotor_msgs::msg::PositionCommand>(
      "cmd", 100, std::bind(&OdomVisualization::cmdCallback, this, std::placeholders::_1));

    RCLCPP_INFO(this->get_logger(), "Odom visualization initialized for drone %d", drone_id_);
  }

private:
  Eigen::Vector4d getColor(const double& h, double alpha)
  {
    double h1 = std::max(0.0, std::min(1.0, h));
    double lambda;
    Eigen::Vector4d color1, color2;
    
    if (h1 >= -1e-4 && h1 < 1.0 / 6) {
      lambda = (h1 - 0.0) * 6;
      color1 = Eigen::Vector4d(1, 0, 0, 1);
      color2 = Eigen::Vector4d(1, 0, 1, 1);
    } else if (h1 >= 1.0 / 6 && h1 < 2.0 / 6) {
      lambda = (h1 - 1.0 / 6) * 6;
      color1 = Eigen::Vector4d(1, 0, 1, 1);
      color2 = Eigen::Vector4d(0, 0, 1, 1);
    } else if (h1 >= 2.0 / 6 && h1 < 3.0 / 6) {
      lambda = (h1 - 2.0 / 6) * 6;
      color1 = Eigen::Vector4d(0, 0, 1, 1);
      color2 = Eigen::Vector4d(0, 1, 1, 1);
    } else if (h1 >= 3.0 / 6 && h1 < 4.0 / 6) {
      lambda = (h1 - 3.0 / 6) * 6;
      color1 = Eigen::Vector4d(0, 1, 1, 1);
      color2 = Eigen::Vector4d(0, 1, 0, 1);
    } else if (h1 >= 4.0 / 6 && h1 < 5.0 / 6) {
      lambda = (h1 - 4.0 / 6) * 6;
      color1 = Eigen::Vector4d(0, 1, 0, 1);
      color2 = Eigen::Vector4d(1, 1, 0, 1);
    } else {
      lambda = (h1 - 5.0 / 6) * 6;
      color1 = Eigen::Vector4d(1, 1, 0, 1);
      color2 = Eigen::Vector4d(1, 0, 0, 1);
    }

    Eigen::Vector4d fcolor = (1 - lambda) * color1 + lambda * color2;
    fcolor(3) = alpha;
    return fcolor;
  }

  void odomCallback(const nav_msgs::msg::Odometry::SharedPtr msg)
  {
    if (msg->header.frame_id == string("null")) return;

    // Publish mesh marker
    visualization_msgs::msg::Marker mesh_ros;
    mesh_ros.header.frame_id = frame_id_;
    mesh_ros.header.stamp = msg->header.stamp;
    mesh_ros.ns = "mesh";
    mesh_ros.id = 0;
    mesh_ros.type = visualization_msgs::msg::Marker::MESH_RESOURCE;
    mesh_ros.action = visualization_msgs::msg::Marker::ADD;
    mesh_ros.pose.position.x = msg->pose.pose.position.x;
    mesh_ros.pose.position.y = msg->pose.pose.position.y;
    mesh_ros.pose.position.z = msg->pose.pose.position.z;
    mesh_ros.pose.orientation = msg->pose.pose.orientation;
    mesh_ros.scale.x = scale_;
    mesh_ros.scale.y = scale_;
    mesh_ros.scale.z = scale_;

    if (drone_num_ > 1) {
      auto color = getColor((drone_id_ - 1) / double(drone_num_ - 1), 1);
      mesh_ros.color.r = color[0];
      mesh_ros.color.g = color[1];
      mesh_ros.color.b = color[2];
      mesh_ros.color.a = color[3];
    } else {
      mesh_ros.color.r = color_r_;
      mesh_ros.color.g = color_g_;
      mesh_ros.color.b = color_b_;
      mesh_ros.color.a = color_a_;
    }
    mesh_ros.mesh_resource = mesh_resource_;
    mesh_pub_->publish(mesh_ros);

    // Publish pose
    geometry_msgs::msg::PoseStamped pose_ros;
    pose_ros.header = msg->header;
    pose_ros.header.frame_id = frame_id_;
    pose_ros.pose = msg->pose.pose;
    pose_pub_->publish(pose_ros);

    // Update path
    path_ros_.header = msg->header;
    path_ros_.header.frame_id = frame_id_;
    path_ros_.poses.push_back(pose_ros);
    if (path_ros_.poses.size() > 1000) {
      path_ros_.poses.erase(path_ros_.poses.begin());
    }
    path_pub_->publish(path_ros_);
  }

  void cmdCallback(const quadrotor_msgs::msg::PositionCommand::SharedPtr cmd)
  {
    if (cmd->header.frame_id == string("null")) return;

    visualization_msgs::msg::Marker mesh_ros;
    mesh_ros.header.frame_id = frame_id_;
    mesh_ros.header.stamp = cmd->header.stamp;
    mesh_ros.ns = "mesh";
    mesh_ros.id = 0;
    mesh_ros.type = visualization_msgs::msg::Marker::MESH_RESOURCE;
    mesh_ros.action = visualization_msgs::msg::Marker::ADD;
    mesh_ros.pose.position.x = cmd->position.x;
    mesh_ros.pose.position.y = cmd->position.y;
    mesh_ros.pose.position.z = cmd->position.z;
    mesh_ros.pose.orientation.w = 1.0;
    mesh_ros.pose.orientation.x = 0.0;
    mesh_ros.pose.orientation.y = 0.0;
    mesh_ros.pose.orientation.z = 0.0;
    mesh_ros.scale.x = scale_;
    mesh_ros.scale.y = scale_;
    mesh_ros.scale.z = scale_;
    mesh_ros.color.a = color_a_;
    mesh_ros.color.r = color_r_;
    mesh_ros.color.g = color_g_;
    mesh_ros.color.b = color_b_;
    mesh_ros.mesh_resource = mesh_resource_;
    mesh_pub_->publish(mesh_ros);
  }

  // Publishers
  rclcpp::Publisher<geometry_msgs::msg::PoseStamped>::SharedPtr pose_pub_;
  rclcpp::Publisher<nav_msgs::msg::Path>::SharedPtr path_pub_;
  rclcpp::Publisher<visualization_msgs::msg::Marker>::SharedPtr mesh_pub_;

  // Subscribers
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  rclcpp::Subscription<quadrotor_msgs::msg::PositionCommand>::SharedPtr cmd_sub_;

  // Parameters
  string mesh_resource_, frame_id_;
  double color_r_, color_g_, color_b_, color_a_, scale_;
  int drone_id_, drone_num_;

  // State
  nav_msgs::msg::Path path_ros_;
};

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<OdomVisualization>());
  rclcpp::shutdown();
  return 0;
}
