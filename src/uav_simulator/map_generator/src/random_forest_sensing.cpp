#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <pcl/kdtree/kdtree_flann.h>
#include <pcl_conversions/pcl_conversions.h>
#include <iostream>
#include <thread>
#include <chrono>

#include <geometry_msgs/msg/pose_stamped.hpp>
#include <geometry_msgs/msg/vector3.hpp>
#include <math.h>
#include <nav_msgs/msg/odometry.hpp>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <Eigen/Eigen>
#include <random>

using namespace std;

class RandomForestMap : public rclcpp::Node
{
public:
  RandomForestMap() : Node("random_forest")
  {
    // Declare parameters
    this->declare_parameter("init_state_x", 0.0);
    this->declare_parameter("init_state_y", 0.0);
    this->declare_parameter("map.x_size", 50.0);
    this->declare_parameter("map.y_size", 50.0);
    this->declare_parameter("map.z_size", 5.0);
    this->declare_parameter("map.obs_num", 30);
    this->declare_parameter("map.resolution", 0.1);
    this->declare_parameter("map.circle_num", 30);
    this->declare_parameter("ObstacleShape.lower_rad", 0.3);
    this->declare_parameter("ObstacleShape.upper_rad", 0.8);
    this->declare_parameter("ObstacleShape.lower_hei", 3.0);
    this->declare_parameter("ObstacleShape.upper_hei", 7.0);
    this->declare_parameter("ObstacleShape.radius_l", 7.0);
    this->declare_parameter("ObstacleShape.radius_h", 7.0);
    this->declare_parameter("ObstacleShape.z_l", 7.0);
    this->declare_parameter("ObstacleShape.z_h", 7.0);
    this->declare_parameter("ObstacleShape.theta", 7.0);
    this->declare_parameter("ObstacleShape.seed", -1);
    this->declare_parameter("sensing.radius", 10.0);
    this->declare_parameter("sensing.rate", 10.0);

    // Get parameters
    init_x_ = this->get_parameter("init_state_x").as_double();
    init_y_ = this->get_parameter("init_state_y").as_double();
    x_size_ = this->get_parameter("map.x_size").as_double();
    y_size_ = this->get_parameter("map.y_size").as_double();
    z_size_ = this->get_parameter("map.z_size").as_double();
    obs_num_ = this->get_parameter("map.obs_num").as_int();
    resolution_ = this->get_parameter("map.resolution").as_double();
    circle_num_ = this->get_parameter("map.circle_num").as_int();
    w_l_ = this->get_parameter("ObstacleShape.lower_rad").as_double();
    w_h_ = this->get_parameter("ObstacleShape.upper_rad").as_double();
    h_l_ = this->get_parameter("ObstacleShape.lower_hei").as_double();
    h_h_ = this->get_parameter("ObstacleShape.upper_hei").as_double();
    radius_l_ = this->get_parameter("ObstacleShape.radius_l").as_double();
    radius_h_ = this->get_parameter("ObstacleShape.radius_h").as_double();
    z_l_ = this->get_parameter("ObstacleShape.z_l").as_double();
    z_h_ = this->get_parameter("ObstacleShape.z_h").as_double();
    theta_ = this->get_parameter("ObstacleShape.theta").as_double();
    int seed = this->get_parameter("ObstacleShape.seed").as_int();
    sensing_range_ = this->get_parameter("sensing.radius").as_double();
    sense_rate_ = this->get_parameter("sensing.rate").as_double();

    min_x_ = -x_size_ / 2.0;
    max_x_ = +x_size_ / 2.0;
    min_y_ = -y_size_ / 2.0;
    max_y_ = +y_size_ / 2.0;
    obs_num_ = min(obs_num_, (int)x_size_ * 10);

    // Publishers and subscribers
    local_map_pub_ = this->create_publisher<sensor_msgs::msg::PointCloud2>("/map_generator/local_cloud", 1);
    all_map_pub_ = this->create_publisher<sensor_msgs::msg::PointCloud2>("/map_generator/global_cloud", 1);
    click_map_pub_ = this->create_publisher<sensor_msgs::msg::PointCloud2>("/pcl_render_node/local_map", 1);
    
    odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
      "odometry", 50, std::bind(&RandomForestMap::rcvOdometryCallback, this, std::placeholders::_1));
    click_sub_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
      "/move_base_simple/goal", 10, std::bind(&RandomForestMap::clickCallback, this, std::placeholders::_1));

    // Init random device
    if (seed < 0) {
      seed = rd_() % INT32_MAX;
    }
    RCLCPP_INFO(this->get_logger(), "Map seed: %d", seed);
    eng_ = default_random_engine(seed);

    // Wait a bit then generate map
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    randomMapGenerate();

    // Timer for publishing
    int period_ms = static_cast<int>(1000.0 / sense_rate_);
    timer_ = this->create_wall_timer(
      std::chrono::milliseconds(period_ms), std::bind(&RandomForestMap::pubSensedPoints, this));
  }

