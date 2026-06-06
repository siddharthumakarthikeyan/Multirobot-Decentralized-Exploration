#ifndef _FAST_EXPLORATION_FSM_H_
#define _FAST_EXPLORATION_FSM_H_

#include <Eigen/Eigen>

#include <rclcpp/rclcpp.hpp>
#include <nav_msgs/msg/path.hpp>
#include <std_msgs/msg/empty.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <visualization_msgs/msg/marker.hpp>
#include <exploration_manager/msg/drone_state.hpp>
#include <exploration_manager/msg/pair_opt.hpp>
#include <exploration_manager/msg/pair_opt_response.hpp>
#include <exploration_manager/msg/h_grid.hpp>
#include <exploration_manager/msg/grid_tour.hpp>
#include <bspline/msg/bspline.hpp>

#include <algorithm>
#include <iostream>
#include <vector>
#include <memory>
#include <string>
#include <thread>

using Eigen::Vector3d;
using std::shared_ptr;
using std::string;
using std::unique_ptr;
using std::vector;

namespace fast_planner {
class FastPlannerManager;
class FastExplorationManager;
class PlanningVisualization;
struct FSMParam;
struct FSMData;

enum EXPL_STATE { INIT, WAIT_TRIGGER, PLAN_TRAJ, PUB_TRAJ, EXEC_TRAJ, FINISH, IDLE };

class FastExplorationFSM {

public:
  FastExplorationFSM(/* args */) {
  }
  ~FastExplorationFSM() {
  }

  void init(rclcpp::Node::SharedPtr nh);

  EIGEN_MAKE_ALIGNED_OPERATOR_NEW

private:
  /* helper functions */
  int callExplorationPlanner();
  void transitState(EXPL_STATE new_state, string pos_call);
  void visualize(int content);
  void clearVisMarker();
  int getId();
  void findUnallocated(const vector<int>& actives, vector<int>& missed);

  /* ROS functions */
  void FSMCallback(/*timer*/);
  void safetyCallback(/*timer*/);
  void frontierCallback(/*timer*/);
  void triggerCallback(const geometry_msgs::msg::PoseStamped::ConstSharedPtr& msg);
  void odometryCallback(const nav_msgs::msg::Odometry::ConstSharedPtr& msg);

  // Swarm
  void droneStateTimerCallback(/*timer*/);
  void droneStateMsgCallback(const exploration_manager::msg::DroneState::ConstSharedPtr& msg);
  void optTimerCallback(/*timer*/);
  void optMsgCallback(const exploration_manager::msg::PairOpt::ConstSharedPtr& msg);
  void optResMsgCallback(const exploration_manager::msg::PairOptResponse::ConstSharedPtr& msg);
  void swarmTrajCallback(const bspline::msg::Bspline::ConstSharedPtr& msg);
  void swarmTrajTimerCallback(/*timer*/);

  /* planning utils */
  shared_ptr<FastPlannerManager> planner_manager_;
  shared_ptr<FastExplorationManager> expl_manager_;
  shared_ptr<PlanningVisualization> visualization_;

  shared_ptr<FSMParam> fp_;
  shared_ptr<FSMData> fd_;
  EXPL_STATE state_;

  /* ROS utils */
  rclcpp::Node::SharedPtr node_;
  rclcpp::TimerBase::SharedPtr exec_timer_, safety_timer_, vis_timer_, frontier_timer_;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr trigger_sub_;
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  rclcpp::Publisher<std_msgs::msg::Empty>::SharedPtr replan_pub_, new_pub_;
  rclcpp::Publisher<bspline::msg::Bspline>::SharedPtr bspline_pub_;

  // Swarm state
  rclcpp::Publisher<exploration_manager::msg::DroneState>::SharedPtr drone_state_pub_;
  rclcpp::Publisher<exploration_manager::msg::PairOpt>::SharedPtr opt_pub_;
  rclcpp::Publisher<exploration_manager::msg::PairOptResponse>::SharedPtr opt_res_pub_;
  rclcpp::Publisher<bspline::msg::Bspline>::SharedPtr swarm_traj_pub_;
  rclcpp::Publisher<exploration_manager::msg::GridTour>::SharedPtr grid_tour_pub_;
  rclcpp::Publisher<exploration_manager::msg::HGrid>::SharedPtr hgrid_pub_;
  rclcpp::Subscription<exploration_manager::msg::DroneState>::SharedPtr drone_state_sub_;
  rclcpp::Subscription<exploration_manager::msg::PairOpt>::SharedPtr opt_sub_;
  rclcpp::Subscription<exploration_manager::msg::PairOptResponse>::SharedPtr opt_res_sub_;
  rclcpp::Subscription<bspline::msg::Bspline>::SharedPtr swarm_traj_sub_;
  rclcpp::TimerBase::SharedPtr drone_state_timer_, opt_timer_, swarm_traj_timer_;
};

}  // namespace fast_planner

#endif