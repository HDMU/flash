#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4
TMPFWDIR=$5
TMPROOTDIR=$6

echo "CURDIR       = $CURDIR"
echo "TUFSBOXDIR   = $TUFSBOXDIR"
echo "OUTDIR       = $OUTDIR"
echo "TMPKERNELDIR = $TMPKERNELDIR"
echo "TMPFWDIR     = $TMPFWDIR"
echo "TMPROOTDIR   = $TMPROOTDIR"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad
FUP=$CURDIR/fup

. $CURDIR/../common/gitversion.sh $CURDIR

OUTFILE=$OUTDIR/update_w_fw.ird
OUTFILE_Z=$OUTDIR/$HOST$gitversion

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

cp $TMPKERNELDIR/uImage $CURDIR/uImage

# Create a jffs2 partition for fw's
# Size 6.875  MB = -p0x6E0000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./fw
# ./fw/audio.elf
# ./fw/video.elf
echo "MKFSJFFS2 -qUfv -p0x6E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin"
$MKFSJFFS2 -qUfv -p0x6E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin > /dev/null
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin > /dev/null
echo "PAD 0x6E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin"
$PAD 0x6E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin

# Create a jffs2 partition for root
# Size 30     MB = -p0x1E00000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./release
# ./release/etc
# ./release/usr
echo "MKFSJFFS2 -qUfv -p0x1E00000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin"
$MKFSJFFS2 -qUfv -p0x1E00000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin > /dev/null
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin > /dev/null
echo "PAD 0x1E00000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin"
$PAD 0x1E00000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin

# Create a fortis signed update file for fw's 
# Note: -g is a workaround which will be removed as soon as the missing conf partition is found
# Note: -e could be used as a extension partition but at the moment we dont use it
echo "FUP -ce $OUTFILE -k $CURDIR/uImage -f $CURDIR/mtd_fw.sum.pad.bin -g foo -e foo -r $CURDIR/mtd_root.sum.pad.bin"
$FUP -ce $OUTFILE -k $CURDIR/uImage -f $CURDIR/mtd_fw.sum.pad.bin -g foo -e foo -r $CURDIR/mtd_root.sum.pad.bin

rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_fw.bin
rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_fw.sum.bin
rm -f $CURDIR/mtd_root.sum.bin
rm -f $CURDIR/mtd_fw.sum.pad.bin
rm -f $CURDIR/mtd_root.sum.pad.bin

md5sum -b $OUTFILE | awk -F' ' '{print $1}' > $OUTFILE.md5
zip -j $OUTFILE_Z.zip $OUTFILE $OUTFILE.md5