private:
  void randomMapGenerate()
  {
    pcl::PointXYZ pt_random;

    rand_x_ = uniform_real_distribution<double>(min_x_, max_x_);
    rand_y_ = uniform_real_distribution<double>(min_y_, max_y_);
    rand_w_ = uniform_real_distribution<double>(w_l_, w_h_);
    rand_h_ = uniform_real_distribution<double>(h_l_, h_h_);
    rand_radius_ = uniform_real_distribution<double>(radius_l_, radius_h_);
    rand_radius2_ = uniform_real_distribution<double>(radius_l_, 1.2);
    rand_theta_ = uniform_real_distribution<double>(-theta_, theta_);
    rand_z_ = uniform_real_distribution<double>(z_l_, z_h_);

    // Generate polar obs
    for (int i = 0; i < obs_num_; i++) {
      double x, y, w, h;
      x = rand_x_(eng_);
      y = rand_y_(eng_);
      w = rand_w_(eng_);

      if (sqrt(pow(x - init_x_, 2) + pow(y - init_y_, 2)) < 2.0) {
        i--;
        continue;
      }

      x = floor(x / resolution_) * resolution_ + resolution_ / 2.0;
      y = floor(y / resolution_) * resolution_ + resolution_ / 2.0;

      int widNum = ceil(w / resolution_);

      for (int r = -widNum / 2.0; r < widNum / 2.0; r++)
        for (int s = -widNum / 2.0; s < widNum / 2.0; s++) {
          h = rand_h_(eng_);
          int heiNum = ceil(h / resolution_);
          for (int t = -30; t < heiNum; t++) {
            pt_random.x = x + r * resolution_ + 1e-2;
            pt_random.y = y + s * resolution_ + 1e-2;
            pt_random.z = (t + 0.5) * resolution_ + 1e-2;
            cloud_map_.points.push_back(pt_random);
          }
        }
    }

    // Generate circle obs
    for (int i = 0; i < circle_num_; ++i) {
      double x, y, z;
      x = rand_x_(eng_);
      y = rand_y_(eng_);
      z = rand_z_(eng_);

      x = floor(x / resolution_) * resolution_ + resolution_ / 2.0;
      y = floor(y / resolution_) * resolution_ + resolution_ / 2.0;
      z = floor(z / resolution_) * resolution_ + resolution_ / 2.0;

      double theta = rand_theta_(eng_);
      Eigen::Matrix3d rotate;
      rotate << cos(theta), -sin(theta), 0.0, sin(theta), cos(theta), 0.0, 0, 0, 1;

      double radius1 = rand_radius_(eng_);
      double radius2 = rand_radius2_(eng_);

      Eigen::Vector3d cpt;
      for (double angle = 0.0; angle < 6.282; angle += resolution_ / 2) {
        cpt(0) = 0.0;
        cpt(1) = radius1 * cos(angle);
        cpt(2) = radius2 * sin(angle);

        Eigen::Vector3d cpt_if;
        for (int ifx = -0; ifx <= 0; ++ifx)
          for (int ify = -0; ify <= 0; ++ify)
            for (int ifz = -0; ifz <= 0; ++ifz) {
              cpt_if = cpt + Eigen::Vector3d(ifx * resolution_, ify * resolution_, ifz * resolution_);
              cpt_if = rotate * cpt_if + Eigen::Vector3d(x, y, z);
              pt_random.x = cpt_if(0);
              pt_random.y = cpt_if(1);
              pt_random.z = cpt_if(2);
              cloud_map_.push_back(pt_random);
            }
      }
    }

    // Add ground
    for (double x = min_x_; x < max_x_; x += resolution_) {
      for (double y = min_y_; y < max_y_; y += resolution_) {
        pt_random.x = x;
        pt_random.y = y;
        pt_random.z = -0.1;
        cloud_map_.push_back(pt_random);
      }
    }

    cloud_map_.width = cloud_map_.points.size();
    cloud_map_.height = 1;
    cloud_map_.is_dense = true;

    RCLCPP_WARN(this->get_logger(), "Finished generate random map with %zu points", cloud_map_.points.size());
    kdtree_local_map_.setInputCloud(cloud_map_.makeShared());
    map_ok_ = true;
  }

  void rcvOdometryCallback(const nav_msgs::msg::Odometry::SharedPtr odom)
  {
    if (odom->child_frame_id == "X" || odom->child_frame_id == "O") return;
    has_odom_ = true;
    state_ = {odom->pose.pose.position.x, odom->pose.pose.position.y, odom->pose.pose.position.z,
              odom->twist.twist.linear.x, odom->twist.twist.linear.y, odom->twist.twist.linear.z,
              0.0, 0.0, 0.0};
  }

  void pubSensedPoints()
  {
    pcl::toROSMsg(cloud_map_, global_map_pcd_);
    global_map_pcd_.header.frame_id = "world";
    global_map_pcd_.header.stamp = this->now();
    all_map_pub_->publish(global_map_pcd_);
  }

  void clickCallback(const geometry_msgs::msg::PoseStamped::SharedPtr msg)
  {
    double x = msg->pose.position.x;
    double y = msg->pose.position.y;
    double w = 0.6;
    double h;
    pcl::PointXYZ pt_random;
    RCLCPP_INFO(this->get_logger(), "Click: %f, %f", x, y);

    x = floor(x / 0.5) * 0.5 + 0.5 / 2.0;
    y = floor(y / 0.5) * 0.5 + 0.5 / 2.0;

    double res2 = resolution_ * 0.5;
    int wid_num2 = ceil(w / res2);

    for (int r = -wid_num2 / 2.0; r < wid_num2 / 2.0; r++)
      for (int s = -wid_num2 / 2.0; s < wid_num2 / 2.0; s++) {
        h = rand_h_(eng_);
        int heiNum = ceil(2.5 / res2);
        int hei_num2 = ceil(1 / res2);
        for (int t = -hei_num2; t < heiNum; t++) {
          pt_random.x = x + (r + 0.5) * res2 + 1e-2;
          pt_random.y = y + (s + 0.5) * res2 + 1e-2;
          pt_random.z = (t + 0.5) * res2 + 1e-2;
          clicked_cloud_.points.push_back(pt_random);
          cloud_map_.points.push_back(pt_random);
        }
      }
    clicked_cloud_.width = clicked_cloud_.points.size();
    clicked_cloud_.height = 1;
    clicked_cloud_.is_dense = true;

    sensor_msgs::msg::PointCloud2 local_pcd;
    pcl::toROSMsg(clicked_cloud_, local_pcd);
    local_pcd.header.frame_id = "world";
    local_pcd.header.stamp = this->now();
    click_map_pub_->publish(local_pcd);
    cloud_map_.width = cloud_map_.points.size();
  }

  // Publishers and subscribers
  rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr local_map_pub_;
  rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr all_map_pub_;
  rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr click_map_pub_;
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr click_sub_;
  rclcpp::TimerBase::SharedPtr timer_;

  // Data
  pcl::KdTreeFLANN<pcl::PointXYZ> kdtree_local_map_;
  pcl::PointCloud<pcl::PointXYZ> cloud_map_;
  pcl::PointCloud<pcl::PointXYZ> clicked_cloud_;
  sensor_msgs::msg::PointCloud2 global_map_pcd_;
  vector<double> state_;

  // Random
  random_device rd_;
  default_random_engine eng_;
  uniform_real_distribution<double> rand_x_, rand_y_, rand_w_, rand_h_;
  uniform_real_distribution<double> rand_radius_, rand_radius2_, rand_theta_, rand_z_;

  // Parameters
  int obs_num_, circle_num_;
  double x_size_, y_size_, z_size_;
  double min_x_, max_x_, min_y_, max_y_;
  double w_l_, w_h_, h_l_, h_h_;
  double radius_l_, radius_h_, z_l_, z_h_, theta_;
  double sensing_range_, resolution_, sense_rate_;
  double init_x_, init_y_;

  bool map_ok_ = false;
  bool has_odom_ = false;
};

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<RandomForestMap>());
  rclcpp::shutdown();
  return 0;
}
