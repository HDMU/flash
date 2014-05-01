#!/bin/bash

CURDIR=$1
EXTRADIR=$2
TMPROOTDIR=$3
TMPKERNELDIR=$4

rm -rf $TMPROOTDIR
mkdir $TMPROOTDIR

rm -rf $TMPKERNELDIR
mkdir $TMPKERNELDIR
U=$USER
sudo tar -C $TMPROOTDIR -xf $EXTRADIR/nor_root.tar.gz 2> /dev/null
sudo chown $U $TMPROOTDIR

cp $EXTRADIR/uImage_rootmtd7 $TMPKERNELDIR/uImage


rm -rf $TMPROOTDIR/app
rm -rf $TMPROOTDIR/config
rm -rf $TMPROOTDIR/data
rm -rf $TMPROOTDIR/softwares

sudo rm -rf $TMPROOTDIR/etc/gtk-2.0
rm -rf $TMPROOTDIR/etc/rcS.d

rm -rf $TMPROOTDIR/etc/directfbrc
rm -rf $TMPROOTDIR/etc/fb.modes
rm -rf $TMPROOTDIR/etc/gdk-pixbuf.loaders
rm -rf $TMPROOTDIR/etc/profile

rm -rf $TMPROOTDIR/etc/init.d/*

cp $EXTRADIR/profile $TMPROOTDIR/etc/
cp $EXTRADIR/rcS $TMPROOTDIR/etc/init.d/
chmod 755 $TMPROOTDIR/etc/init.d/rcS
sudo cp $EXTRADIR/update $TMPROOTDIR/bin
sudo chmod 755 $TMPROOTDIR/bin/update
