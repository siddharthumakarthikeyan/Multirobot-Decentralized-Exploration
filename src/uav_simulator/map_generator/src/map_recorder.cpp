#include <pcl/io/pcd_io.h>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <pcl_conversions/pcl_conversions.h>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <thread>
#include <chrono>

using namespace std;

bool finish = false;

void cloudCallback(const sensor_msgs::msg::PointCloud2::SharedPtr msg) {
  pcl::PointCloud<pcl::PointXYZ> cloud;
  pcl::fromROSMsg(*msg, cloud);
  pcl::io::savePCDFileASCII("/home/boboyu/Downloads/tmp.pcd", cloud);

  cout << "map saved." << endl;
  finish = true;
}

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<rclcpp::Node>("map_recorder");

  // Generate map by clicking
  auto cloud_sub = node->create_subscription<sensor_msgs::msg::PointCloud2>(
      "/map_generator/global_cloud", 10, cloudCallback);
  std::this_thread::sleep_for(std::chrono::seconds(1));

  while (rclcpp::ok()) {
    rclcpp::spin_some(node);
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    if (finish) break;
  }

  // cout << "finish record map." << endl;
  RCLCPP_WARN(rclcpp::get_logger("racer"), "[Map Recorder]: finish record map.");
  return 0;
}
