#include <rclcpp/rclcpp.hpp>
#include <exploration_manager/fast_exploration_manager.h>
#include <active_perception/frontier_finder.h>
#include <exploration_manager/msg/h_grid.hpp>
#include <exploration_manager/msg/grid_tour.hpp>
#include <visualization_msgs/msg/marker.hpp>
#include <traj_utils/planning_visualization.h>

#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <pcl_conversions/pcl_conversions.h>
#include <plan_manage/backward.hpp>

namespace backward {
backward::SignalHandling sh;
}

using namespace fast_planner;

class ExplGroundNode {
public:
  ExplGroundNode(rclcpp::Node::SharedPtr nh) {
    expl_.reset(new FastExplorationManager);
    expl_->initialize(nh);

    frontier_timer_ = nh.createTimer(rclcpp::Duration(0.5), &ExplGroundNode::frontierCallback, this);
    frontier_pub_ = nh.advertise<sensor_msgs::msg::PointCloud2>("/expl_ground_node/frontier", 10);
    grid_pub_ = nh.advertise<visualization_msgs::msg::Marker>("/expl_ground_node/grid", 10);

    grid_tour_sub_ =
        nh.subscribe("/swarm_expl/grid_tour_recv", 10, &ExplGroundNode::gridTourCallback, this);
    hgrid_sub_ = nh.subscribe("/swarm_expl/hgrid_recv", 10, &ExplGroundNode::HGridCallback, this);

    nh.param("exploration/drone_num", drone_num_, 4);

    grid_tour_stamp_.resize(drone_num_);
    for (auto& st : grid_tour_stamp_) st = 0.0;
    hgrid_stamp_ = 0.0;
  }

  ~ExplGroundNode() {
  }

private:
  void frontierCallback(/*timer*/) {
    static int delay = 0;
    if (++delay < 5) return;

    // Detect frontier
    auto ft = expl_->frontier_finder_;
    ft->searchFrontiers();
    ft->computeFrontiersToVisit();
    // ft->updateFrontierCostMatrix();

    vector<vector<Eigen::Vector3d>> ftrs;
    ft->getFrontiers(ftrs);

    // Draw frontier as point cloud
    pcl::PointXYZ pt;
    pcl::PointCloud<pcl::PointXYZ> cloud;

    for (auto cluster : ftrs) {
      for (auto cell : cluster) {
        pt.x = cell[0];
        pt.y = cell[1];
        pt.z = cell[2];
        cloud.push_back(pt);
      }
    }
    cloud.width = cloud.points.size();
    cloud.height = 1;
    cloud.is_dense = true;
    cloud.header.frame_id = "world";
    sensor_msgs::msg::PointCloud2 cloud_msg;
    pcl::toROSMsg(cloud, cloud_msg);
    frontier_pub_.publish(cloud_msg);
  }

  void HGridCallback(const exploration_manager::HGrid::ConstSharedPtr& msg) {
    if (msg->stamp <= hgrid_stamp_ + 1e-4) return;

    visualization_msgs::msg::Marker mk;
    mk.header.frame_id = "world";
    mk.header.stamp = this->now();
    mk.id = 0;
    mk.ns = "hgrid";
    mk.type = visualization_msgs::msg::Marker::LINE_LIST;

    mk.pose.orientation.x = 0.0;
    mk.pose.orientation.y = 0.0;
    mk.pose.orientation.z = 0.0;
    mk.pose.orientation.w = 1.0;

    mk.color.r = 1.0;
    mk.color.g = 0.0;
    mk.color.b = 1.0;
    mk.color.a = 0.5;

    mk.scale.x = 0.05;
    mk.scale.y = 0.05;
    mk.scale.z = 0.05;

    mk.action = visualization_msgs::msg::Marker::DELETE;
    grid_pub_.publish(mk);

    for (int i = 0; i < msg->points1.size(); ++i) {
      mk.points.push_back(msg->points1[i]);
      mk.points.push_back(msg->points2[i]);
    }

    mk.action = visualization_msgs::msg::Marker::ADD;
    grid_pub_.publish(mk);
    rclcpp::Duration(0.0005).sleep();

    hgrid_stamp_ = msg->stamp;
  }

  void gridTourCallback(const exploration_manager::GridTour::ConstSharedPtr& msg) {
    if (msg->stamp <= grid_tour_stamp_[msg->drone_id - 1] + 1e-4) return;
    if (msg->points.empty()) return;

    visualization_msgs::msg::Marker mk;
    mk.header.frame_id = "world";
    mk.header.stamp = this->now();
    mk.id = msg->drone_id;
    mk.ns = "grid tour";
    mk.type = visualization_msgs::msg::Marker::LINE_LIST;

    mk.pose.orientation.x = 0.0;
    mk.pose.orientation.y = 0.0;
    mk.pose.orientation.z = 0.0;
    mk.pose.orientation.w = 1.0;

    auto color = PlanningVisualization::getColor((msg->drone_id - 1) / double(drone_num_));

    mk.color.r = color(0);
    mk.color.g = color(1);
    mk.color.b = color(2);
    mk.color.a = color(3);

    mk.scale.x = 0.05;
    mk.scale.y = 0.05;
    mk.scale.z = 0.05;

    mk.action = visualization_msgs::msg::Marker::DELETE;
    grid_pub_.publish(mk);

    for (int i = 0; i < msg->points.size() - 1; ++i) {
      auto pt1 = msg->points[i];
      auto pt2 = msg->points[i + 1];
      mk.points.push_back(pt1);
      mk.points.push_back(pt2);
    }

    mk.action = visualization_msgs::msg::Marker::ADD;
    grid_pub_.publish(mk);
    rclcpp::Duration(0.0005).sleep();

    grid_tour_stamp_[msg->drone_id - 1] = msg->stamp;
  }

  // Data ------------------------
  shared_ptr<FastExplorationManager> expl_;

  rclcpp::TimerBase::SharedPtr frontier_timer_;
  rclcpp::Publisher<std_msgs::msg::Empty>::SharedPtr frontier_pub_, grid_pub_;
  rclcpp::Subscription<std_msgs::msg::Empty>::SharedPtr grid_tour_sub_, hgrid_sub_;

  vector<double> grid_tour_stamp_;
  double hgrid_stamp_;
  int drone_num_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::Node::SharedPtr nh("~");

  ExplGroundNode ground_node(nh);

  rclcpp::Duration(1.0).sleep();
  rclcpp::spin(node);

  return 0;
}
