
#include <stdint.h>

#include "crc16.h"

/*
 * CRC table for the CRC-16. The poly is 0x8005 (x^16 + x^15 + x^2 + 1) 
 */
static const uint16_t crc16_table[256] = {
	0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
	0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
	0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
	0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
	0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
	0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
	0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
	0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
	0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
	0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
	0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
	0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
	0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
	0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
	0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
	0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
	0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
	0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
	0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
	0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
	0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
	0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
	0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
	0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
	0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
	0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
	0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
	0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
	0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
	0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
	0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
	0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040
};

/*
 * crc16_byte - compute the CRC-16 for a byte
 * @crc:	previous CRC value
 * @data: 	byte value
 */
static inline uint16_t crc16_byte(uint16_t crc, const uint8_t data)
{
	return (crc >> 8) ^ crc16_table[(crc ^ data) & 0xff];
}

/*
 * crc16 - compute the CRC-16 for the data buffer
 * @crc:	previous CRC value
 * @buffer:	data pointer
 * @len:	number of bytes in the buffer
 *
 * Returns the updated CRC value.
 */
uint16_t crc16(uint16_t crc, const uint8_t *buffer, uint32_t len)
{
	while (len--)
		crc = crc16_byte(crc, *buffer++);
	return crc;
}

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
SCRIPTDIR=$CURDIR/scripts_L600
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

