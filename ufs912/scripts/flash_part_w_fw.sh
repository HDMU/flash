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
MUP=$CURDIR/mup

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
OUTFILE=$OUTDIR/update_w_fw.img
OUTFILE_Z=$OUTDIR/$HOST$gitversion

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
  rm -f $OUTFILE.md5
fi

cp $TMPKERNELDIR/uImage $OUTDIR/uImage.bin

# Create a jffs2 partition for fw's
# Size 8mb = -p0x800000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./fw
# ./fw/audio.elf
# ./fw/video.elf
$MKFSJFFS2 -qUfv -p0x800000 -e0x20000 -r $TMPFWDIR -o $OUTDIR/mtd_fw.bin
$SUMTOOL -v -p -e 0x20000 -i $OUTDIR/mtd_fw.bin -o $OUTDIR/mtd_fw.sum.bin
rm -f $OUTDIR/mtd_fw.bin
# Create a jffs2 partition for root
# Size 64mb = -p0x4000000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./release
# ./release/etc
# ./release/usr
$MKFSJFFS2 -qUfv -p0x4000000 -e0x20000 -r $TMPROOTDIR -o $OUTDIR/mtd_root.bin
$SUMTOOL -v -p -e 0x20000 -i $OUTDIR/mtd_root.bin -o $OUTDIR/mtd_root.sum.bin
rm -f $OUTDIR/mtd_root.bin
# Create a kathrein update file for fw's 
# To get the partitions erased we first need to fake an yaffs2 update
$MUP c $OUTFILE << EOF
2
0x00400000, 0x800000, 3, foo
0x00C00000, 0x4000000, 3, foo
0x00000000, 0x0, 1, $OUTDIR/uImage.bin
0x00400000, 0x0, 1, $OUTDIR/mtd_fw.sum.bin
0x00C00000, 0x0, 1, $OUTDIR/mtd_root.sum.bin
;
EOF

md5sum -b $OUTFILE | awk -F' ' '{print $1}' > $OUTFILE.md5
zip -j $OUTFILE_Z.zip $OUTFILE $OUTFILE.md5
rm -f $OUTFILE
rm -f $OUTFILE.md5
rm -f $OUTDIR/uImage.bin
rm -f $OUTDIR/mtd_fw.sum.bin
rm -f $OUTDIR/mtd_root.sum.bin
