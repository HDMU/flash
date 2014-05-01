#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4
TMPROOTDIR=$5
TMPEXTDIR=$6

echo "CURDIR       = $CURDIR"
echo "TUFSBOXDIR   = $TUFSBOXDIR"
echo "OUTDIR       = $OUTDIR"
echo "TMPKERNELDIR = $TMPKERNELDIR"
echo "TMPROOTDIR   = $TMPROOTDIR"
echo "TMPEXTDIR   = $TMPEXTDIR"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad
FUP=$CURDIR/fup

OUTFILE=$OUTDIR/update_wo_fw.ird

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

cp $TMPKERNELDIR/uImage $CURDIR/uImage

# Create a jffs2 partition for root
# Size 30     MB = -p0x1E00000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./release
# ./release/etc
# ./release/usr
$MKFSJFFS2 -qUfv -p0x1E00000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin
$PAD 0x1E00000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin

# Create a jffs2 partition for ext
# 0x01220000 - 0x01DFFFFF (11.875 MB)
# Should be p0xBE0000 but due to a bug in stock uboot the size had to be decreased
$MKFSJFFS2 -qUfv -p0xBC0000 -e0x20000 -r $TMPEXTDIR -o $CURDIR/mtd_ext.bin
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_ext.bin -o $CURDIR/mtd_ext.sum.bin
$PAD 0xBC0000 $CURDIR/mtd_ext.sum.bin $CURDIR/mtd_ext.sum.pad.bin

# Create a fortis signed update file for fw's
# Note: -g is a workaround which will be removed as soon as the missing conf partition is found
# Note: -e could be used as a extension partition but at the moment we dont use it
$FUP -ce $OUTFILE -k $CURDIR/uImage -r $CURDIR/mtd_root.sum.pad.bin -g foo -e $CURDIR/mtd_ext.sum.pad.bin

rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_root.sum.bin
rm -f $CURDIR/mtd_root.sum.pad.bin
rm -f $CURDIR/mtd_ext.bin
rm -f $CURDIR/mtd_ext.sum.bin
rm -f $CURDIR/mtd_ext.sum.pad.bin

zip -j $OUTFILE.zip $OUTFILE
