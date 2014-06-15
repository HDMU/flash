#!/bin/bash

CURDIR=$1
RELEASEDIR=$2

TMPROOTDIR=$3
TMPKERNELDIR=$4
TMPFWDIR=$5

cp -a $RELEASEDIR/* $TMPROOTDIR
cp $RELEASEDIR/.version $TMPROOTDIR
mv $TMPROOTDIR/lib/firmware/audio.elf $TMPFWDIR/
mv $TMPROOTDIR/lib/firmware/video.elf $TMPFWDIR/

if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
	cd $TMPROOTDIR/dev/
	if [ -e $TMPROOTDIR/var/etc/init.d/makedev ]; then
		$TMPROOTDIR/var/etc/init.d/makedev start
	else
		$TMPROOTDIR/etc/init.d/makedev start
	fi
	cd -
fi

mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage
rm -fr $TMPROOTDIR/boot
mv $TMPROOTDIR/lib/firmware/* $TMPFWDIR

if [ -e $TMPROOTDIR/var/etc/fstab ]; then
	echo "/dev/mtdblock8	/lib/firmware	jffs2	defaults	0	0" >> $TMPROOTDIR/var/etc/fstab
	#echo "/dev/mtdblock10	/swap	jffs2	defaults	0	0" >> $TMPROOTDIR/var/etc/fstab
else
	echo "/dev/mtdblock8	/lib/firmware	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
	#echo "/dev/mtdblock10	/swap	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
fi
