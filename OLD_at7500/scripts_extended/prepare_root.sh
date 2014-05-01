#!/bin/bash

CURDIR=$1
RELEASEDIR=$2

TMPROOTDIR=$3
TMPEXTDIR=$4
TMPKERNELDIR=$5
TMPFWDIR=$6

cp -a $RELEASEDIR/* $TMPROOTDIR
cp $RELEASEDIR/.version $TMPROOTDIR

mv $TMPROOTDIR/etc/enigma2/ $TMPROOTDIR/var/etc/enigma2/
ln -s /var/etc/enigma2 $TMPROOTDIR/etc/enigma2

mv $TMPROOTDIR/var/* $TMPEXTDIR
mkdir $TMPEXTDIR/usr
mkdir $TMPEXTDIR/usr/share
mkdir $TMPEXTDIR/usr/lib
mv $TMPROOTDIR/usr/lib/enigma2 $TMPEXTDIR/usr/lib/
ln -s /var/usr/lib/enigma2 $TMPROOTDIR/usr/lib/
mv $TMPROOTDIR/usr/share/* $TMPEXTDIR/usr/share/
rm -rf $TMPROOTDIR/usr/share/
ln -s /var/usr/share $TMPROOTDIR/usr/share
rm $TMPEXTDIR/usr/share/enigma2
mv $TMPROOTDIR/usr/local/share/enigma2/ $TMPEXTDIR/usr/share/
ln -s /usr/share/enigma2 $TMPROOTDIR/usr/local/share/enigma2

mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage

mv $TMPROOTDIR/boot/audio.elf $TMPFWDIR/audio.elf
mv $TMPROOTDIR/boot/video.elf $TMPFWDIR/video.elf

rm -f $TMPROOTDIR/boot/*

echo "/dev/mtdblock2	/boot	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
echo "/dev/mtdblock3	/var	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab


if [  -e $CURDIR/extras/dev_at7500.tar.gz ]; then
  sudo tar -xzf $CURDIR/extras/dev_at7500.tar.gz -C $TMPROOTDIR/dev/
fi
