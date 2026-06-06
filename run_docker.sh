#!/bin/bash
# run_docker.sh - Build and launch the RACER ROS2 Humble development container
set -e

IMAGE_NAME="racer_ros2_humble"
CONTAINER_NAME="racer_ros2_dev"
WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================================="
echo "       RACER ROS2 Humble Development Environment"
echo "=========================================================="

# 1. Build image if needed
build_image() {
    echo "[*] Building Docker image '${IMAGE_NAME}'..."
    docker build -t ${IMAGE_NAME} -f "${WORKSPACE_DIR}/Dockerfile" "${WORKSPACE_DIR}"
    echo "[+] Image built successfully."
}

if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" == "" ]]; then
    build_image
else
    if [[ "$1" == "--rebuild" ]]; then
        build_image
    else
        echo "[*] Found existing image '${IMAGE_NAME}'. Use './run_docker.sh --rebuild' to force rebuild."
    fi
fi

# 2. X11 Display Forwarding
echo "[*] Setting up X11 display forwarding..."
xhost +local:root > /dev/null 2>&1 || xhost + > /dev/null 2>&1 || echo "[!] Warning: xhost failed"

# 3. GPU Check
GPU_FLAGS=""
if command -v nvidia-smi &> /dev/null && command -v nvidia-container-cli &> /dev/null; then
    echo "[+] NVIDIA GPU detected. Enabling GPU acceleration..."
    GPU_FLAGS="--gpus all"
else
    echo "[*] No NVIDIA GPU detected. Using CPU rendering."
fi

# 4. Remove old container
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "[*] Removing existing container '${CONTAINER_NAME}'..."
    docker rm -f ${CONTAINER_NAME} > /dev/null
fi

# 5. Run container
echo "[*] Launching container '${CONTAINER_NAME}'..."
echo "[*] Mounting: ${WORKSPACE_DIR}/src -> /ros2_ws/src"
echo "----------------------------------------------------------"

docker run -it \
    ${GPU_FLAGS} \
    --net=host \
    --ipc=host \
    --privileged \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v ${WORKSPACE_DIR}/src:/ros2_ws/src \
    --name ${CONTAINER_NAME} \
    ${IMAGE_NAME}
