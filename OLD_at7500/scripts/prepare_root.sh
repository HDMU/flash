#!/bin/bash

CURDIR=$1
RELEASEDIR=$2

TMPROOTDIR=$3
TMPKERNELDIR=$4
TMPFWDIR=$5

cp -a $RELEASEDIR/* $TMPROOTDIR
cp $RELEASEDIR/.version $TMPROOTDIR

mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage

mv $TMPROOTDIR/boot/audio.elf $TMPFWDIR/audio.elf
mv $TMPROOTDIR/boot/video.elf $TMPFWDIR/video.elf

rm -f $TMPROOTDIR/boot/*

if [ -e $TMPROOTDIR/var/etc/fstab ]; then
	echo "/dev/mtdblock2	/boot	jffs2	defaults	0	0" >> $TMPROOTDIR/var/etc/fstab
	#echo "/dev/mtdblock5	/root	jffs2	defaults	0	0" >> $TMPROOTDIR/var/etc/fstab
else
	echo "/dev/mtdblock2	/boot	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
	#echo "/dev/mtdblock5	/root	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
fi

cd $TMPROOTDIR/dev/
MAKEDEV="sudo $TMPROOTDIR/sbin/MAKEDEV -p $TMPROOTDIR/var/etc/passwd -g $TMPROOTDIR/var/etc/group"
${MAKEDEV} std
${MAKEDEV} fd
${MAKEDEV} hda hdb
${MAKEDEV} sda sdb sdc sdd
${MAKEDEV} scd0 scd1
${MAKEDEV} st0 st1
${MAKEDEV} sg
${MAKEDEV} ptyp ptyq
${MAKEDEV} console
${MAKEDEV} ttyAS0 ttyAS1 ttyAS2 ttyAS3
${MAKEDEV} lp par audio video fb rtc lirc st200 alsasnd mme bpamem
${MAKEDEV} ppp busmice
${MAKEDEV} input i2c mtd
${MAKEDEV} dvb dvb_2nd
${MAKEDEV} vfd
${MAKEDEV} hdmi_cec
cd -
