#!/bin/bash

CURDIR=$1
RELEASEDIR=$2
TMPROOTDIR=$3
TMPKERNELDIR=$4


cp -a $RELEASEDIR/* $TMPROOTDIR


rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/ar
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/bg
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/c*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/da
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/el
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/es
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/et
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/f*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/h*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/i*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/k*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/l*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/n*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/p*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/r*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/s*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/t*
rm -rf $TMPROOTDIR/usr/local/share/enigma2/po/uk
cd $TMPROOTDIR/dev/
$TMPROOTDIR/etc/init.d/makedev start
cd -

mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage


cp -rf $HOME/HDMU-BUILD/tools/boot/* $TMPROOTDIR/boot
#sed -i "s/\/boot\/bootlogo.mvi/\/etc\/bootlogo.mvi/g" $TMPROOTDIR/etc/init.d/rcS



#echo "/dev/mtdblock2	/boot	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab
#echo "/dev/mtdblock4	/var	jffs2	defaults	0	0" >> $TMPROOTDIR/etc/fstab


