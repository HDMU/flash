#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4
TMPROOTDIR=$5

echo "CURDIR       = $CURDIR"
echo "TUFSBOXDIR   = $TUFSBOXDIR"
echo "OUTDIR       = $OUTDIR"
echo "TMPKERNELDIR = $TMPKERNELDIR"
echo "TMPROOTDIR   = $TMPROOTDIR"

MKCRAMFS=$CURDIR/../common/mkcramfs1.1
MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
MUP=$CURDIR/mup

OUTFILE=$OUTDIR/ufs913.software.V1.00.B00.data

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

cp $TMPKERNELDIR/uImage $CURDIR/uImage

# Create a jffs2 partition for fw's
#$MKFSJFFS2 -qUfv -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_tiny.bin
echo "$MKCRAMFS $TMPROOTDIR $CURDIR/mtd_tiny.bin"
$MKCRAMFS $TMPROOTDIR $CURDIR/mtd_tiny.bin


# Create a kathrein update file for fw's 
$MUP c $OUTFILE << EOF
3
0x00400000, 0x0, 0, uImage
0x00660000, 0x0, 0, mtd_tiny.bin
;
EOF

rm -f $CURDIR/uImage
#rm -f $CURDIR/mtd_tiny.bin

rm -rf $TMPKERNELDIR
sudo rm -rf $TMPROOTDIR


