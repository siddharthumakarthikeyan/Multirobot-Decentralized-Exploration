FROM osrf/ros:humble-desktop

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libarmadillo-dev \
    libeigen3-dev \
    libpcl-dev \
    libopencv-dev \
    ros-humble-cv-bridge \
    ros-humble-pcl-conversions \
    ros-humble-pcl-ros \
    ros-humble-tf2-ros \
    ros-humble-tf2-geometry-msgs \
    ros-humble-message-filters \
    ros-humble-rviz-common \
    ros-humble-rviz-default-plugins \
    ros-humble-rviz-rendering \
    ros-humble-pluginlib \
    ros-humble-ament-cmake \
    ros-humble-rosidl-default-generators \
    ros-humble-rosidl-default-runtime \
    ros-humble-ament-index-cpp \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install nlopt v2.7.1
RUN cd /tmp && \
    git clone -b v2.7.1 https://github.com/stevengj/nlopt.git && \
    cd nlopt && mkdir build && cd build && \
    cmake .. && make -j$(nproc) && make install && \
    ldconfig && \
    rm -rf /tmp/nlopt

# Install LKH-3 (needs -fcommon for GCC 10+ compatibility)
RUN cd /tmp && \
    wget http://akira.ruc.dk/~keld/research/LKH-3/LKH-3.0.6.tgz && \
    tar xvfz LKH-3.0.6.tgz && \
    cd LKH-3.0.6 && \
    sed -i 's/CFLAGS = -O3/CFLAGS = -O3 -fcommon/' SRC/Makefile && \
    make && \
    cp LKH /usr/local/bin && \
    rm -rf /tmp/LKH-3.0.6*

# Create workspace
RUN mkdir -p /ros2_ws/src

WORKDIR /ros2_ws

# Source ROS 2 in bashrc
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /ros2_ws/install/setup.bash 2>/dev/null || true" >> ~/.bashrc

CMD ["/bin/bash"]
