#!/bin/sh
#
# Copyright 2013, Silverio Diquigiovanni <silverio.android@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEV=/dev/sdc
UBOOT_PATH=/home/shine/android/build/linux-sunxi/u-boot-sunxi
KERNEL_PATH=/home/shine/android/build/cubieboard2-sdk/lichee/linux-3.3
BUILD_PATH=/home/shine/android/build/cubieboard2-sdk/android42/out/target/product/sugar-cubieboard2

echo_red() {
	echo "\033[31m$1\033[0m"
}

echo_green() {
	echo "\033[32m$1\033[0m"
}

nand_to_mmc_partition() {
  	sed -i "s/nanda/mmcblk0p1/g" $1
  	sed -i "s/nandb/mmcblk0p2/g" $1
  	sed -i "s/nandc/mmcblk0p3/g" $1
  	sed -i "s/nandd/mmcblk0p5/g" $1
	sed -i "s/nande/mmcblk0p6/g" $1
	sed -i "s/nandf/mmcblk0p7/g" $1
  	sed -i "s/nandg/mmcblk0p8/g" $1
  	sed -i "s/nandh/mmcblk0p9/g" $1
  	sed -i "s/nandi/mmcblk0p10/g" $1
  	sed -i "s/nandj/mmcblk0p11/g" $1
 	sed -i "s/\/dev\/block\/bootloader/\/dev\/block\/mmcblk0p1/g" $1
 	sed -i "s/\/dev\/block\/env/\/dev\/block\/mmcblk0p2/g" $1
 	sed -i "s/\/dev\/block\/boot/\/dev\/block\/mmcblk0p3/g" $1
 	sed -i "s/\/dev\/block\/system/\/dev\/block\/mmcblk0p5/g" $1
 	sed -i "s/\/dev\/block\/databk/\/dev\/block\/mmcblk0p10/g" $1
 	sed -i "s/\/dev\/block\/data/\/dev\/block\/mmcblk0p6/g" $1
 	sed -i "s/\/dev\/block\/misc/\/dev\/block\/mmcblk0p7/g" $1
 	sed -i "s/\/dev\/block\/recovery/\/dev\/block\/mmcblk0p8/g" $1
 	sed -i "s/\/dev\/block\/cache/\/dev\/block\/mmcblk0p9/g" $1
 	sed -i "s/\/dev\/block\/UDISK/\/dev\/block\/mmcblk0p11/g" $1
}

echo_green "check root user..."
if [ ! $USER = "root" ]; then
	echo_red "root priviledges required !"
	exit 1
fi

echo_green "check u-boot path..."
if [ ! -d "$UBOOT_PATH" ]; then
	echo_red "invalid u-boot path !"
	exit 1
fi

echo_green "check kernel path..."
if [ ! -d "$KERNEL_PATH" ]; then
	echo_red "invalid kernel path !"
	exit 1
fi

echo_green "check build path..."
if [ ! -d "$BUILD_PATH" ] || [ ! -d $BUILD_PATH/root ] || [ ! -d $BUILD_PATH/system ] || [ ! -d $BUILD_PATH/recovery ]; then
	echo_red "invalid build path !"
	exit 1
fi

echo_green "clean device mbr..."
dd if=/dev/zero of=$DEV bs=1M count=1

echo_green "create device partitions..."
sfdisk -f $DEV < partitions.txt

#
# Mount points for Android 4.2
#
#       from    to           type   name          size
#       =====   =========    ====   ==========    ====
# 	nanda - mmcblk0p1  - vfat - bootloader  - 8000
#	nandb - mmcblk0p2  - emmc - env	  	- 8000		I SWITCH to ext4
# 	nandc - mmcblk0p3  - emmc - boot	- 8000		I SWITCH to ext4
# 	nandd - mmcblk0p5  - ext4 - system	- 100000
# 	nande - mmcblk0p6  - ext4 - data 	- 100000
# 	nandf - mmcblk0p7  - emmc - misc	- 8000		I SWITCH to ext4
# 	nandg - mmcblk0p8  - ext4 - recovery	- 10000
# 	nandh - mmcblk0p9  - ext4 - cache	- 80000
# 	nandi - mmcblk0p10 - ext4 - databk	- 80000
# 	nandj - mmcblk0p11 - vfat - UDISK	- 428000
#
# In init.sun7i.rc there is also a private mounting point that don't mach any nand partition.
# Perpahs is because nand driver can't map more than ten partitions ? Or is because private 
# isn't used by AllWinner ported Android OS ? Mistery ...
#
#	nand? - mmcblk0p?? - vfat - private 	- ????          

