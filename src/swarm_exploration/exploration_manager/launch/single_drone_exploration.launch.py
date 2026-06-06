import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PythonExpression
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    # Declare arguments
    drone_id = DeclareLaunchArgument('drone_id', default_value='1')
    drone_num = DeclareLaunchArgument('drone_num', default_value='1')
    init_x = DeclareLaunchArgument('init_x', default_value='0')
    init_y = DeclareLaunchArgument('init_y', default_value='0')
    init_z = DeclareLaunchArgument('init_z', default_value='0')
    map_size_x = DeclareLaunchArgument('map_size_x', default_value='22')
    map_size_y = DeclareLaunchArgument('map_size_y', default_value='22')
    map_size_z = DeclareLaunchArgument('map_size_z', default_value='3.5')
    odom_prefix = DeclareLaunchArgument('odom_prefix', default_value='odom')
    simulation = DeclareLaunchArgument('simulation', default_value='false')
    cx = DeclareLaunchArgument('cx', default_value='324.0879821777344')
    cy = DeclareLaunchArgument('cy', default_value='239.10362243652344')
    fx = DeclareLaunchArgument('fx', default_value='385.69793701171875')
    fy = DeclareLaunchArgument('fy', default_value='385.69793701171875')
    max_vel = DeclareLaunchArgument('max_vel', default_value='1.5')
    max_acc = DeclareLaunchArgument('max_acc', default_value='1.0')

    # Include single_drone_planner
    planner_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(
                get_package_share_directory('exploration_manager'),
                'launch',
                'single_drone_planner.launch.py'
            )
        ),
        launch_arguments={
            'drone_id': LaunchConfiguration('drone_id'),
            'drone_num': LaunchConfiguration('drone_num'),
            'map_size_x': LaunchConfiguration('map_size_x'),
            'map_size_y': LaunchConfiguration('map_size_y'),
            'map_size_z': LaunchConfiguration('map_size_z'),
            'odom_prefix': LaunchConfiguration('odom_prefix'),
            'cx': LaunchConfiguration('cx'),
            'cy': LaunchConfiguration('cy'),
            'fx': LaunchConfiguration('fx'),
            'fy': LaunchConfiguration('fy'),
            'max_vel': LaunchConfiguration('max_vel'),
            'max_acc': LaunchConfiguration('max_acc'),
            'simulation': LaunchConfiguration('simulation'),
        }.items()
    )

    # Trajectory server node
    traj_server_node = Node(
        package='plan_manage',
        executable='traj_server',
        name=['traj_server_', LaunchConfiguration('drone_id')],
        output='screen',
        remappings=[
            ('/odom_world', [LaunchConfiguration('odom_prefix'), '_', LaunchConfiguration('drone_id')]),
            ('/planning/bspline', ['/planning/bspline_', LaunchConfiguration('drone_id')]),
            ('/planning/replan', ['/planning/replan_', LaunchConfiguration('drone_id')]),
            ('/planning/new', ['/planning/new_', LaunchConfiguration('drone_id')]),
            ('/position_cmd', ['planning/pos_cmd_', LaunchConfiguration('drone_id')]),
            ('planning/position_cmd_vis', ['planning/position_cmd_vis_', LaunchConfiguration('drone_id')]),
            ('planning/travel_traj', ['planning/travel_traj_', LaunchConfiguration('drone_id')]),
        ],
        parameters=[{
            'traj_server.time_forward': 1.5,
            'traj_server.pub_traj_id': 4,
            'traj_server.drone_id': LaunchConfiguration('drone_id'),
            'traj_server.drone_num': LaunchConfiguration('drone_num'),
            'perception_utils.top_angle': 0.56125,
            'perception_utils.left_angle': 0.69222,
            'perception_utils.right_angle': 0.68901,
            'perception_utils.max_dist': 4.5,
            'perception_utils.vis_dist': 1.0,
        }]
    )

    return LaunchDescription([
        drone_id, drone_num, init_x, init_y, init_z,
        map_size_x, map_size_y, map_size_z,
        odom_prefix, simulation, cx, cy, fx, fy, max_vel, max_acc,
        planner_launch,
        traj_server_node,
    ])
