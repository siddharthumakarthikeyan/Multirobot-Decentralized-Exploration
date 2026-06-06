import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    # Arguments
    args = [
        DeclareLaunchArgument('drone_id', default_value='1'),
        DeclareLaunchArgument('drone_num', default_value='1'),
        DeclareLaunchArgument('init_x', default_value='0.0'),
        DeclareLaunchArgument('init_y', default_value='0.0'),
        DeclareLaunchArgument('init_z', default_value='1.0'),
        DeclareLaunchArgument('map_size_x', default_value='50.0'),
        DeclareLaunchArgument('map_size_y', default_value='50.0'),
        DeclareLaunchArgument('map_size_z', default_value='3.5'),
    ]

    # Map generator - creates random forest obstacle map
    map_generator_node = Node(
        package='map_generator',
        executable='random_forest',
        name='random_forest',
        output='screen',
        parameters=[{
            'map.resolution': 0.1,
            'map.x_size': LaunchConfiguration('map_size_x'),
            'map.y_size': LaunchConfiguration('map_size_y'),
            'map.z_size': LaunchConfiguration('map_size_z'),
            'map.obs_num': 150,
            'map.circle_num': 150,
            'map.fix_ratio': 0.0,
            'obstacle.lower_rad': 0.3,
            'obstacle.upper_rad': 0.8,
            'obstacle.lower_hei': 1.0,
            'obstacle.upper_hei': 3.5,
            'obstacle.set_height_z': 0.5,
            'sensing.rate': 10.0,
        }]
    )

    # Position command to odometry (simulator)
    poscmd_2_odom_node = Node(
        package='poscmd_2_odom',
        executable='poscmd_2_odom',
        name='poscmd_2_odom',
        output='screen',
        parameters=[{
            'drone_id': LaunchConfiguration('drone_id'),
            'init_x': LaunchConfiguration('init_x'),
            'init_y': LaunchConfiguration('init_y'),
            'init_z': LaunchConfiguration('init_z'),
        }],
        remappings=[
            ('command', ['/planning/pos_cmd_', LaunchConfiguration('drone_id')]),
            ('odometry', ['/odom_', LaunchConfiguration('drone_id')]),
        ]
    )

    # Odometry visualization
    odom_vis_node = Node(
        package='odom_visualization',
        executable='odom_visualization',
        name='odom_visualization',
        output='screen',
        parameters=[{
            'drone_id': LaunchConfiguration('drone_id'),
            'drone_num': LaunchConfiguration('drone_num'),
            'color.a': 1.0,
            'color.r': 0.0,
            'color.g': 0.0,
            'color.b': 1.0,
            'robot_scale': 1.0,
        }],
        remappings=[
            ('odom', ['/odom_', LaunchConfiguration('drone_id')]),
        ]
    )

    # Local sensing - simulated depth camera
    pcl_render_node = Node(
        package='local_sensing',
        executable='pcl_render_node',
        name='pcl_render_node',
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
            ('odometry', ['/odom_', LaunchConfiguration('drone_id')]),
            ('depth', ['/pcl_render_node/depth_', LaunchConfiguration('drone_id')]),
            ('sensor_pose', ['/pcl_render_node/sensor_pose_', LaunchConfiguration('drone_id')]),
        ]
    )

    # Include exploration planner
    exploration_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(
                get_package_share_directory('exploration_manager'),
                'launch',
                'single_drone_exploration.launch.py'
            )
        ),
        launch_arguments={
            'drone_id': LaunchConfiguration('drone_id'),
            'drone_num': LaunchConfiguration('drone_num'),
            'init_x': LaunchConfiguration('init_x'),
            'init_y': LaunchConfiguration('init_y'),
            'init_z': LaunchConfiguration('init_z'),
            'map_size_x': LaunchConfiguration('map_size_x'),
            'map_size_y': LaunchConfiguration('map_size_y'),
            'map_size_z': LaunchConfiguration('map_size_z'),
            'odom_prefix': '/odom',
            'simulation': 'true',
        }.items()
    )

    return LaunchDescription(args + [
        map_generator_node,
        poscmd_2_odom_node,
        # odom_vis_node,  # Disabled
        pcl_render_node,
        exploration_launch,
    ])
