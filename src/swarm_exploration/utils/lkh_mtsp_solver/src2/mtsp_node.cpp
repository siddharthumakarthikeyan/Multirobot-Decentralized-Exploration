#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/empty.hpp>
#include <string>
#include <fstream>

#include <lkh_mtsp_solver/lkh3_interface.h>
#include <lkh_mtsp_solver/srv/solve_mtsp.hpp>

using std::string;

std::string mtsp_dir1_;
std::string mtsp_dir2_;
std::string mtsp_dir3_;
int drone_id_, problem_id_;
rclcpp::Node::SharedPtr g_node;

void mtspCallback(
    const std::shared_ptr<lkh_mtsp_solver::srv::SolveMTSP::Request> req,
    std::shared_ptr<lkh_mtsp_solver::srv::SolveMTSP::Response> res) {

  RCLCPP_INFO(g_node->get_logger(), "MTSP callback called with prob=%d", req->prob);
  
  std::string par_file;
  if (req->prob == 1) {
    par_file = mtsp_dir1_;
  } else if (req->prob == 2) {
    par_file = mtsp_dir2_;
  } else if (req->prob == 3) {
    par_file = mtsp_dir3_;
  } else {
    RCLCPP_WARN(g_node->get_logger(), "Unknown prob value: %d, defaulting to mtsp_dir1", req->prob);
    par_file = mtsp_dir1_;
  }
  
  RCLCPP_INFO(g_node->get_logger(), "Opening par file: %s", par_file.c_str());
  
  // Check if file exists before trying to solve
  std::ifstream test_file(par_file);
  if (!test_file.good()) {
    RCLCPP_ERROR(g_node->get_logger(), "Par file does not exist: %s - skipping solve", par_file.c_str());
    res->empty = 1;  // Indicate failure
    return;
  }
  test_file.close();
  
  if (req->prob == 3) {
    std::string cmd = "/usr/local/bin/LKH " + mtsp_dir3_;
    system(cmd.c_str());
  } else {
    solveMTSPWithLKH3(par_file.c_str());
  }
  
  res->empty = 0;  // Indicate success
  RCLCPP_INFO(g_node->get_logger(), "MTSP callback completed for prob=%d", req->prob);
}

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  g_node = std::make_shared<rclcpp::Node>("mtsp_node");

  // Read mtsp file dir
  std::string mtsp_dir;
  g_node->declare_parameter("exploration.mtsp_dir", std::string("null"));
  g_node->declare_parameter("exploration.drone_id", 1);
  g_node->declare_parameter("exploration.problem_id", 1);
  
  g_node->get_parameter("exploration.mtsp_dir", mtsp_dir);
  g_node->get_parameter("exploration.drone_id", drone_id_);
  g_node->get_parameter("exploration.problem_id", problem_id_);
  
  RCLCPP_INFO(g_node->get_logger(), "MTSP dir: %s, drone_id: %d, problem_id: %d", mtsp_dir.c_str(), drone_id_, problem_id_);

  mtsp_dir1_ = mtsp_dir + "/amtsp_" + std::to_string(drone_id_) + ".par";
  mtsp_dir2_ = mtsp_dir + "/amtsp2_" + std::to_string(drone_id_) + ".par";
  mtsp_dir3_ = mtsp_dir + "/amtsp3_" + std::to_string(drone_id_) + ".par";

  string service_name;
  if (problem_id_ == 1) {  // TSP
    service_name = "/solve_tsp_" + std::to_string(drone_id_);
  } else if (problem_id_ == 2) {  // ACVRP
    service_name = "/solve_acvrp_" + std::to_string(drone_id_);
  }
  auto mtsp_server = g_node->create_service<lkh_mtsp_solver::srv::SolveMTSP>(service_name, mtspCallback);

  RCLCPP_WARN(g_node->get_logger(), "MTSP server %d is ready.", drone_id_);
  rclcpp::spin(g_node);

  return 0;
}
