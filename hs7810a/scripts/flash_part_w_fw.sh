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

OUTFILE=$OUTDIR/update_w_fw.ird

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
echo "MKFSJFFS2 -qUfv -p0x4E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin"
$MKFSJFFS2 -qUfv -p0x4E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin > /dev/null
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin > /dev/null
echo "PAD 0x4E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin"
$PAD 0x4E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin

cat $CURDIR/dummy.squash.signed.padded > $CURDIR/mtd_fw.sum.pad.signed.bin
cat $CURDIR/mtd_fw.sum.pad.bin >> $CURDIR/mtd_fw.sum.pad.signed.bin

# Create a jffs2 partition for root
# Size 30     MB = -p0x1E00000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./release
# ./release/etc
# ./release/usr
echo "MKFSJFFS2 -qUfv -p0x1240000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin"
$MKFSJFFS2 -qUfv -p0x1240000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin > /dev/null
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin > /dev/null
echo "PAD 0x1240000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin"
$PAD 0x1240000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin

# Split the rootfs

#root
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.r.bin bs=1 skip=0 count=0x00ac0000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.r.bin bs=1 skip=0 count=11272192
cat $CURDIR/dummy.squash.signed.padded > $CURDIR/mtd_root.sum.pad.r.signed.bin
cat $CURDIR/mtd_root.sum.pad.r.bin >> $CURDIR/mtd_root.sum.pad.r.signed.bin
#dev7
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.d.bin bs=1 skip=0x00ac0000 count=0x002c0000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.d.bin bs=1 skip=11272192 count=2883584
cat $CURDIR/dummy.squash.signed.padded > $CURDIR/mtd_root.sum.pad.d.signed.bin
cat $CURDIR/mtd_root.sum.pad.d.bin >> $CURDIR/mtd_root.sum.pad.d.signed.bin
#config2345
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.c0.bin bs=1 skip=0x00d80000 count=0x00040000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.c0.bin bs=1 skip=14155776 count=262144
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.c4.bin bs=1 skip=0x00dc0000 count=0x00040000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.c4.bin bs=1 skip=14417920 count=262144
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.c8.bin bs=1 skip=0x00e00000 count=0x00020000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.c8.bin bs=1 skip=14680064 count=131072
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.ca.bin bs=1 skip=0x00e20000 count=0x00020000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.ca.bin bs=1 skip=14811136 count=131072
#user9
echo "dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.u.bin bs=1 skip=0x00e40000 count=0x00400000"
dd if=$CURDIR/mtd_root.sum.pad.bin of=$CURDIR/mtd_root.sum.pad.u.bin bs=1 skip=14942208 count=4194304

$FUP -c $OUTFILE -k $CURDIR/uImage -a $CURDIR/mtd_fw.sum.pad.signed.bin -r $CURDIR/mtd_root.sum.pad.r.signed.bin -d $CURDIR/mtd_root.sum.pad.d.signed.bin -c0 $CURDIR/mtd_root.sum.pad.c0.bin -c4 $CURDIR/mtd_root.sum.pad.c4.bin -c8 $CURDIR/mtd_root.sum.pad.c8.bin -ca $CURDIR/mtd_root.sum.pad.ca.bin -u $CURDIR/mtd_root.sum.pad.u.bin

# Change reseller id
./fup -r $OUTFILE 2522

rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_fw.bin
#rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_fw.sum.bin
#rm -f $CURDIR/mtd_root.sum.bin
rm -f $CURDIR/mtd_fw.sum.pad.bin
#rm -f $CURDIR/mtd_root.sum.pad.bin

zip -j $OUTFILE.zip $OUTFILE
