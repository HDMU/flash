#!/bin/bash

CURDIR=$1
RELEASEDIR=$2

TMPROOTDIR=$3
TMPKERNELDIR=$4
TMPFWDIR=$5

cp -a $RELEASEDIR/* $TMPROOTDIR

cd $TMPROOTDIR/dev/
$TMPROOTDIR/etc/init.d/makedev start
cd -

mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage

mv $TMPROOTDIR/boot/audio.elf $TMPFWDIR/audio.elf
mv $TMPROOTDIR/boot/video.elf $TMPFWDIR/video.elf

mv $TMPROOTDIR/boot/bootlogo.mvi $TMPROOTDIR/etc/bootlogo.mvi
sed -i "s/\/boot\/bootlogo.mvi/\/etc\/bootlogo.mvi/g" $TMPROOTDIR/etc/init.d/rcS

rm -f $TMPROOTDIR/boot/*

echo "/dev/mtdblock2	/boot	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
#echo "/dev/mtdblock5	/root	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab

