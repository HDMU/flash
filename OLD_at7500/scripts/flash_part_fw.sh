#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPFWDIR=$4

echo "CURDIR     = $CURDIR"
echo "TUFSBOXDIR = $TUFSBOXDIR"
echo "OUTDIR     = $OUTDIR"
echo "TMPFWDIR   = $TMPFWDIR"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad
FUP=$CURDIR/fup

OUTFILE=$OUTDIR/update_fw.ird

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

# Create a jffs2 partition for fw's
# Size 6.875  MB = -p0x6E0000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./fw
# ./fw/audio.elf
# ./fw/video.elf
$MKFSJFFS2 -qUfv -p0x6E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin
$PAD 0x6E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin

# Create a fortis signed update file for fw's 
echo "CMD: $FUP -ce $OUTFILE -f $CURDIR/mtd_fw.sum.pad.bin"
$FUP -ce $OUTFILE -f $CURDIR/mtd_fw.sum.pad.bin

rm -f $CURDIR/mtd_fw.bin
rm -f $CURDIR/mtd_fw.sum.bin
rm -f $CURDIR/mtd_fw.sum.pad.bin

zip -j $OUTFILE.zip $OUTFILE
