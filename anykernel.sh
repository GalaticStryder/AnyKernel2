# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Lambda Kernel
kernel.vector=Plain
kernel.version=FALLBACK / 07222018
do.devicecheck=0
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
'; } # end properties

# shell variables
block=boot;
is_slot_device=0;
ramdisk_compression=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chmod -R 755 $ramdisk/sbin;
chown -R root:root $ramdisk/*;

## AnyKernel install
dump_boot;

# begin ramdisk changes
# sepolicy
$bin/magiskpolicy --load sepolicy --save sepolicy \
    "allow qti_init_shell kmsg_device chr_file { read write open } " \
    "allow qti_init_shell sysfs_kgsl file write" \
    "allow qti_init_shell sysfs_cpu_boost file write" \
    "allow qti_init_shell sysfs dir rw_file_perms" \
    "allow qti_init_shell sysfs file rw_file_perms" \
    "allow qti_init_shell kernel system syslog_read" \
    "allow qti_init_shell default_prop property_service set" \
    ;

# sepolicy_debug
$bin/magiskpolicy --load sepolicy_debug --save sepolicy_debug \
    "allow qti_init_shell kmsg_device chr_file { read write open } " \
    "allow qti_init_shell sysfs_kgsl file write" \
    "allow qti_init_shell sysfs_cpu_boost file write" \
    "allow qti_init_shell sysfs dir rw_file_perms" \
    "allow qti_init_shell sysfs file rw_file_perms" \
    "allow qti_init_shell kernel system syslog_read" \
    "allow qti_init_shell default_prop property_service set" \
    ;

patch_prop default.prop "ro.lambda.device" "$(file_getprop /tmp/anykernel/autogen.sh device.name1)";
patch_prop default.prop "ro.lambda.vector" "$(file_getprop /tmp/anykernel/autogen.sh kernel.vector)";

# init.qcom.power.rc
backup_file init.qcom.power.rc;
ui_print "Injecting custom post-boot tuning script...";
append_file init.qcom.power.rc "lambda-post_boot" init.script.patch;
# end ramdisk changes

write_boot;

## end install
