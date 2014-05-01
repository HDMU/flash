#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4
TMPROOTDIR=$5
TMPVARDIR=$6

echo "CURDIR       = $CURDIR"
echo "TUFSBOXDIR   = $TUFSBOXDIR"
echo "OUTDIR       = $OUTDIR"
echo "TMPKERNELDIR = $TMPKERNELDIR"
echo "TMPROOTDIR   = $TMPROOTDIR"
echo "TMPVARDIR    = $TMPVARDIR"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
MKSQUASHFS=$CURDIR/../common/mksquashfs4.0
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad

ZIPFILE=$OUTDIR/update_w_fw.zip
ZIPDATA=${OUTDIR}/kathrein
OUTDIR=$OUTDIR/kathrein/ufc960
OUTFILE=$OUTDIR/update.img

if [ ! -e $OUTDIR ]; then
  mkdir -p $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
fi

if [ -e $ZIPFILE ]; then
  rm -f $ZIPFILE
fi

#KMAX=0x160000
#RMAX=0x9e0000
#VMAX=0x480000
KMAX=0x1a0000
RMAX=0x9c0000
VMAX=0x460000

# --- KERNEL ---
# Size 1,375MB !
cp $TMPKERNELDIR/uImage $CURDIR/uImage
$PAD ${KMAX} $CURDIR/uImage $CURDIR/mtd_kernel.pad.bin

# --- ROOT ---
# Create a squashfs partition for root
# Size 9,875MB ! ${RMAX}
echo "MKSQUASHFS $TMPROOTDIR $CURDIR/mtd_root.bin -comp lzma -all-root"
$MKSQUASHFS $TMPROOTDIR $CURDIR/mtd_root.bin -comp lzma -all-root > /dev/null
echo "PAD ${RMAX} $CURDIR/mtd_root.bin $CURDIR/mtd_root.pad.bin"
$PAD ${RMAX} $CURDIR/mtd_root.bin $CURDIR/mtd_root.pad.bin

# --- VAR ---
# Size 4,5
echo "MKFSJFFS2 -qUfv -p${VMAX} -e0x20000 -r $TMPVARDIR -o $CURDIR/mtd_var.bin"
$MKFSJFFS2 -qUfv -p${VMAX} -e0x20000 -r $TMPVARDIR -o $CURDIR/mtd_var.bin
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_var.bin -o $CURDIR/mtd_var.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_var.bin -o $CURDIR/mtd_var.sum.bin
echo "$PAD ${VMAX} $CURDIR/mtd_var.sum.bin $CURDIR/mtd_var.sum.pad.bin"
$PAD ${VMAX} $CURDIR/mtd_var.sum.bin $CURDIR/mtd_var.sum.pad.bin

# --- update.img ---
#Merge all 3 together
cat $CURDIR/mtd_kernel.pad.bin >> $OUTFILE
cat $CURDIR/mtd_root.pad.bin >> $OUTFILE
cat $CURDIR/mtd_var.sum.pad.bin >> $OUTFILE

rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_var.bin
rm -f $CURDIR/mtd_var.sum.bin

SIZE=`stat mtd_kernel.pad.bin -t --format %s`
SIZE=`printf "0x%x" $SIZE`
if [[ $SIZE > "${KMAX}" ]]; then
  echo "KERNEL TO BIG. $SIZE instead of ${KMAX}" > /dev/stderr
  read -p "Press ENTER to continue..."
fi

SIZE=`stat mtd_root.pad.bin -t --format %s`
SIZE=`printf "0x%x" $SIZE`
if [[ $SIZE > "${RMAX}" ]]; then
  echo "ROOT TO BIG. $SIZE instead of ${RMAX}" > /dev/stderr
  read -p "Press ENTER to continue..."
fi

SIZE=`stat mtd_var.sum.pad.bin -t --format %s`
SIZE=`printf "0x%x" $SIZE`
if [[ $SIZE > "${VMAX}" ]]; then
  echo "VAR TO BIG. $SIZE instead of ${VMAX}" > /dev/stderr
  read -p "Press ENTER to continue..."
fi

rm -f $CURDIR/mtd_kernel.pad.bin
rm -f $CURDIR/mtd_root.pad.bin
rm -f $CURDIR/mtd_var.sum.pad.bin

cp $CURDIR/extra/updatescript.sh $OUTDIR

cd `dirname ${ZIPDATA}`
zip -r ${ZIPFILE} `basename ${ZIPDATA}`
cd - > /dev/null
