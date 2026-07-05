# Build Manual — DAP-1360 (H/W: D1) OpenWrt 14.07

## System Requirements

- **OS:** Ubuntu 16.04
- **Disk:** 10-20 GB free
- **RAM:** 2 GB minimum
- **Internet:** Required for first build (downloads toolchain)

## Install Dependencies

```bash
sudo apt-get update
sudo apt-get install build-essential libncurses5-dev zlib1g-dev gawk \
    git gettext libssl-dev xsltproc wget unzip python python3 subversion \
    mercurial rsync curl sudo ca-certificates
```

## Build Steps

```bash
cd rtk_openwrt_sdk

# 1. Initialize Realtek SDK (downloads toolchain)
./rtk_scripts/rtk_init.sh prepare
./rtk_scripts/rtk_init.sh patch

# 2. Update package feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 3. Apply DAP-1360 configuration
cp rtk_deconfig/defconfig_rtl8196c .config
make menuconfig  # Review settings, save and exit

# 4. Build firmware
make V=s -j$(nproc)
```

## Build Output

```
bin/rtkmips/
├── openwrt-rtkmips-rtl8196c-DAP1360-fw.bin    # Firmware image
├── openwrt-rtkmips-rtl8196c-rootfs.squashfs   # Root filesystem
└── openwrt-rtkmips-rtl8196c-vmlinux.bin.lzma  # Compressed kernel
```

## What Gets Built

| Component | Description |
|-----------|-------------|
| Cross-compiler | mips-rlx4181-linux toolchain |
| Linux kernel | 3.10 with RTL8196C support |
| WiFi driver | RTL8192CD as kernel module (.ko) |
| cvimg-rtl8196c | Image packaging tool |
| Root filesystem | LuCI, WiFi, PPPoE, firewall |
| Firmware | Combined kernel + rootfs image |

## Docker Alternative

The repo provides a `Dockerfile` (Ubuntu 16.04 + build deps + builder user) and `docker-setup.sh` which creates a named Docker volume for the SDK sources.

```bash
# One-time setup: build image, copy sources into volume, start container
./docker-setup.sh

# Enter the container
docker exec -it openwrt-1407-build bash

# Inside the container, run the full build sequence:
cd /build/rtk_openwrt_sdk
./rtk_scripts/rtk_init.sh prepare && ./rtk_scripts/rtk_init.sh patch
./scripts/feeds update -a && ./scripts/feeds install -a
cp rtk_deconfig/defconfig_rtl8196c .config
make menuconfig  # Review settings, save and exit
make V=s -j$(nproc)
```

**Note:** The volume is copied one-way from the host — edits on the host do not affect the container. To pick up host-side changes, re-run `docker-setup.sh`.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `rtk_init.sh prepare` fails | Check internet connection, Realtek SVN may be down |
| Build stops with config error | Run `make kernel_menuconfig`, save and exit |
| WiFi module not loading | Check `lsmod | grep 8192cd`, verify `CONFIG_PACKAGE_kmod-rtl8192cd=y` |
| Image too large | Remove packages from defconfig, rebuild |
| Boot loop after flash | Verify flash layout matches DAP-1360 (kernel at 0x30000) |
| No serial output | Check baud rate is 38400, not 115200 |
