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
MUP=$CURDIR/mup

OUTFILE=$OUTDIR/update_fw.img

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

# Create a jffs2 partition for fw's
# Size 8mb = -p0x800000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./fw
# ./fw/audio.elf
# ./fw/video.elf
$MKFSJFFS2 -qUfv -p0x800000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin

# Create a kathrein update file for fw's 
# To get the partitions erased we first need to fake an yaffs2 update
$MUP c $OUTFILE << EOF
2
0x00400000, 0x800000, 3, foo
0x00400000, 0x0, 1, mtd_fw.sum.bin
;
EOF

rm -f $CURDIR/mtd_fw.bin
rm -f $CURDIR/mtd_fw.sum.bin

zip -j $OUTFILE.zip $OUTFILE
