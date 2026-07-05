/*
 * Wrapper for bsp/bspchip.h — resolves to the correct SoC header.
 */
#ifndef __BSP_BSPCHIP_H
#define __BSP_BSPCHIP_H

#if defined(CONFIG_SOC_RTL8198C) || defined(CONFIG_SOC_RTL8196C)
#include <asm/mach-realtek/bspchip.h>
#elif defined(CONFIG_SOC_RTL8197F)
#include <asm/mach-rtl8197f/bspchip.h>
#else
#error "Unknown SoC — cannot resolve bsp/bspchip.h"
#endif

#endif
