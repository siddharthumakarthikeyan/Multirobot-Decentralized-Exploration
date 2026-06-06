import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    args = [
        DeclareLaunchArgument('drone_id', default_value='1'),
        DeclareLaunchArgument('drone_num', default_value='1'),
        DeclareLaunchArgument('init_x', default_value='0.0'),
        DeclareLaunchArgument('init_y', default_value='0.0'),
        DeclareLaunchArgument('init_z', default_value='1.0'),
        DeclareLaunchArgument('map_size_x', default_value='35.0'),
        DeclareLaunchArgument('map_size_y', default_value='35.0'),
        DeclareLaunchArgument('map_size_z', default_value='3.5'),
        DeclareLaunchArgument('odometry_topic', default_value='odom_1'),
    ]

    # Position command to odometry converter (lightweight simulator)
    poscmd_2_odom_node = Node(
        package='poscmd_2_odom',
        executable='poscmd_2_odom',
        name=['poscmd_2_odom_', LaunchConfiguration('drone_id')],
        output='screen',
        parameters=[{
            'drone_id': LaunchConfiguration('drone_id'),
            'init_x': LaunchConfiguration('init_x'),
            'init_y': LaunchConfiguration('init_y'),
            'init_z': LaunchConfiguration('init_z'),
        }],
        remappings=[
            ('command', ['/planning/pos_cmd_', LaunchConfiguration('drone_id')]),
            ('odometry', ['/', LaunchConfiguration('odometry_topic')]),
        ]
    )

    # Odometry visualization
    odom_vis_node = Node(
        package='odom_visualization',
        executable='odom_visualization',
        name=['odom_visualization_', LaunchConfiguration('drone_id')],
        output='screen',
        parameters=[{
            'drone_id': LaunchConfiguration('drone_id'),
            'drone_num': LaunchConfiguration('drone_num'),
            'color.a': 1.0,
            'color.r': 0.0,
            'color.g': 0.0,
            'color.b': 1.0,
            'covariance_scale': 100.0,
            'robot_scale': 1.0,
        }],
        remappings=[
            ('odom', ['/', LaunchConfiguration('odometry_topic')]),
        ]
    )

    # Point cloud render node (local sensing)
    pcl_render_node = Node(
        package='local_sensing',
        executable='pcl_render_node',
        name=['pcl_render_node_', LaunchConfiguration('drone_id')],
        output='screen',
        parameters=[{
            'sensing_horizon': 5.0,
            'sensing_rate': 10.0,
            'estimation_rate': 10.0,
            'map.x_size': LaunchConfiguration('map_size_x'),
            'map.y_size': LaunchConfiguration('map_size_y'),
            'map.z_size': LaunchConfiguration('map_size_z'),
            'map.init_x': LaunchConfiguration('init_x'),
            'map.init_y': LaunchConfiguration('init_y'),
            'map.drone_id': LaunchConfiguration('drone_id'),
        }],
        remappings=[
            ('global_map', '/map_generator/global_cloud'),
            ('odometry', ['/', LaunchConfiguration('odometry_topic')]),
            ('depth', ['/pcl_render_node/depth_', LaunchConfiguration('drone_id')]),
            ('sensor_pose', ['/pcl_render_node/sensor_pose_', LaunchConfiguration('drone_id')]),
        ]
    )

    return LaunchDescription(args + [
        poscmd_2_odom_node,
        # odom_vis_node,  # Disabled - not needed for basic simulation
        pcl_render_node,
    ])
