# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Lambda Kernel
kernel.vector=Plain
kernel.version=FALLBACK / 07222018
compiler.clang=None
compiler.gcc=None
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
is_treble_device=0;
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
# treble
if [ -f /vendor/build.prop ]; then
  is_treble_device=1;
  ui_print "Treble support is present, reconfiguring...";
  mount -o rw,remount -t auto /vendor 2>/dev/null;
fi;

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

# default.prop
if [ $is_treble_device == 1 ]; then
  ui_print "[Treble] Patching custom Lambda properties...";
  patch_prop /vendor/default.prop "ro.lambda.device" "$(file_getprop /tmp/anykernel/autogen.sh device.name1)";
  patch_prop /vendor/default.prop "ro.lambda.vector" "$(file_getprop /tmp/anykernel/autogen.sh kernel.vector)";
else
  ui_print "Patching custom Lambda properties...";
  patch_prop default.prop "ro.lambda.device" "$(file_getprop /tmp/anykernel/autogen.sh device.name1)";
  patch_prop default.prop "ro.lambda.vector" "$(file_getprop /tmp/anykernel/autogen.sh kernel.vector)";
fi;

# init.qcom.rc / init.qcom.power.rc
if [ $is_treble_device == 1 ]; then
  backup_file /vendor/etc/init/hw/init.qcom.rc;
  ui_print "[Treble] Injecting custom post-boot tuning script...";
  cp -f $prebuilt/vendor/etc/init/hw/init.lambda.rc /vendor/etc/init/hw/init.lambda.rc;
  #cp -f $prebuilt/vendor/bin/init.qcom.post_boot.sh /vendor/bin/init.qcom.post_boot.sh;
  #chown root:shell /vendor/bin/init.qcom.post_boot.sh;
  #ln -sf /vendor/bin/init.qcom.post_boot.sh /vendor/bin/lambda-post_boot.sh
  insert_line /vendor/etc/init/hw/init.qcom.rc "init.lambda.rc" after "import /vendor/etc/init/hw/init.device.rc" "import /vendor/etc/init/hw/init.lambda.rc";
else
  backup_file init.qcom.power.rc;
  ui_print "Injecting custom post-boot tuning script...";
  append_file init.qcom.power.rc "lambda-post_boot" init.script.patch;
fi;

# umount /vendor, if treble
if [ $is_treble_device == 1 ]; then
  mount -o ro,remount -t auto /vendor 2>/dev/null;
fi;
# end ramdisk changes

write_boot;

## end install
