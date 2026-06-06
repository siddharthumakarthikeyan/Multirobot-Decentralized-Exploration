# Multi-Robot Decentralized Exploration (RACER)

ROS2 Humble port of the RACER (Rapid Autonomous Collaborative Exploration using Robots) system for multi-robot decentralized exploration.

## Overview

This package implements a hierarchical planning framework for fast autonomous exploration with quadrotor swarms. It features:
- Decentralized coordination for multiple UAVs
- Frontier-based exploration with TSP/MTSP optimization
- B-spline trajectory optimization
- Real-time replanning capabilities

## System Requirements

- Ubuntu 22.04
- ROS2 Humble
- Docker (recommended for easy setup)

## Quick Start with Docker

### Build Docker Image

```bash
cd /path/to/this/repo
docker build -t multi_decent_expl .
```

### Run Simulation

**Terminal 1 - Launch Simulation:**
```bash
xhost +local:docker && docker run --rm -it -v $(pwd):/ros2_ws -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --network host multi_decent_expl bash -c "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && ros2 launch exploration_manager sim_single_drone.launch.py"
```

**Terminal 2 - Launch RViz (after simulation starts):**
```bash
docker exec -it $(docker ps -q | head -1) bash -c "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && rviz2 -d /ros2_ws/src/swarm_exploration/exploration_manager/config/swarm_ros2.rviz"
```

The exploration will auto-trigger after ~20 seconds, or trigger manually:
```bash
docker exec $(docker ps -q | head -1) bash -c "source /opt/ros/humble/setup.bash && ros2 topic pub /move_base_simple/goal geometry_msgs/msg/PoseStamped '{header: {frame_id: \"world\"}, pose: {position: {x: 0, y: 0, z: 1}}}' --once"
```

### Configuration

Map size and obstacles can be configured in:
`src/swarm_exploration/exploration_manager/launch/sim_single_drone.launch.py`

Default settings:
- Map size: 50m x 50m x 3.5m
- Obstacles: 150 cylinders + 150 circles

## Building from Source (without Docker)

### Install Dependencies

```bash
sudo apt update
sudo apt install -y \
    ros-humble-desktop \
    ros-humble-tf2-ros \
    ros-humble-tf2-geometry-msgs \
    ros-humble-cv-bridge \
    ros-humble-pcl-conversions \
    libeigen3-dev \
    libpcl-dev \
    libnlopt-dev \
    libnlopt-cxx-dev
```

### Build

```bash
cd /path/to/this/repo
source /opt/ros/humble/setup.bash
colcon build --symlink-install
```

### Run

```bash
source install/setup.bash
ros2 launch exploration_manager sim_single_drone.launch.py
```

## Package Structure

```
src/
├── swarm_exploration/          # Main exploration packages
│   ├── exploration_manager/    # High-level exploration FSM
│   ├── active_perception/      # Frontier detection & viewpoint selection
│   ├── plan_env/              # Environment representation (SDF map)
│   ├── plan_manage/           # Trajectory server
│   └── bspline_opt/           # B-spline trajectory optimization
├── uav_simulator/             # UAV simulation components
│   ├── map_generator/         # Random forest map generation
│   ├── local_sensing/         # Simulated depth camera
│   └── poscmd_2_odom/         # Position command to odometry
├── lkh_tsp_solver/            # TSP solver for tour planning
└── Utils/                     # Utility packages
```

## Key Topics

| Topic | Type | Description |
|-------|------|-------------|
| `/odom_1` | nav_msgs/Odometry | UAV odometry |
| `/map_generator/global_cloud` | sensor_msgs/PointCloud2 | Obstacle map |
| `/sdf_map/occupancy_all_1` | sensor_msgs/PointCloud2 | Explored occupancy |
| `/planning_vis/trajectory_1` | visualization_msgs/Marker | Planned trajectory |
| `/planning_vis/frontier_1` | visualization_msgs/Marker | Detected frontiers |

## Visualization in RViz

Set **Fixed Frame** to `world` and add:
- PointCloud2: `/map_generator/global_cloud` (obstacles)
- PointCloud2: `/sdf_map/occupancy_all_1` (explored map)
- Marker: `/planning_vis/trajectory_1` (trajectory)
- Marker: `/planning_vis/frontier_1` (frontiers)

## Exploration States (FSM)

```
INIT → WAIT_TRIGGER → PLAN_TRAJ → PUB_TRAJ → EXEC_TRAJ → (loop) → FINISH/IDLE
```

## Troubleshooting

### RViz shows nothing
- Ensure Fixed Frame is set to `world` (not `map`)
- Run RViz inside the same Docker container using `docker exec`

### Exploration goes to IDLE quickly
- Map boundary reached - increase `map_size_x` and `map_size_y` in launch file

### DDS discovery issues between containers
- Use `docker exec` to run tools inside the simulation container
- Or use `--network host` for all containers

## Credits

Based on [RACER](https://github.com/SYSU-STAR/RACER) by SYSU-STAR, ported to ROS2 Humble.

## License

GPL-3.0 License
