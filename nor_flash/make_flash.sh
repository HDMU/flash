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
TMPSTORAGEDIR=$TMPDIR/STORAGE

OUTDIR=$CURDIR/out

if [ -e $TMPDIR ]; then
	rm -rf $TMPDIR/*
fi

mkdir -p $TMPDIR
mkdir -p $TMPROOTDIR
mkdir -p $TMPKERNELDIR
mkdir -p $TMPSTORAGEDIR

echo "This script creates flashable images for NOR flash receivers."
echo "Author: Schischu, Oxygen-1, BPanther, TangoCash, Grabber66"
echo "Last Change: 05-05-2013"
echo "Changed for \"classic flash\" (no mini_fo) for UFS910 and add more receivers by BPanther, 13-Feb-2013."
echo ""
echo "Supported receivers (autoselection) are:"
echo "UFS910, UFS922, Octagon1008, Fortis HDBox, Cuberevo MINI2, Cuberevo, Cuberevo 2000HD"
echo "-----------------------------------------------------------------------"
echo "It's expected that an image was already build prior to this execution!"
echo "-----------------------------------------------------------------------"

$BASEDIR/flash/common/common.sh $BASEDIR/flash/common/

echo "-----------------------------------------------------------------------"
echo "Checking targets..."
echo "Found targets:"
if [  -e $TUFSBOXDIR/release ]; then
	echo "Preparing Enigma2..."
	$SCRIPTDIR/prepare_root.sh $CURDIR $TUFSBOXDIR/release $TMPROOTDIR $TMPSTORAGEDIR $TMPKERNELDIR
fi
if [  -e $TUFSBOXDIR/release_neutrino ]; then
	echo "Preparing Neutrino..."
	$SCRIPTDIR/prepare_root_neutrino.sh $CURDIR $TUFSBOXDIR/release_neutrino $TMPROOTDIR $TMPSTORAGEDIR $TMPKERNELDIR
fi
echo "Root prepared"
echo ""
echo "You can customize your image now (i.e. move files you like from ROOT to STORAGE)."
echo "Or insert your changes into scripts/customize.sh"
$SCRIPTDIR/customize.sh $CURDIR $TMPROOTDIR $TMPSTORAGEDIR $TMPKERNELDIR
echo "-----------------------------------------------------------------------"
echo "Creating flash image..."
$SCRIPTDIR/flash_part_w_fw.sh $CURDIR $TUFSBOXDIR $OUTDIR $TMPKERNELDIR $TMPROOTDIR $TMPSTORAGEDIR
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
echo "UFS910: To flash the created image rename the *.img file to miniFLASH.img"
echo "        and copy it to the root (/) of your usb drive."
echo "        To start the flashing process press RECORD for 10 sec on your"
echo "        remote control while the box is starting."
echo ""
echo "MINI2:  To flash the created image rename the *.img file to usb_update.img"
echo "        and copy it to the root (/) of your usb drive."
echo "        To start the flashing process press POWER for 10 sec on your"
echo "        box while the box is starting."
echo ""
