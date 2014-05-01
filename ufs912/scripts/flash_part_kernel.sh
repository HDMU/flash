#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4

echo "CURDIR       = $CURDIR"
echo "TUFSBOXDIR   = $TUFSBOXDIR"
echo "OUTDIR       = $OUTDIR"
echo "TMPKERNELDIR = $TMPKERNELDIR"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
MUP=$CURDIR/mup

OUTFILE=$OUTDIR/update_kernel.img

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

cp $TMPKERNELDIR/uImage $CURDIR/uImage

# Create a kathrein update file for fw's 
# Offset on NAND Disk = 0x00400000
$MUP c $OUTFILE << EOF
2
0x00000000, 0x0, 1, uImage
;
EOF

rm -f $CURDIR/uImage

zip -j $OUTFILE.zip $OUTFILE
