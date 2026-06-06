import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    # Declare arguments
    map_size_x = DeclareLaunchArgument('map_size_x', default_value='35.0')
    map_size_y = DeclareLaunchArgument('map_size_y', default_value='35.0')
    map_size_z = DeclareLaunchArgument('map_size_z', default_value='3.5')
    odom_prefix = DeclareLaunchArgument('odom_prefix', default_value='/state_ukf/odom')
    drone_num = DeclareLaunchArgument('drone_num', default_value='5')

    # Map generator node
    map_generator_share = get_package_share_directory('map_generator')
    map_pub_node = Node(
        package='map_generator',
        executable='map_pub',
        name='map_pub',
        output='screen',
        arguments=[os.path.join(map_generator_share, 'resource', 'pillar.pcd')]
    )

    # Include single drone exploration for each drone
    drone_launches = []
    drone_configs = [
        {'id': '1', 'x': '0',  'y': '0',  'z': '1'},
        {'id': '2', 'x': '0',  'y': '-1', 'z': '1'},
        {'id': '3', 'x': '1',  'y': '-1', 'z': '1'},
        {'id': '4', 'x': '1',  'y': '0',  'z': '1'},
        {'id': '5', 'x': '-1', 'y': '0',  'z': '1'},
    ]

    for cfg in drone_configs:
        drone_launch = IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(
                    get_package_share_directory('exploration_manager'),
                    'launch',
                    'single_drone_exploration.launch.py'
                )
            ),
            launch_arguments={
                'drone_id': cfg['id'],
                'init_x': cfg['x'],
                'init_y': cfg['y'],
                'init_z': cfg['z'],
                'map_size_x': LaunchConfiguration('map_size_x'),
                'map_size_y': LaunchConfiguration('map_size_y'),
                'map_size_z': LaunchConfiguration('map_size_z'),
                'odom_prefix': LaunchConfiguration('odom_prefix'),
                'drone_num': LaunchConfiguration('drone_num'),
                'simulation': 'true',
            }.items()
        )
        drone_launches.append(drone_launch)

    return LaunchDescription([
        map_size_x,
        map_size_y,
        map_size_z,
        odom_prefix,
        drone_num,
        map_pub_node,
    ] + drone_launches)
