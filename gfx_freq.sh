#!/bin/bash

# https://askubuntu.com/a/569122
# https://github.com/vicious-widgets/vicious/blob/master/contrib/ati_linux.lua

# Radeon R9 270     "Up to 925MHz engine clock", "Up to 1.4 GHz (5.6Gbps) memory clock speed"
# Radeon R7 370     975MHz                       1.4 GHz
# mclk seems to be just move decimal place 5 to the left to get GHz
# and sclk ... 2 to get MHz?

# sclk is the engine clock, clock units seem to be kHz * 10
# vddc is the core voltage
freq_mhz=$(echo "scale=1; $((`sudo grep -o "sclk: [0-9]*" /sys/kernel/debug/dri/0/radeon_pm_info | cut -d ' ' -f 2` / 100))" | bc -l)

echo $freq_mhz