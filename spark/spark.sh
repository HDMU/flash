#!/bin/bash
if [ `id -u` != 0 ]; then
	echo "You are not running this script as root. Try it again as root or with su/sudo command."
	echo "Bye Bye..."
	exit
fi

CURDIR=`pwd`
BASEDIR=$CURDIR/../..

TUFSBOXDIR=$BASEDIR/tufsbox
CDKDIR=$BASEDIR/cvs/cdk

SCRIPTDIR=$CURDIR/scripts
TMPDIR=$CURDIR/tmp
TMPROOTDIR=$TMPDIR/ROOT
TMPKERNELDIR=$TMPDIR/KERNEL

OUTDIR=$CURDIR/out

if [ -e $TMPDIR ]; then
	rm -rf $TMPDIR/*
fi

mkdir -p $TMPDIR
mkdir -p $TMPROOTDIR
mkdir -p $TMPKERNELDIR

echo "This script creates flashable images for Spark"
echo "Author: Schischu, BPanther"
echo "Date: 05-05-2013"
echo "-----------------------------------------------------------------------"
echo "It's expected that an image was already build prior to this execution!"
echo "-----------------------------------------------------------------------"

$BASEDIR/flash/common/common.sh $BASEDIR/flash/common/

echo "-----------------------------------------------------------------------"
echo "Checking targets..."
echo "Found targets:"
if [  -e $TUFSBOXDIR/release ]; then
	echo "Preparing Enigma2..."
	$SCRIPTDIR/prepare_root.sh $CURDIR $TUFSBOXDIR/release $TMPROOTDIR $TMPKERNELDIR
fi
if [  -e $TUFSBOXDIR/release_neutrino ]; then
	echo "Preparing Neutrino..."
	$SCRIPTDIR/prepare_root_neutrino.sh $CURDIR $TUFSBOXDIR/release_neutrino $TMPROOTDIR $TMPKERNELDIR
fi
echo "Root prepared"
echo "-----------------------------------------------------------------------"
echo "Creating flash image..."
$SCRIPTDIR/flash_part_w_fw.sh $CURDIR $TUFSBOXDIR $OUTDIR $TMPKERNELDIR $TMPROOTDIR
echo "-----------------------------------------------------------------------"
AUDIOELFSIZE=`stat -c %s $TMPROOTDIR/lib/firmware/audio.elf`
if [ "$AUDIOELFSIZE" == "0" -o "$AUDIOELFSIZE" == "" ]; then
  echo -e "\033[01;31m"
  echo "!!! WARNING: AUDIOELF SIZE IS ZERO OR MISSING !!!"
  echo "IF YOUR ARE CREATING THE FW PART MAKE SURE THAT YOU USE CORRECT ELFS"
  echo  "-----------------------------------------------------------------------"
  echo -e "\033[00m"
fi
VIDEOELFSIZE=`stat -c %s $TMPROOTDIR/lib/firmware/video.elf`
if [ "$VIDEOELFSIZE" == "0" -o "$VIDEOELFSIZE" == "" ]; then
  echo -e "\033[01;31m"
  echo "!!! WARNING: VIDEOELF SIZE IS ZERO OR MISSING !!!"
  echo "IF YOUR ARE CREATING THE FW PART MAKE SURE THAT YOU USE CORRECT ELFS"
  echo  "-----------------------------------------------------------------------"
  echo -e "\033[00m"
fi
if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
  echo -e "\033[01;31m"
  echo "!!! WARNING: DEVS ARE MISSING !!!"
  echo "IF YOUR ARE CREATING THE ROOT PART MAKE SURE THAT YOU USE A CORRECT DEV.TAR"
  echo "-----------------------------------------------------------------------"
  echo -e "\033[00m"
fi

echo ""
echo ""
echo ""
echo "-----------------------------------------------------------------------"
echo "Flashimage created:"
ls -o $OUTDIR | awk -F " " '{print $7}'

echo "-----------------------------------------------------------------------"
echo "To flash the created image rename the *.img file to e2jffs2.img and "
echo "copy it and the uImage to the enigma2 folder (/enigma2) of your usb drive."
echo "Before flashing make sure that enigma2 is the default system on your box."
echo "To set enigma2 as your default system press OK for 5 sec on your box "
echo "while the box is starting. As soon as \"FoYc\" is being displayed press"
echo "DOWN (v) on your box to select \"ENIG\" and press OK to confirm"
echo "To start the flashing process press OK for 5 sec on your box "
echo "while the box is starting. As soon as \"Fact\" is being displayed press"
echo "RIGHT (->) on your box to start the update"
echo ""
