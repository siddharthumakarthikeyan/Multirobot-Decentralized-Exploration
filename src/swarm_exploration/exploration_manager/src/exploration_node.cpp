#include <rclcpp/rclcpp.hpp>
#include <exploration_manager/fast_exploration_fsm.h>
#include <chrono>

#include <plan_manage/backward.hpp>
namespace backward {
backward::SignalHandling sh;
}

using namespace fast_planner;

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<rclcpp::Node>("exploration_node");

  FastExplorationFSM expl_fsm;
  expl_fsm.init(node);

  std::this_thread::sleep_for(std::chrono::seconds(1));
  
  // Use MultiThreadedExecutor to allow service responses while in callbacks
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();

  return 0;
}
