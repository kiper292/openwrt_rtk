#!/bin/bash
# Docker setup script for OpenWrt 14.07 build environment

set -e

IMAGE_NAME="openwrt-1407-builder"
CONTAINER_NAME="openwrt-1407-build"
VOLUME_NAME="openwrt-1407-sources"
SOURCE_DIR="$(pwd)"

echo "=== OpenWrt 14.07 Docker Build Environment Setup ==="

# Step 1: Build Docker image
echo ""
echo "[1/4] Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Step 2: Copy sources to volume (if not already there)
echo ""
echo "[2/4] Copying sources to Docker volume..."
docker run --rm \
    -v "$VOLUME_NAME":/build \
    -v "$SOURCE_DIR":/source:ro \
    ubuntu:14.04 \
    bash -c "cp -a /source/rtk_openwrt_sdk /build/ 2>/dev/null || true"

# Step 3: Remove old container if exists
echo ""
echo "[3/4] Cleaning up old container..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Step 4: Create new container
echo ""
echo "[4/4] Creating build container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -v "$VOLUME_NAME":/build \
    -w /build/rtk_openwrt_sdk \
    "$IMAGE_NAME" \
    sleep infinity

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
echo "  docker exec -it $CONTAINER_NAME bash -c './rtk_scripts/rtk_init.sh prepare && ./rtk_scripts/rtk_init.sh patch && ./scripts/feeds update -a && ./scripts/feeds install -a && cp rtk_deconfig/defconfig_rtl8196c .config && make menuconfig && make V=s -j\$(nproc)'"
