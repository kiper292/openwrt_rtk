#
# Copyright (C) 2006-2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/DAP1360
  NAME:=D-Link DAP-1360 (H/W: D1)
  PACKAGES:=wpad-mini kmod-cfg80211 kmod-mac80211 luci luci-base \
    luci-theme-bootstrap luci-app-firewall luci-proto-ppp \
    ppp ppp-mod-pppoe dropbear
endef

define Profile/DAP1360/Description
	Package for D-Link DAP-1360 H/W revision D1 (RTL8196C, 4MB flash, 32MB RAM)
	Includes: WiFi, minimal LuCI, PPPoE
endef

$(eval $(call Profile,DAP1360))
