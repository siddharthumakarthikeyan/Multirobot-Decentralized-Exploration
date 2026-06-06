#include <plan_env/sdf_map.h>
#include <plan_env/map_ros.h>
#include <plan_env/multi_map_manager.h>

#include <type_traits>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <visualization_msgs/msg/marker.hpp>

#include <fstream>
#include <functional>
#include <chrono>

namespace fast_planner {
MapROS::MapROS() {
}

MapROS::~MapROS() {
}

void MapROS::setMap(SDFMap* map) {
  this->map_ = map;
}

// Helper function to declare and get parameters (handles string-to-type conversion for launch files)
template<typename T>
static T declare_param(rclcpp::Node::SharedPtr& nh, const std::string& name, const T& default_value) {
  try {
    // Declare as generic parameter that accepts any type
    if (!nh->has_parameter(name)) {
      nh->declare_parameter(name, rclcpp::ParameterValue(default_value));
    }
    
    rclcpp::Parameter param = nh->get_parameter(name);
    
    // Handle string parameters (from LaunchConfiguration)
    if (param.get_type() == rclcpp::ParameterType::PARAMETER_STRING) {
      std::string str_val = param.as_string();
      if (str_val.empty()) return default_value;
      
      if constexpr (std::is_same_v<T, double>) {
        return std::stod(str_val);
      } else if constexpr (std::is_same_v<T, int>) {
        return std::stoi(str_val);
      } else if constexpr (std::is_same_v<T, bool>) {
        return str_val == "true" || str_val == "True" || str_val == "1";
      } else if constexpr (std::is_same_v<T, std::string>) {
        return str_val;
      }
      return default_value;
    }
    
    // Handle native types
    if (param.get_type() == rclcpp::ParameterType::PARAMETER_DOUBLE) {
      if constexpr (std::is_same_v<T, double>) {
        return param.as_double();
      } else if constexpr (std::is_same_v<T, int>) {
        return static_cast<int>(param.as_double());
      }
    } else if (param.get_type() == rclcpp::ParameterType::PARAMETER_INTEGER) {
      if constexpr (std::is_same_v<T, int>) {
        return static_cast<int>(param.as_int());
      } else if constexpr (std::is_same_v<T, double>) {
        return static_cast<double>(param.as_int());
      }
    } else if (param.get_type() == rclcpp::ParameterType::PARAMETER_BOOL) {
      if constexpr (std::is_same_v<T, bool>) {
        return param.as_bool();
      }
    }
    
    // Try direct get as fallback
    return param.get_value<T>();
  } catch (const std::exception& e) {
    RCLCPP_WARN(nh->get_logger(), "Failed to get param %s: %s, using default", name.c_str(), e.what());
    return default_value;
  }
}

void MapROS::init() {
  fx_ = declare_param(node_, "map_ros.fx", -1.0);
  fy_ = declare_param(node_, "map_ros.fy", -1.0);
  cx_ = declare_param(node_, "map_ros.cx", -1.0);
  cy_ = declare_param(node_, "map_ros.cy", -1.0);
  depth_filter_maxdist_ = declare_param(node_, "map_ros.depth_filter_maxdist", -1.0);
  depth_filter_mindist_ = declare_param(node_, "map_ros.depth_filter_mindist", -1.0);
  depth_filter_margin_ = declare_param(node_, "map_ros.depth_filter_margin", -1);
  k_depth_scaling_factor_ = declare_param(node_, "map_ros.k_depth_scaling_factor", -1.0);
  skip_pixel_ = declare_param(node_, "map_ros.skip_pixel", -1);

  esdf_slice_height_ = declare_param(node_, "map_ros.esdf_slice_height", -0.1);
  visualization_truncate_height_ = declare_param(node_, "map_ros.visualization_truncate_height", -0.1);
  visualization_truncate_low_ = declare_param(node_, "map_ros.visualization_truncate_low", -0.1);
  show_occ_time_ = declare_param(node_, "map_ros.show_occ_time", false);
  show_esdf_time_ = declare_param(node_, "map_ros.show_esdf_time", false);
  show_all_map_ = declare_param(node_, "map_ros.show_all_map", false);
  frame_id_ = declare_param(node_, "map_ros.frame_id", std::string("world"));

  proj_points_.resize(640 * 480 / (skip_pixel_ * skip_pixel_));
  point_cloud_.points.resize(640 * 480 / (skip_pixel_ * skip_pixel_));
  // proj_points_.reserve(640 * 480 / map_->mp_->skip_pixel_ / map_->mp_->skip_pixel_);
  proj_points_cnt = 0;

  local_updated_ = false;
  esdf_need_update_ = false;
  fuse_time_ = 0.0;
  esdf_time_ = 0.0;
  max_fuse_time_ = 0.0;
  max_esdf_time_ = 0.0;
  fuse_num_ = 0;
  esdf_num_ = 0;
  depth_image_.reset(new cv::Mat);

  rand_noise_ = normal_distribution<double>(0, 0.1);
  random_device rd;
  eng_ = default_random_engine(rd());

  esdf_timer_ = node_->create_wall_timer(
      std::chrono::milliseconds(50), std::bind(&MapROS::updateESDFCallback, this));
  vis_timer_ = node_->create_wall_timer(
      std::chrono::milliseconds(200), std::bind(&MapROS::visCallback, this));

  map_all_pub_ = node_->create_publisher<sensor_msgs::msg::PointCloud2>("/sdf_map/occupancy_all", 10);
  map_local_pub_ = node_->create_publisher<sensor_msgs::msg::PointCloud2>("/sdf_map/occupancy_local", 10);
  map_local_inflate_pub_ =
      node_->create_publisher<sensor_msgs::msg::PointCloud2>("/sdf_map/occupancy_local_inflate", 10);
  unknown_pub_ = node_->create_publisher<sensor_msgs::msg::PointCloud2>("/sdf_map/unknown", 10);
  esdf_pub_ = node_->create_publisher<sensor_msgs::msg::PointCloud2>("/sdf_map/esdf", 10);
  update_range_pub_ = node_->create_publisher<visualization_msgs::msg::Marker>("/sdf_map/update_range", 10);
  depth_pub_ = node_->create_publisher<sensor_msgs::msg::PointCloud2>("/sdf_map/depth_cloud", 10);

  // basecoor_sub_ = node_->create_subscription("/sdf_map/basecoor", 10, &MapROS::basecoorCallback, this);

  // BYPASS message_filters synchronizer - use direct subscribers with latest pose
  // This fixes the sync issue where depth and pose timestamps don't match
  rclcpp::QoS qos(50);
  qos.reliable();  // Match publisher QoS
  qos.durability_volatile();
  
  pose_direct_sub_ = node_->create_subscription<geometry_msgs::msg::PoseStamped>(
      "/map_ros/pose", qos,
      std::bind(&MapROS::poseCallback, this, std::placeholders::_1));
  
  depth_direct_sub_ = node_->create_subscription<sensor_msgs::msg::Image>(
      "/map_ros/depth", qos,
      std::bind(&MapROS::depthCallback, this, std::placeholders::_1));
  
  RCLCPP_INFO(node_->get_logger(), "MapROS: Using direct depth/pose subscribers (sync bypass)");

  map_start_time_ = node_->now();
}

void MapROS::visCallback() {
  publishMapLocal();
  if (show_all_map_) {
    // Limit the frequency of all map
    static rclcpp::Time last_pub_time = node_->now();
    rclcpp::Time current_time = node_->now();
    double tpass = (current_time - last_pub_time).seconds();
    if (tpass > 0.1) {
      publishMapAll();
      last_pub_time = current_time;
    }
    // static double tpass2 = 0.0;
    // tpass2 += (e.current_real - e.last_real).toSec();
    // if (tpass2 > 0.2) {
    //   publishUnknown();
    //   tpass2 = 0.0;
    // }
  }
  // publishUnknown();
  // publishESDF();

  publishUpdateRange();
  // publishDepth();
}

void MapROS::updateESDFCallback() {
  if (!esdf_need_update_) return;
  auto t1 = node_->now();

  map_->updateESDF3d();
  esdf_need_update_ = false;

  auto t2 = node_->now();
  esdf_time_ += (t2 - t1).seconds();
  max_esdf_time_ = max(max_esdf_time_, (t2 - t1).seconds());
  esdf_num_++;
  if (show_esdf_time_)
    RCLCPP_WARN(rclcpp::get_logger("racer"), "ESDF t: cur: %lf, avg: %lf, max: %lf", (t2 - t1).seconds(), esdf_time_ / esdf_num_,
        max_esdf_time_);
}

void MapROS::depthPoseCallback(
    const sensor_msgs::msg::Image::ConstSharedPtr& img, const geometry_msgs::msg::PoseStamped::ConstSharedPtr& pose) {
  static int depth_callback_count = 0;
  if (depth_callback_count++ % 50 == 0) {
    RCLCPP_INFO(rclcpp::get_logger("map_ros"), "depthPoseCallback called #%d, pose=(%.1f,%.1f,%.1f)",
      depth_callback_count, pose->pose.position.x, pose->pose.position.y, pose->pose.position.z);
  }
  camera_pos_(0) = pose->pose.position.x;
  camera_pos_(1) = pose->pose.position.y;
  camera_pos_(2) = pose->pose.position.z;
  if (!map_->isInMap(camera_pos_))  // exceed mapped region
    return;

  // Simulate swarm communication
  map_->mm_->drone_pos_ = camera_pos_;

  camera_q_ = Eigen::Quaterniond(pose->pose.orientation.w, pose->pose.orientation.x,
      pose->pose.orientation.y, pose->pose.orientation.z);
  cv_bridge::CvImagePtr cv_ptr = cv_bridge::toCvCopy(img, img->encoding);
  if (img->encoding == sensor_msgs::image_encodings::TYPE_32FC1)
    (cv_ptr->image).convertTo(cv_ptr->image, CV_16UC1, k_depth_scaling_factor_);
  cv_ptr->image.copyTo(*depth_image_);

  auto t1 = node_->now();

  // generate point cloud, update map
  processDepthImage();
  map_->inputPointCloud(point_cloud_, proj_points_cnt, camera_pos_);

  // RCLCPP_WARN(rclcpp::get_logger("racer"), "Depth and inputcloud time: %lf", (node_->now() - t1).seconds());

  if (local_updated_) {
    // t1 = node_->now();

    map_->clearAndInflateLocalMap();

    // RCLCPP_WARN(rclcpp::get_logger("racer"), "Inflate time: %lf", (node_->now() - t1).seconds());

    esdf_need_update_ = true;
    local_updated_ = false;
  }

  auto t2 = node_->now();
  fuse_time_ += (t2 - t1).seconds();
  max_fuse_time_ = max(max_fuse_time_, (t2 - t1).seconds());
  fuse_num_ += 1;
  if (show_occ_time_)
    RCLCPP_WARN(rclcpp::get_logger("racer"), "Fusion t: cur: %lf, avg: %lf, max: %lf", (t2 - t1).seconds(), fuse_time_ / fuse_num_,
        max_fuse_time_);
}

void MapROS::cloudPoseCallback(
    const sensor_msgs::msg::PointCloud2::ConstSharedPtr& msg, const geometry_msgs::msg::PoseStamped::ConstSharedPtr& pose) {
  camera_pos_(0) = pose->pose.position.x;
  camera_pos_(1) = pose->pose.position.y;
  camera_pos_(2) = pose->pose.position.z;
  camera_q_ = Eigen::Quaterniond(pose->pose.orientation.w, pose->pose.orientation.x,
      pose->pose.orientation.y, pose->pose.orientation.z);
  pcl::PointCloud<pcl::PointXYZ> cloud;
  pcl::fromROSMsg(*msg, cloud);
  int num = cloud.points.size();

  map_->inputPointCloud(cloud, num, camera_pos_);

  if (local_updated_) {
    map_->clearAndInflateLocalMap();
    esdf_need_update_ = true;
    local_updated_ = false;
  }
}

// Direct callbacks (bypass message_filters sync)
void MapROS::poseCallback(const geometry_msgs::msg::PoseStamped::ConstSharedPtr& pose) {
  std::lock_guard<std::mutex> lock(pose_mutex_);
  latest_pose_ = std::make_shared<geometry_msgs::msg::PoseStamped>(*pose);
  static int pose_count = 0;
  if (pose_count++ % 100 == 0) {
    RCLCPP_INFO(node_->get_logger(), "poseCallback #%d", pose_count);
  }
}

void MapROS::depthCallback(const sensor_msgs::msg::Image::ConstSharedPtr& img) {
  static int depth_count = 0;
  if (depth_count++ % 50 == 0) {
    RCLCPP_INFO(node_->get_logger(), "depthCallback #%d", depth_count);
  }
  
  geometry_msgs::msg::PoseStamped::SharedPtr pose;
  {
    std::lock_guard<std::mutex> lock(pose_mutex_);
    pose = latest_pose_;
  }
  
  if (!pose) {
    static int skip_count = 0;
    if (skip_count++ % 100 == 0) {
      RCLCPP_WARN(node_->get_logger(), "depthCallback: no pose yet, skipped %d frames", skip_count);
    }
    return;
  }
  
  // Use depthPoseCallback with latest pose
  depthPoseCallback(img, pose);
}

// void MapROS::basecoorCallback(const swarm_msgs::swarm_drone_basecoor::ConstSharedPtr& msg) {

//   if (msg->self_id != map_->mm_->drone_id_ && msg->self_id != map_->mm_->vis_drone_id_) return;

//   for (int i = 0; i < msg->ids.size(); ++i) {
//     auto id = msg->ids[i];
//     auto pos = msg->drone_basecoor[i];
//     auto yaw = msg->drone_baseyaw[i];
//     map_->md_->swarm_transform_[id] = Eigen::Vector4d(pos.x, pos.y, pos.z, yaw);
//   }

//   // Update global bounding box
//   if (map_->md_->swarm_transform_.find(1) == map_->md_->swarm_transform_.end()) return;

//   auto transform = map_->md_->swarm_transform_[1];
//   double yaw = transform[3];
//   map_->mp_->rot_sw_ << cos(yaw), -sin(yaw), 0, sin(yaw), cos(yaw), 0, 0, 0, 1;
//   map_->mp_->trans_sw_ = transform.head<3>();

//   // Compute vertices, box and normals of map in current drone's frame
//   Eigen::Vector3d left_bottom, right_top, left_top, right_bottom;
//   left_bottom = map_->mp_->box_mind_;
//   right_top = map_->mp_->box_maxd_;

//   left_top[0] = left_bottom[0];
//   left_top[1] = right_top[1];
//   left_top[2] = left_bottom[2];
//   right_bottom[0] = right_top[0];
//   right_bottom[1] = left_bottom[1];
//   right_bottom[2] = left_bottom[2];
//   right_top[2] = left_bottom[2];

//   map_->mp_->vertices_ = { left_bottom, right_bottom, right_top, left_top };
//   if (map_->mp_->use_swarm_tf_) {
//     for (auto& vert : map_->mp_->vertices_) vert = map_->mp_->rot_sw_ * vert +
//     map_->mp_->trans_sw_;
//   }

//   map_->mp_->vmin_ = map_->mp_->vmax_ = map_->mp_->vertices_[0];
//   for (int j = 1; j < map_->mp_->vertices_.size(); ++j) {
//     for (int k = 0; k < 2; ++k) {
//       map_->mp_->vmin_[k] = min(map_->mp_->vmin_[k], map_->mp_->vertices_[j][k]);
//       map_->mp_->vmax_[k] = max(map_->mp_->vmax_[k], map_->mp_->vertices_[j][k]);
//     }
//   }

//   map_->mp_->normals_.clear();
//   for (int j = 0; j < 4; ++j) {
//     Eigen::Vector3d dir =
//         (map_->mp_->vertices_[(j + 1) % 4] - map_->mp_->vertices_[j]).normalized();
//     map_->mp_->normals_.push_back(dir);
//   }
// }

void MapROS::processDepthImage() {
  proj_points_cnt = 0;

  uint16_t* row_ptr;
  int cols = depth_image_->cols;
  int rows = depth_image_->rows;
  double depth;
  Eigen::Matrix3d camera_r = camera_q_.toRotationMatrix();
  Eigen::Vector3d pt_cur, pt_world;
  const double inv_factor = 1.0 / k_depth_scaling_factor_;

  for (int v = depth_filter_margin_; v < rows - depth_filter_margin_; v += skip_pixel_) {
    row_ptr = depth_image_->ptr<uint16_t>(v) + depth_filter_margin_;
    for (int u = depth_filter_margin_; u < cols - depth_filter_margin_; u += skip_pixel_) {
      depth = (*row_ptr) * inv_factor;
      row_ptr = row_ptr + skip_pixel_;

      // // filter depth
      // if (depth > 0.01)
      //   depth += rand_noise_(eng_);

      // TODO: simplify the logic here
      // if (*row_ptr == 0) continue;

      if (*row_ptr == 0 || depth > depth_filter_maxdist_)
        depth = depth_filter_maxdist_;
      else if (depth < depth_filter_mindist_)
        continue;

      pt_cur(0) = (u - cx_) * depth / fx_;
      pt_cur(1) = (v - cy_) * depth / fy_;
      pt_cur(2) = depth;
      pt_world = camera_r * pt_cur + camera_pos_;
      auto& pt = point_cloud_.points[proj_points_cnt++];
      pt.x = pt_world[0];
      pt.y = pt_world[1];
      pt.z = pt_world[2];
    }
  }

  publishDepth();
}

void MapROS::publishMapAll() {
  pcl::PointXYZ pt;
  pcl::PointCloud<pcl::PointXYZ> cloud1, cloud2;

  // for (int x = map_->mp_->box_min_(0) - 20; x < map_->mp_->box_max_(0) + 20; ++x)
  //   for (int y = map_->mp_->box_min_(1) - 20; y < map_->mp_->box_max_(1) + 20; ++y)
  //     for (int z = map_->mp_->box_min_(2) /* + 1 */; z < map_->mp_->box_max_(2); ++z) {
  Eigen::Vector3i min_idx, max_idx;
  map_->posToIndex(map_->md_->all_min_, min_idx);
  map_->posToIndex(map_->md_->all_max_, max_idx);

  map_->boundIndex(min_idx);
  map_->boundIndex(max_idx);
  // for (int k = 0; k < 2; ++k) {
  //   min_idx(k) = max(min(min_idx(k), map_->mp_->box_max_(k) - 1), map_->mp_->box_min_(k));
  //   max_idx(k) = max(min(max_idx(k), map_->mp_->box_max_(k) - 1), map_->mp_->box_min_(k));
  // }

  for (int x = min_idx[0]; x <= max_idx[0]; ++x)
    for (int y = min_idx[1]; y <= max_idx[1]; ++y)
      for (int z = min_idx[2]; z <= max_idx[2]; ++z) {
        if (map_->md_->occupancy_buffer_[map_->toAddress(x, y, z)] >
            map_->mp_->min_occupancy_log_) {
          Eigen::Vector3d pos;
          map_->indexToPos(Eigen::Vector3i(x, y, z), pos);
          if (pos(2) > visualization_truncate_height_) continue;
          if (pos(2) < visualization_truncate_low_) continue;
          pt.x = pos(0);
          pt.y = pos(1);
          pt.z = pos(2);
          cloud1.push_back(pt);
        }
      }
  cloud1.width = cloud1.points.size();
  cloud1.height = 1;
  cloud1.is_dense = true;
  cloud1.header.frame_id = frame_id_;
  sensor_msgs::msg::PointCloud2 cloud_msg;
  pcl::toROSMsg(cloud1, cloud_msg);
  map_all_pub_->publish(cloud_msg);

  // // Output time and known volumn
  // double time_now = (node_->now() - map_start_time_).seconds();
  // double known_volumn = 0;

  // for (int x = map_->mp_->box_min_(0) /* + 1 */; x < map_->mp_->box_max_(0); ++x)
  //   for (int y = map_->mp_->box_min_(1) /* + 1 */; y < map_->mp_->box_max_(1); ++y)
  //     for (int z = map_->mp_->box_min_(2) /* + 1 */; z < map_->mp_->box_max_(2); ++z) {
  //       if (map_->md_->occupancy_buffer_[map_->toAddress(x, y, z)] >
  //           map_->mp_->clamp_min_log_ - 1e-3)
  //         known_volumn += 0.1 * 0.1 * 0.1;
  //     }

  // ofstream file("/home/boboyu/workspaces/plan_ws/src/fast_planner/exploration_manager/resource/"
  //               "curve1.txt",
  //     ios::app);
  // file << "time:" << time_now << ",vol:" << known_volumn << std::endl;
}

void MapROS::publishMapLocal() {
  pcl::PointXYZ pt;
  pcl::PointCloud<pcl::PointXYZ> cloud;
  pcl::PointCloud<pcl::PointXYZ> cloud2;
  Eigen::Vector3i min_cut = map_->md_->local_bound_min_;
  Eigen::Vector3i max_cut = map_->md_->local_bound_max_;
  map_->boundIndex(min_cut);
  map_->boundIndex(max_cut);

  // for (int z = min_cut(2); z <= max_cut(2); ++z)
  for (int x = min_cut(0); x <= max_cut(0); ++x)
    for (int y = min_cut(1); y <= max_cut(1); ++y)
      for (int z = map_->mp_->box_min_(2); z < map_->mp_->box_max_(2); ++z) {
        if (map_->md_->occupancy_buffer_[map_->toAddress(x, y, z)] >
            map_->mp_->min_occupancy_log_) {
          // Occupied cells
          Eigen::Vector3d pos;
          map_->indexToPos(Eigen::Vector3i(x, y, z), pos);
          if (pos(2) > visualization_truncate_height_) continue;
          if (pos(2) < visualization_truncate_low_) continue;

          pt.x = pos(0);
          pt.y = pos(1);
          pt.z = pos(2);
          cloud.push_back(pt);
        }
        // else if (map_->md_->occupancy_buffer_inflate_[map_->toAddress(x, y, z)] == 1)
        // {
        //   // Inflated occupied cells
        //   Eigen::Vector3d pos;
        //   map_->indexToPos(Eigen::Vector3i(x, y, z), pos);
        //   if (pos(2) > visualization_truncate_height_)
        //     continue;
        //   if (pos(2) < visualization_truncate_low_)
        //     continue;

        //   pt.x = pos(0);
        //   pt.y = pos(1);
        //   pt.z = pos(2);
        //   cloud2.push_back(pt);
        // }
      }

  cloud.width = cloud.points.size();
  cloud.height = 1;
  cloud.is_dense = true;
  cloud.header.frame_id = frame_id_;
  cloud2.width = cloud2.points.size();
  cloud2.height = 1;
  cloud2.is_dense = true;
  cloud2.header.frame_id = frame_id_;
  sensor_msgs::msg::PointCloud2 cloud_msg;

  pcl::toROSMsg(cloud, cloud_msg);
  map_local_pub_->publish(cloud_msg);
  pcl::toROSMsg(cloud2, cloud_msg);
  map_local_inflate_pub_->publish(cloud_msg);
}

void MapROS::publishUnknown() {
  pcl::PointXYZ pt;
  pcl::PointCloud<pcl::PointXYZ> cloud;
  Eigen::Vector3i min_idx, max_idx;
  map_->posToIndex(map_->md_->all_min_, min_idx);
  map_->posToIndex(map_->md_->all_max_, max_idx);

  map_->boundIndex(min_idx);
  map_->boundIndex(max_idx);

  for (int x = min_idx(0); x <= max_idx(0); ++x)
    for (int y = min_idx(1); y <= max_idx(1); ++y)
      for (int z = min_idx(2); z <= max_idx(2); ++z) {
        if (map_->md_->occupancy_buffer_[map_->toAddress(x, y, z)] <
            map_->mp_->clamp_min_log_ - 1e-3) {
          Eigen::Vector3d pos;
          map_->indexToPos(Eigen::Vector3i(x, y, z), pos);
          if (pos(2) > visualization_truncate_height_) continue;
          if (pos(2) < visualization_truncate_low_) continue;
          pt.x = pos(0);
          pt.y = pos(1);
          pt.z = pos(2);
          cloud.push_back(pt);
        }
      }
  cloud.width = cloud.points.size();
  cloud.height = 1;
  cloud.is_dense = true;
  cloud.header.frame_id = frame_id_;
  sensor_msgs::msg::PointCloud2 cloud_msg;
  pcl::toROSMsg(cloud, cloud_msg);
  unknown_pub_->publish(cloud_msg);
}

void MapROS::publishDepth() {
  pcl::PointXYZ pt;
  pcl::PointCloud<pcl::PointXYZ> cloud;
  for (int i = 0; i < proj_points_cnt; ++i) {
    cloud.push_back(point_cloud_.points[i]);
  }
  cloud.width = cloud.points.size();
  cloud.height = 1;
  cloud.is_dense = true;
  cloud.header.frame_id = frame_id_;
  sensor_msgs::msg::PointCloud2 cloud_msg;
  pcl::toROSMsg(cloud, cloud_msg);
  depth_pub_->publish(cloud_msg);
}

void MapROS::publishUpdateRange() {
  Eigen::Vector3d esdf_min_pos, esdf_max_pos, cube_pos, cube_scale;
  visualization_msgs::msg::Marker mk;
  map_->indexToPos(map_->md_->local_bound_min_, esdf_min_pos);
  map_->indexToPos(map_->md_->local_bound_max_, esdf_max_pos);

  cube_pos = 0.5 * (esdf_min_pos + esdf_max_pos);
  cube_scale = esdf_max_pos - esdf_min_pos;
  mk.header.frame_id = frame_id_;
  mk.header.stamp = node_->now();
  mk.type = visualization_msgs::msg::Marker::CUBE;
  mk.action = visualization_msgs::msg::Marker::ADD;
  mk.id = 0;
  mk.pose.position.x = cube_pos(0);
  mk.pose.position.y = cube_pos(1);
  mk.pose.position.z = cube_pos(2);
  mk.scale.x = cube_scale(0);
  mk.scale.y = cube_scale(1);
  mk.scale.z = cube_scale(2);
  mk.color.a = 0.3;
  mk.color.r = 1.0;
  mk.color.g = 0.0;
  mk.color.b = 0.0;
  mk.pose.orientation.w = 1.0;
  mk.pose.orientation.x = 0.0;
  mk.pose.orientation.y = 0.0;
  mk.pose.orientation.z = 0.0;

  update_range_pub_->publish(mk);
}

void MapROS::publishESDF() {
  double dist;
  pcl::PointCloud<pcl::PointXYZI> cloud;
  pcl::PointXYZI pt;

  const double min_dist = 0.0;
  const double max_dist = 3.0;

  Eigen::Vector3i min_cut =
      map_->md_->local_bound_min_ - Eigen::Vector3i(map_->mp_->local_map_margin_,
                                        map_->mp_->local_map_margin_, map_->mp_->local_map_margin_);
  Eigen::Vector3i max_cut =
      map_->md_->local_bound_max_ + Eigen::Vector3i(map_->mp_->local_map_margin_,
                                        map_->mp_->local_map_margin_, map_->mp_->local_map_margin_);
  map_->boundIndex(min_cut);
  map_->boundIndex(max_cut);

  for (int x = min_cut(0); x <= max_cut(0); ++x)
    for (int y = min_cut(1); y <= max_cut(1); ++y) {
      Eigen::Vector3d pos;
      map_->indexToPos(Eigen::Vector3i(x, y, 1), pos);
      pos(2) = esdf_slice_height_;
      dist = map_->getDistance(pos);
      dist = min(dist, max_dist);
      dist = max(dist, min_dist);
      pt.x = pos(0);
      pt.y = pos(1);
      pt.z = 0.2;
      pt.intensity = (dist - min_dist) / (max_dist - min_dist);
      cloud.push_back(pt);
    }

  cloud.width = cloud.points.size();
  cloud.height = 1;
  cloud.is_dense = true;
  cloud.header.frame_id = frame_id_;
  sensor_msgs::msg::PointCloud2 cloud_msg;
  pcl::toROSMsg(cloud, cloud_msg);

  esdf_pub_->publish(cloud_msg);

  // RCLCPP_INFO(rclcpp::get_logger("racer"), "pub esdf");
}
}  // namespace fast_planner