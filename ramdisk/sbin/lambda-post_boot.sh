#!/system/bin/sh
# Copyright (c) 2012-2013, 2016, The Linux Foundation. All rights reserved.
# Copyright (c) 2016-2017, The Paranoid Android Project.
# Copyright (c) 2016-2018, Ícaro Pereira Hoff.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

STATE=$(getprop ro.lambda.state)

# Common function to print Lambda Kernel messages only once.
function lkmsg() {
  if [ -z "$STATE" ] || [ ! "$STATE" = "active" ]; then
    echo "[Lambda] $1" | tee /dev/kmsg
  fi;
}

VECTOR=$(getprop ro.lambda.vector)
DEVICE=$(getprop ro.lambda.device)

lkmsg "Welcome to $VECTOR!"
sleep 5

# Zenith Vector Tuning (EAS):
if [ "$VECTOR" = "Zenith" ]; then
  # Adjust 'schedtune' values for foreground, top-app and rt.
  echo 1 > /dev/stune/foreground/schedtune.prefer_idle
  echo 1 > /dev/stune/top-app/schedtune.prefer_idle
  echo 1 > /dev/stune/top-app/schedtune.sched_boost
  echo 1 > /dev/stune/rt/schedtune.prefer_idle
  # Switch to 'schedutil' CPU governor.
  echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
  echo "schedutil" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
  # Perform rate limit fine tuning.
  echo 500 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
  echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
  echo 500 > /sys/devices/system/cpu/cpu2/cpufreq/schedutil/up_rate_limit_us
  echo 20000 > /sys/devices/system/cpu/cpu2/cpufreq/schedutil/down_rate_limit_us
fi;

# Setup CPU input boost.
echo "0:1190400 2:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 90 > /sys/module/cpu_boost/parameters/input_boost_ms
if [ "$VECTOR" = "Zenith" ]; then
  # This dynamic stune boost tunable is only available on EAS.
  echo 1 > /sys/module/cpu_boost/parameters/dynamic_stune_boost
fi;

# Disable printk console suspend.
echo "N" > /sys/module/printk/parameters/console_suspend

# Set GPU default/idle power level to the lowest one.
# MSM8996:
if [ "$DEVICE" = "x2" ]; then
  echo 6 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
fi;
# MSM8996AB:
if [ "$DEVICE" = "zl1" ]; then
  echo 7 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
fi;

# Set the optimal read-ahead value for all blocks.
for block_device in /sys/block/*
do
  echo 128 > $block_device/queue/read_ahead_kb
done

# Switch the I/O scheduler via property, if available in *.rc.
setprop sys.io.scheduler "maple"

# Switch the I/O scheduler for the main blocks.
echo "maple" > /sys/block/sda/queue/scheduler
echo "maple" > /sys/block/sde/queue/scheduler

# If encrypted, switch the DM blocks' I/O scheduler as well.
if [ "$(getprop ro.crypto.state)" = "encrypted" ]; then
  echo "maple" > /sys/block/dm-0/queue/scheduler
fi;

# We're awake and alive, again.
lkmsg "We are awake and alive!"
setprop ro.lambda.state "active"
