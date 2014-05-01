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
FUP=$CURDIR/fup

OUTFILE=$OUTDIR/update_kernel.ird

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

cp $TMPKERNELDIR/uImage $CURDIR/uImage

# Create a fortis signed update file for fw's 
$FUP -ce $OUTFILE -k $CURDIR/uImage

rm -f $CURDIR/uImage

zip -j $OUTFILE.zip $OUTFILE
