#!/usr/bin/env python3
"""Simple visualization script for RACER exploration."""

import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy
from sensor_msgs.msg import PointCloud2
from nav_msgs.msg import Odometry
from visualization_msgs.msg import Marker
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import struct

class ExplorationVisualizer(Node):
    def __init__(self):
        super().__init__('exploration_visualizer')
        
        qos = QoSProfile(depth=10, reliability=ReliabilityPolicy.RELIABLE)
        
        self.map_points = None
        self.drone_pos = None
        self.trajectory = []
        
        # Subscribers
        self.create_subscription(
            PointCloud2, '/map_generator/global_cloud', 
            self.map_callback, qos)
        self.create_subscription(
            Odometry, '/odom_1', 
            self.odom_callback, qos)
        
        # Setup plot
        plt.ion()
        self.fig = plt.figure(figsize=(12, 8))
        self.ax = self.fig.add_subplot(111, projection='3d')
        self.ax.set_xlabel('X')
        self.ax.set_ylabel('Y')
        self.ax.set_zlabel('Z')
        self.ax.set_title('RACER Exploration Visualization')
        
        # Timer for plot update
        self.create_timer(0.5, self.update_plot)
        
        self.get_logger().info('Visualization started. Waiting for data...')

    def pointcloud2_to_xyz(self, msg):
        """Extract XYZ from PointCloud2."""
        points = []
        point_step = msg.point_step
        data = msg.data
        
        for i in range(0, len(data), point_step):
            if i + 12 <= len(data):
                x, y, z = struct.unpack('fff', bytes(data[i:i+12]))
                if not (np.isnan(x) or np.isnan(y) or np.isnan(z)):
                    points.append([x, y, z])
        
        return np.array(points) if points else None

    def map_callback(self, msg):
        self.map_points = self.pointcloud2_to_xyz(msg)
        if self.map_points is not None:
            self.get_logger().info(f'Map: {len(self.map_points)} points, frame: {msg.header.frame_id}')

    def odom_callback(self, msg):
        pos = msg.pose.pose.position
        self.drone_pos = [pos.x, pos.y, pos.z]
        self.trajectory.append(self.drone_pos.copy())
        # Keep last 1000 points
        if len(self.trajectory) > 1000:
            self.trajectory = self.trajectory[-1000:]

    def update_plot(self):
        self.ax.clear()
        self.ax.set_xlabel('X')
        self.ax.set_ylabel('Y')
        self.ax.set_zlabel('Z')
        self.ax.set_title('RACER Exploration')
        
        # Plot map (subsample for performance)
        if self.map_points is not None and len(self.map_points) > 0:
            step = max(1, len(self.map_points) // 5000)
            pts = self.map_points[::step]
            self.ax.scatter(pts[:, 0], pts[:, 1], pts[:, 2], 
                          c='gray', s=1, alpha=0.5, label='Map')
        
        # Plot trajectory
        if len(self.trajectory) > 1:
            traj = np.array(self.trajectory)
            self.ax.plot(traj[:, 0], traj[:, 1], traj[:, 2], 
                        'b-', linewidth=2, label='Trajectory')
        
        # Plot drone position
        if self.drone_pos:
            self.ax.scatter(*self.drone_pos, c='red', s=100, 
                          marker='^', label='Drone')
        
        self.ax.legend()
        self.ax.set_box_aspect([1, 1, 0.3])
        plt.draw()
        plt.pause(0.01)


def main():
    rclpy.init()
    node = ExplorationVisualizer()
    
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        plt.close('all')
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
