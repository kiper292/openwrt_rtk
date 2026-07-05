#!/bin/bash
# Docker setup script for OpenWrt 14.07 build environment

set -e

IMAGE_NAME="openwrt-1407-builder"
CONTAINER_NAME="openwrt-1407-build"
VOLUME_NAME="openwrt-1407-sources"
SOURCE_DIR="$(pwd)"

# Handle --clean flag
if [ "$1" = "--clean" ]; then
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    docker volume rm "$VOLUME_NAME" 2>/dev/null || true
    echo "Done. Container and volume removed."
    exit 0
fi

echo "=== OpenWrt 14.07 Docker Build Environment Setup ==="

# Step 1: Build Docker image
echo ""
echo "[1/4] Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Step 2: Remove old container if exists
echo ""
echo "[2/4] Cleaning up old container..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Step 3: Create new container with volume
echo ""
echo "[3/4] Creating build container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -v "$VOLUME_NAME":/build \
    "$IMAGE_NAME" \
    sleep infinity

# Step 4: Copy sources into container
echo ""
echo "[4/4] Copying sources to container..."
docker cp "$SOURCE_DIR/rtk_openwrt_sdk" "$CONTAINER_NAME":/build/

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Container: $CONTAINER_NAME"
echo "Volume:    $VOLUME_NAME"
echo "Workspace: /build/rtk_openwrt_sdk"
echo ""
echo "To enter the container:"
echo "  docker exec -it $CONTAINER_NAME bash"
echo ""
echo "To start the build:"
echo "  docker exec -it $CONTAINER_NAME bash -c 'cd /build/rtk_openwrt_sdk && ./rtk_scripts/rtk_init.sh prepare && ./rtk_scripts/rtk_init.sh patch && ./scripts/feeds update -a && ./scripts/feeds install -a && cp rtk_deconfig/defconfig_rtl8196c .config && make menuconfig && make V=s -j\$(nproc)'"
echo ""
echo "To clean up (remove container and volume):"
echo "  ./docker-setup.sh --clean"
