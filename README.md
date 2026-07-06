# OpenWrt 14.07 for D-Link DAP-1360 (H/W: D1, RTL8196C)

Custom OpenWrt build for D-Link DAP-1360 router based on Realtek RTL8196C SoC. Forked from cgoder/openwrt_rtk SDK with added RTL8196C subtarget support.

## Hardware Specifications

| Component | Specification |
|-----------|---------------|
| SoC | Realtek RTL8196C (RLX4181, single-core, 389 BogoMIPS) |
| CPU | MIPS-1 ISA, MIPS16 ISA, no FPU |
| RAM | 32 MB (soldered) |
| Flash | 4 MB SPI NOR (Winbond) |
| WiFi | RTL8192CD (2.4 GHz 802.11n, 2x2 MIMO) |
| Ethernet | RTL8196C integrated 5-port 10/100 switch (2 ports on board) |
| Bootloader | RTL-Boot (NOT U-Boot) |
| Serial | 38400 baud (NOT 115200) |

## Flash Layout

```
Offset      Size      Description
0x000000    64 KB     Bootloader (RTL-Boot, read-only)
0x010000    64 KB     MAC address storage, HW settings (0x6000)
0x020000    64 KB     NVRAM configuration, bootinfo (0xC000)
0x030000    1 MB      Linux kernel
0x130000    2.8 MB    SquashFS root filesystem
```

## Prerequisites

### Linux Build Environment

OpenWrt requires a case-sensitive filesystem. Use Linux or WSL2.

```bash
# Ubuntu/Debian dependencies
sudo apt-get update
sudo apt-get install build-essential libncurses5-dev zlib1g-dev gawk \
    git gettext libssl-dev xsltproc wget unzip python \
    subversion mercurial rsync

# Verify case sensitivity
touch Test && ls test  # Should fail on case-sensitive FS
rm Test
```

### Disk Space

- Minimum: 10 GB free
- Recommended: 20 GB free (toolchain + build artifacts)

## Build Instructions

### 1. Clone Repository

```bash
cd /path/to/work
git clone https://github.com/kiper292/openwrt_rtk.git
cd openwrt_rtk/rtk_openwrt_sdk
```

### 2. Initialize Realtek SDK

```bash
# Download toolchain and patch SDK
./rtk_scripts/rtk_init.sh prepare
./rtk_scripts/rtk_init.sh patch
```

**Note:** The `prepare` command downloads the Realtek toolchain from the GitHub releases of this repository.

### 3. Update Feeds

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### 4. Configure for DAP-1360

```bash
# Option A: Use defconfig (recommended)
cp rtk_deconfig/defconfig_rtl8196c .config
make menuconfig  # Review and save

# Option B: Manual configuration
make menuconfig
# Target System → Realtek mips SOC
# Subtarget → rtl8196c
# Target Profile → D-Link DAP-1360
# Target Images → squashfs
```

### 5. Build

```bash
# Full build
make V=s -j$(nproc)

# Single-threaded (for debugging)
make V=s -j1
```

**Build time:** 30-120 minutes depending on hardware.

### 6. Output

```
bin/rtkmips/
└── openwrt-rtkmips-rtl8196c-DAP1360-fw.bin    # Firmware image (kernel + rootfs)
```

## Flashing

### Method 1: Web Interface (if accessible)