echo_green "format device partitions..."
mkfs.vfat ${DEV}1 -n bootloader
mkfs.ext4 ${DEV}2 -L env
mkfs.ext4 ${DEV}3 -L boot
mkfs.ext4 ${DEV}5 -L system
mkfs.ext4 ${DEV}6 -L data
mkfs.ext4 ${DEV}7 -L misc
mkfs.ext4 ${DEV}8 -L recovery
mkfs.ext4 ${DEV}9 -L cache
mkfs.ext4 ${DEV}10 -L databk
mkfs.vfat ${DEV}11 -n UDISK

# workaround for EXT4-fs (mmcblk0pX): Filesystem with huge files cannot be mounted RDWR without CONFIG_LBDAF
# actually cubieboard-tv-sdk, that I'm using with this script, don't had CONFIG_LBDAF enabled so the workaround is needed
echo_green "remove huge_file option from ext4 partitios..."
tune2fs -O ^huge_file ${DEV}2
#e2fsck ${DEV}2
tune2fs -O ^huge_file ${DEV}3
#e2fsck ${DEV}3
tune2fs -O ^huge_file ${DEV}5
#e2fsck ${DEV}5
tune2fs -O ^huge_file ${DEV}6
#e2fsck ${DEV}6
tune2fs -O ^huge_file ${DEV}7
#e2fsck ${DEV}7
tune2fs -O ^huge_file ${DEV}8
#e2fsck ${DEV}8
tune2fs -O ^huge_file ${DEV}9
#e2fsck ${DEV}9
tune2fs -O ^huge_file ${DEV}10
#e2fsck ${DEV}10

echo_green "write SPL into device..."
# dd if=$UBOOT_PATH/spl/sunxi-spl.bin of=$DEV bs=1024 seek=8
dd if=/home/shine/android/build/cubieboard2-linux3.3_hwpack/bootloader/sunxi-spl.bin of=$DEV bs=1024 seek=8
echo_green "write U-BOOTL into device..."
# dd if=$UBOOT_PATH/u-boot.bin of=$DEV bs=1024 seek=32
dd if=/home/shine/android/build/cubieboard2-linux3.3_hwpack/bootloader/u-boot.bin of=$DEV bs=1024 seek=32

echo_green "mount device partitions..."
if [ -d mnt ]; then
	rm -rf mnt
fi

mkdir mnt
mkdir mnt/bootloader
mkdir mnt/boot
mkdir mnt/system
mkdir mnt/recovery

mount ${DEV}1 mnt/bootloader
mount ${DEV}3 mnt/boot
mount ${DEV}5 mnt/system
mount ${DEV}8 mnt/recovery

echo_green "update bootloader..."
mkimage -A ARM -C none -T kernel -O linux  -a 40008000 -e 40008000 -d $KERNEL_PATH/output/zImage mnt/bootloader/uImage
cp support/script.bin mnt/bootloader
cp support/uEnv.txt mnt/bootloader

echo_green "update boot..."
cp -r $BUILD_PATH/root/* mnt/boot

echo_green "update system..."
cp -r $BUILD_PATH/system/* mnt/system

echo_green "update recovery..."
cp -r $BUILD_PATH/recovery/* mnt/recovery
sync

#echo_green "change dpi value..."
#sed -i "s/ro.sf.lcd_density=160/ro.sf.lcd_density=120/g" mnt/system/build.prop

echo_green "change nand(x) to mmcblk0p(y) partitions..."
nand_to_mmc_partition mnt/boot/init.sun7i.rc
#nand_to_mmc_partition mnt/boot/ueventd.sun7i.rc

#nand_to_mmc_partition mnt/system/etc/vold.fstab
nand_to_mmc_partition mnt/system/bin/data_resume.sh
nand_to_mmc_partition mnt/system/bin/preinstall.sh
nand_to_mmc_partition mnt/system/bin/sop.sh

#nand_to_mmc_partition mnt/recovery/root/ueventd.sun7i.rc
nand_to_mmc_partition mnt/recovery/root/etc/recovery.fstab

echo_green "umount device partitions..."
sync
umount ${DEV}1
umount ${DEV}3
umount ${DEV}5
umount ${DEV}8

echo_green "clean mnt path..."
rm -rf mnt

echo_green "== THAT'S ALL FOLKS ! =="
