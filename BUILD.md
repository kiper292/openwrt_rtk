# Build Manual — DAP-1360 OpenWrt 14.07

## System Requirements

- **OS:** Ubuntu 14.04 (native or Docker)
- **Disk:** 10-20 GB free
- **RAM:** 2 GB minimum
- **Internet:** Required for first build (downloads toolchain)

## Install Dependencies (Ubuntu 14.04)

```bash
sudo apt-get update
sudo apt-get install build-essential libncurses5-dev zlib1g-dev gawk \
    git gettext libssl-dev xsltproc wget unzip python2 subversion \
    mercurial rsync
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
| Linux kernel | 3.10.49 with RTL8196C support |
| WiFi driver | RTL8192CD as kernel module (.ko) |
| cvimg-rtl8196c | Image packaging tool |
| Root filesystem | LuCI, WiFi, PPPoE, firewall |
| Firmware | Combined kernel + rootfs image |

## Docker Alternative (Modern Hosts)

Ubuntu 14.04 is EOL. Use Docker to avoid glibc/m4 incompatibilities:

```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:14.04
RUN apt-get update && apt-get install -y \
    build-essential libncurses5-dev zlib1g-dev gawk \
    git gettext libssl-dev xsltproc wget unzip python2 \
    subversion mercurial rsync
WORKDIR /build
EOF

# Build and run
docker build -t openwrt-14.07 .
docker run -it -v $(pwd):/build openwrt-14.07 bash
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `rtk_init.sh prepare` fails | Check internet connection, Realtek SVN may be down |
| Build stops with config error | Run `make kernel_menuconfig`, save and exit |
| WiFi module not loading | Check `lsmod \| grep 8192cd`, verify `CONFIG_RTL8192CD=m` |
| Image too large | Remove packages from defconfig, rebuild |
| Boot loop after flash | Verify flash layout matches DAP-1360 (kernel at 0x30000) |
| No serial output | Check baud rate is 38400, not 115200 |