1. Connect to DAP-1360 via Ethernet (192.168.0.50)
2. Open web interface (http://192.168.0.50)
3. Navigate to Firmware Update
4. Upload the `-fw.bin` file
5. Wait for reboot

### Method 2: TFTP (if web interface broken)

```bash
# Set up TFTP server
sudo apt-get install tftpd-hpa
sudo cp bin/rtkmips/openwrt-rtkmips-rtl8196c-DAP1360-fw.bin /srv/tftp/
sudo systemctl restart tftpd-hpa

# On router (via telnet/serial)
tftp -g -l /tmp/firmware.bin <TFTP_SERVER_IP>
mtd write /tmp/firmware.bin linux
reboot
```

### Method 3: Serial Console (if bricked)

Requires soldering serial header (3.3V TTL, 38400 baud):

```
Pin 1: VCC (3.3V) — do NOT connect
Pin 2: GND
Pin 3: TX (connect to USB-TX)
Pin 4: RX (connect to USB-RX)
```

## Default Credentials

| Service | IP | Username | Password |
|---------|-----|----------|----------|
| Web/SSH | 192.168.0.50 | admin | admin |
| WiFi SSID | — | DAP-1360-OpenWrt | — |

## Configuration Details

### Kernel Config (rtl8196c/config-3.10)

Key settings for RTL8196C:

```
# SoC selection
CONFIG_SOC_RTL8196C=y

# CPU (single-core RLX4181)
# CONFIG_SMP is not set
CONFIG_NR_CPUS=1
# CONFIG_CPU_MIPS32_R2 is not set
# CONFIG_CPU_R4K_FPU is not set

# USB (2.0 only)
CONFIG_USB_EHCI_HCD=y
CONFIG_USB_OHCI_HCD=y
# CONFIG_USB_XHCI_HCD is not set

# WiFi
CONFIG_RTL8192CD=m
CONFIG_SLOT_0_92C=y
CONFIG_SLOT_1_92C=y
CONFIG_BAND_2G_ON_WLAN0=y

# Flash
CONFIG_RTL819X_SPI_FLASH=y
CONFIG_RD_LZMA=y
```

### Package Selection (defconfig_rtl8196c)

Minimal build for 4MB flash:

**Included:**
- base-files, busybox, dropbear, firewall, iptables
- netifd, opkg, uci, procd, ubus, dnsmasq
- kmod-ipt-core, kmod-ipt-conntrack, kmod-ipt-nat, kmod-ipt-nathelper
- kmod-cfg80211, kmod-mac80211, kmod-rtl8192cd, wpad
- luci, luci-base, luci-theme-bootstrap, uhttpd
- luci-app-firewall, luci-proto-ppp
- ppp, ppp-mod-pppoe

**Excluded (to save flash/RAM):**
- IPv6 packages (kmod-ip6tables, odhcp6c, odhcpd)
- mtd, uboot-envtools (not needed at runtime)
- luci-i18n-* (translations)
- luci-app-* (extra apps except firewall)

### Space Budget

| Component | Size |
|-----------|------|
| Boot/MAC/config | 192 KB |
| Kernel | ~1,000 KB |
| Rootfs | ~2,345 KB |
| **Total** | **~3,537 KB** |
| **Remaining** | **~559 KB** |

## Project Structure

```
openwrt-14.07-dap1360/
├── README.md                        # This file
├── BUILD.md                         # Quick build reference
├── Dockerfile                       # Docker build environment
├── docker-setup.sh                  # Docker container setup script
└── rtk_openwrt_sdk/
    ├── rtk_deconfig/
    │   └── defconfig_rtl8196c          # DAP-1360 defconfig
    ├── target/linux/rtkmips/
    │   ├── Makefile                     # SUBTARGETS includes rtl8196c
    │   ├── rtl8196c/                    # RTL8196C subtarget
    │   │   ├── target.mk               # CPU_TYPE:=mips32
    │   │   ├── config-3.10             # Kernel config
    │   │   ├── kconfig/
    │   │   │   └── 96C-config-3.10     # Menuconfig variant
    │   │   └── profiles/
    │   │       ├── 120-AP.mk           # Generic AP profile
    │   │       └── 130-DAP1360.mk      # DAP-1360 profile
    │   ├── rtl8198c/                    # RTL8198C subtarget (reference)
    │   ├── image/
    │   │   ├── Makefile                 # Image build rules
    │   │   └── lzma-loader/            # Boot decompressor
    │   ├── files/
    │   │   ├── drivers/net/wireless/rtl8192cd/  # WiFi driver
    │   │   ├── drivers/net/rtl819x/    # Ethernet/switch driver
    │   │   ├── drivers/mtd/maps/       # Flash mapping
    │   │   └── arch/mips/realtek/      # Board support
    │       └── patches-3.10/               # Kernel patches (36 total)
    └── tools/rtk-tools/                 # cvimg-rtl8196c image tool
```

## Differences from RTL8198C

| Feature | RTL8196C (DAP-1360) | RTL8198C (reference) |
|---------|---------------------|----------------------|
| CPU cores | 1 (RLX4181) | 2 (MIPS32r2 24Kc) |
| SMP | Disabled | Enabled |
| USB | EHCI/OHCI (2.0) | XHCI (3.0) |
| WiFi bands | 2.4 GHz only | 2.4 + 5 GHz |
| Kernel offset | 0x30000 | 0x60000 |
| HW settings | 0x20000 | 0x20000 |
| I-cache | 16 KB | 64 KB |
| D-cache | 8 KB | 32 KB |

## Known Issues

1. **WiFi driver integration** — RTL8192CD compiles as module, may need manual loading
2. **Serial baud rate** — 38400, not 115200 like most routers
3. **RTL-Boot** — Cannot use U-Boot commands, different flash protocol
4. **cvimg tool** — Must be built with `-DCONFIG_RTL_8196C` (handled by SDK)

## Recovery

If device is bricked:

1. **Soft brick (web accessible):** Flash stock firmware via web interface
2. **Hard brick (no access):** Use serial console + TFTP
3. **Complete brick:** Use JTAG or flash chip programmer

### Stock Firmware

Download from [GitHub Releases](https://github.com/kiper292/openwrt_rtk/releases): `2017.10.13-15.40_DAP_1360D1_3.0.0_release.bin` (3.12 MB)

**Note:** This firmware is for hardware revision D1 only.

## References

- [OpenWrt 14.07 Documentation](https://openwrt.org/docs/start)
- [cgoder/openwrt_rtk](https://github.com/cgoder/openwrt_rtk)

## License

OpenWrt is licensed under GPL v2. Realtek SDK components are subject to their own licenses.
