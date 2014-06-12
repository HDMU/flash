#!/bin/bash
clear
echo "-----------------------------------------------------------------------"
echo "This script creates flashable images for Fortis HS8200 receivers with"
echo "loader 6.00. Default reseller ID is for the Octagon SF1028P Noblence."
echo "Other versions of the HS8200 are supported by supplying their 4 byte"
echo "reseller ID in hex on the command line (requires fup 1.8 or later)."
echo "Author: Schischu, Audioniek"
echo "Date: 01-31-2011 - 07-04-2014"
echo ""
echo "Usage: $0 [Reseller ID]"
echo "-----------------------------------------------------------------------"
echo ""

if [ `id -u` != 0 ]; then
	echo "You are not running this script as root. Try it again as root or with su/sudo command."
	echo "Bye Bye..."
	exit
fi

CURDIR=`pwd`
BASEDIR=$CURDIR/../..
RESELLERID=$1
# Some reseller ID's for HS8200 models:
# Rebox RE-8500 HD PVR          : 230100A0
# Octagon SF-1028P Noblence     : 230200A0
# Atevio AT7500HD PVR           : 230300A0
#                               : 230400A0
#                               : 230500A0
#                               : 230600A0
# Openbox S9                    : 230700A0
#                               : 230800A0
#                               : 230900A0
# Icecrypt STC6000 HD           : 231000A0
#                               : 231100A0
#                               : 231200A0
#                               : 231300A0
#                               : 231400A0
#                               : 231500A0
#                               : 231600A0
#                               : 232400A0
#                               : 232900A0
# Opticum Actus Duo             : 233100A0 

# Change default reseller ID here
if [[ "$RESELLERID" == "" ]]; then
  echo "No reseller ID specified, using default."
  RESELLERID=230200A0
fi

echo "Using reseller ID $RESELLERID."
echo "-----------------------------------------------------------------------"
echo ""

# The root will be stripped of all language support except de (German) and en (English)
# because the flash space is rather limited on this receiver.
# A third language can be specified here in ISO code (suggestion is your own language,
# two lower case letters):
OWNLANG=nl
# And the country to go with it (ISO code, two uppercase letters, often the same as
# the language):
OWNCOUNTRY=NL

TUFSBOXDIR=$BASEDIR/tufsbox
CDKDIR=$BASEDIR/cdk
$BASEDIR/flash/common/common.sh $BASEDIR/flash/common/
SCRIPTDIR=$CURDIR/scripts
TMPDIR=$CURDIR/tmp
TMPROOTDIR=$TMPDIR/ROOT
TMPKERNELDIR=$TMPDIR/KERNEL
TMPDUMDIR=$CURDIR/tmp/DUMMY
OUTDIR=$CURDIR/out
FUP=$CURDIR/fup

if [ -e $TMPDIR ]; then
  rm -rf $TMPDIR/*
fi

if [ ! -d $TMPDIR ]; then
  mkdir $TMPDIR
fi

if [ ! -e $TMPROOTDIR ]; then
  mkdir $TMPROOTDIR
fi

if [ ! -e $TMPKERNELDIR ]; then
  mkdir $TMPKERNELDIR
fi

if [ ! -e $TMPDUMDIR ]; then
  mkdir $TMPDUMDIR
fi

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

#echo "-----------------------------------------------------------------------"
echo "Checking targets..."
echo "Preparing Enigma2 Root..."
$SCRIPTDIR/prepare_root.sh $CURDIR $TUFSBOXDIR/release $TMPROOTDIR $TMPKERNELDIR $OWNLANG $OWNCOUNTRY
echo "Root prepared."
echo ""

if [ ! -e $FUP ]; then
echo "-----------------------------------------------------------------------"
  echo "Flashtool fup is missing, trying to compile it..."
  cd $CURDIR/../common/fup.src
  $CURDIR/../common/fup.src/compile.sh USE_ZLIB
  mv $CURDIR/../common/fup.src/fup $CURDIR/fup
  cd $CURDIR
  if [ ! -e $CURDIR/fup ]; then
    echo "Compiling failed! Exiting..."
    echo "If the error is \"cannot find -lz\" then you need to install the 32bit version of libz"
    exit 3
  else
    echo "Compiling fup successful."
  fi
fi

if [ ! -e $CURDIR/dummy.squash.signed.padded ]; then
  $FUP > /dev/null
fi

echo "-----------------------------------------------------------------------"
echo "Creating KERNEL with ROOT and FW..."
$SCRIPTDIR/flash_part_w_fw.sh $CURDIR $TUFSBOXDIR $OUTDIR $TMPKERNELDIR $TMPROOTDIR $TMPDUMDIR $RESELLERID

#clear
if [ "$REPLY" == "1" ]; then
  echo "-----------------------------------------------------------------------------"
  AUDIOELFSIZE=`stat -c %s $TMPROOTDIR/boot/audio.elf`
  VIDEOELFSIZE=`stat -c %s $TMPROOTDIR/boot/video.elf`
  if [ $AUDIOELFSIZE == "0" ]; then
    echo -e "\033[01;31m"
    echo "!!! WARNING: FILE SIZE OF AUDIO.ELF IS ZERO !!!"
    echo "MAKE SURE THAT YOU USE CORRECT ELFS."
    echo -e "\033[00m"
    echo "-----------------------------------------------------------------------------"
    exit
  fi
  if [ $VIDEOELFSIZE == "0" ]; then
    echo -e "\033[01;31m"
    echo "!!! WARNING: FILE SIZE OF VIDEO.ELF IS ZERO !!!"
    echo "MAKE SURE THAT YOU USE CORRECT ELFS."
    echo -e "\033[00m"
    echo "-----------------------------------------------------------------------------"
    exit
  fi
  if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
    echo -e "\033[01;31m"
    echo "!!! WARNING: DEVS ARE MISSING !!!"
    echo "APPARENTLY MAKEDEV IN prepare_root.sh FAILED."
    echo -e "\033[00m"
    echo "-----------------------------------------------------------------------------"
    exit
  fi
fi

echo ""
echo ""
echo ""
echo "-----------------------------------------------------------------------"
echo "Flash image file(s) created:"
echo `ls $OUTDIR`

echo "-----------------------------------------------------------------------"
echo "To flash the created image copy the .ird file to an USB stick."
echo ""
echo "Insert the USB stick in any of the box's USB ports, and switch the box"
echo "on using the mains switch while pressing and holding the channel up key"
echo "on the frontpanel. Release the button when the display shows SCAN USB."
echo "Flashing the image will then begin."
echo "On Octagon SF1028P and Icecrypt STC6000 only, use volume up (->)"
echo "instead of channel up."
echo ""

