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

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
MKSQUASHFS=$CURDIR/../common/mksquashfs4.0
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad

if [ -f $TMPROOTDIR/etc/hostname ]; then
	HOST=`cat $TMPROOTDIR/etc/hostname`
elif [ -f $TMPROOTDIR/var/etc/hostname ]; then
	HOST=`cat $TMPROOTDIR/var/etc/hostname`
fi

if [ -d $CURDIR/../../cvs/apps/libstb-hal-next ]; then
	HAL_REV=_HAL-rev`cd $CURDIR/../../cvs/apps/libstb-hal-next && git log | grep "^commit" | wc -l`-next
elif [ -d $CURDIR/../../cvs/apps/libstb-hal-github ]; then
	HAL_REV=_HAL-rev`cd $CURDIR/../../cvs/apps/libstb-hal-github && git log | grep "^commit" | wc -l`-github
elif [ -d $CURDIR/../../cvs/apps/libstb-hal-martii-github ]; then
	HAL_REV=_HAL-rev`cd $CURDIR/../../cvs/apps/libstb-hal-martii-github && git log | grep "^commit" | wc -l`-martii-github
else
	HAL_REV=_HAL-rev`cd $CURDIR/../../cvs/apps/libstb-hal && git log | grep "^commit" | wc -l`
fi

if [ -d $CURDIR/../../cvs/apps/neutrino-mp-next ]; then
	NMP_REV=_NMP-rev`cd $CURDIR/../../cvs/apps/neutrino-mp-next && git log | grep "^commit" | wc -l`-next
elif [ -d $CURDIR/../../cvs/apps/neutrino-mp-github ]; then
	NMP_REV=_NMP-rev`cd $CURDIR/../../cvs/apps/neutrino-mp-github && git log | grep "^commit" | wc -l`-github
elif [ -d $CURDIR/../../cvs/apps/neutrino-mp-martii-github ]; then
	NMP_REV=_NMP-rev`cd $CURDIR/../../cvs/apps/neutrino-mp-martii-github && git log | grep "^commit" | wc -l`-martii-github
else
	NMP_REV=_NMP-rev`cd $CURDIR/../../cvs/apps/neutrino-mp && git log | grep "^commit" | wc -l`
fi

gitversion="_BASE-rev`(cd $CURDIR/../../ && git log | grep "^commit" | wc -l)`$HAL_REV$NMP_REV"
OUTFILE=$OUTDIR/$HOST$gitversion

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
  rm -f $OUTFILE.md5
fi

# --- KERNEL ---
# Size 8MB !
cp -f $TMPKERNELDIR/uImage $OUTDIR/uImage
#$PAD 0x800000 $CURDIR/uImage $CURDIR/mtd_kernel.pad.bin #padding of kernel uImage is not needed

# --- ROOT ---
# Size 64MB !
echo "MKFSJFFS2 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin -e 0x20000 -p -n"
$MKFSJFFS2 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin -e 0x20000 -p -n
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin
#echo "$PAD 0x4000000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin"
#$PAD 0x4000000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin

#echo "MKFSJFFS2 --qUfv -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin"
#$MKFSJFFS2 -qUfv -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin
#echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.pad.bin"
#$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.pad.bin

#rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_root.bin
#rm -f $CURDIR/mtd_root.sum.bin

#SIZE=`stat mtd_kernel.pad.bin -t --format %s`
#SIZE=`printf "0x%x" $SIZE`
#if [[ $SIZE > "0x800000" ]]; then
#  echo "KERNEL TO BIG. $SIZE instead of 0x800000" > /dev/stderr
#fi

#SIZE=`stat mtd_root.sum.pad.bin -t --format %s`
SIZE=`stat mtd_root.sum.bin -t --format %s`
SIZE=`printf "0x%07x" $SIZE`
if [[ $SIZE > "0x4000000" ]]; then
  echo "ROOT TO BIG. $SIZE instead of 0x4000000" > /dev/stderr
  read -p "Press ENTER to continue..."
fi

#mv $CURDIR/mtd_kernel.pad.bin $OUTDIR/uImage
#mv $CURDIR/mtd_root.sum.pad.bin $OUTDIR/e2jffs2.img
mv $CURDIR/mtd_root.sum.bin $OUTDIR/e2jffs2.img

rm -f $CURDIR/mtd_kernel.pad.bin
#rm -f $CURDIR/mtd_root.sum.pad.bin
rm -f $CURDIR/mtd_root.sum.bin
cd $OUTDIR
zip -j $OUTFILE.zip e2jffs2.img uImage
rm -f $OUTDIR/e2jffs2.img
rm -f $OUTDIR/uImage
