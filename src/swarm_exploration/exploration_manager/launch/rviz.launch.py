import os
from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    # Try to find rviz config
    rviz_config = os.path.join(
        get_package_share_directory('exploration_manager'),
        'config', 'swarm.rviz'
    )

    rviz_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=['-d', rviz_config] if os.path.exists(rviz_config) else [],
        output='screen'
    )

    return LaunchDescription([rviz_node])
