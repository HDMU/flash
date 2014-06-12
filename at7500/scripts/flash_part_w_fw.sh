#!/bin/bash
#
# Note: for HS8200 with loader 6.00!
# (concatenated partitions version)

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4
TMPROOTDIR=$5
TMPDUMDIR=$6
RESELLERID=$7

#echo "CURDIR       = $CURDIR"
#echo "TUFSBOXDIR   = $TUFSBOXDIR"
#echo "OUTDIR       = $OUTDIR"
#echo "TMPKERNELDIR = $TMPKERNELDIR"
#echo "TMPROOTDIR   = $TMPROOTDIR"
#echo "TMPDUMDIR    = $TMPDUMDIR"
#echo "RESELLERID   = $RESELLERID"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
MKSQUASHFS=$CURDIR/../common/mksquashfs3.3
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad
FUP=$CURDIR/fup

OUTFILE=HS8200_L600_enigma2_flash_R$RESELLERID.ird

if [ -e $OUTDIR/$OUTFILE ]; then
  rm -f $OUTDIR/$OUTFILE
fi

# mtd-layout after flashing:
#	 .name   = "Boot_firmware", //mtd0
#	 .size   = 0x00060000,  //384k
#	 .offset = 0x00000000,
#
#	 .name   = "kernel",    //mtd1
#	 .size   = 0x000320000, //3.125M
#	 .offset = 0x000060000, //384k (0.375M)
#
#	 .name   = "ROOT_FS",   //mtd2
#	 .size   = 0x00020000,  //128k (dummy)
#	 .offset = 0x00380000,  //3.5M
#
#	 .name   = "Device",    //mtd3
#	 .size   = 0x00020000,  //128k (dummy)
#	 .offset = 0x003A0000,  //3.625M
#
#	 .name   = "APP",       //mtd4
#	 .size   = 0x00020000,	//128k (dummy)
#	 .offset = 0x003C0000,  //3.75M
#
#	 .name   = "Real_ROOT", //mtd5
#	 .size   = 0x01D00000,	//29Mbyte, 128k hole at 0x2FE0000 is used for force flash
#	 .offset = 0x003E0000,	//3.875M
#
#	 .name   = "Config",    //mtd6
#	 .size   = 0x00100000,  //1M
#	 .offset = 0x02100000,
#
#	 .name   = "User",      //mtd7
#	 .size   = 0x01E00000,  //30M
#	 .offset = 0x02200000,
#
# mtd-layout after partition concatenating:
#	 .name   = "Boot_firmware", //mtd0
#	 .size   = 0x00060000,	//384k (0.375M)
#	 .offset = 0x00000000,
#
#	 .name   = "Kernel",    //mtd1
#	 .size   = 0x00320000,	//3.125M
#	 .offset = 0x00060000,  //0.375M
#
#	 .name   = "Fake_ROOT", //mdt2
#	 .size   = 0x0001FFFE,	//128k (dummy) minus 1 word to force read only mount
#	 .offset = 0x00380000,  //4M - 128k force flash hole - 128k Fake_APP - 128k Fake_DEV - 128k own size
#
#	 .name   = "Fake_DEV",  //mtd3
#	 .size   = 0x0001FFFE,	//128k (dummy) minus 1 word to force read only mount
#	 .offset = 0x003A0000,  //4M - 128k force flash hole - 128k Fake_APP - 128k own size
#
#	 .name   = "Fake_APP",  //mtd4
#	 .size   = 0x0001FFFE,	//128k (dummy) minus 1 word to force read only mount
#	 .offset = 0x003C0000,  //4M - 128k force flash hole - 128k own size
#
#	 .name   = "Real_ROOT", //mtd5
#	 .size   = 0x03C00000,	//60M
#	 .offset = 0x003E0000,  //4M - 128k force flash hole

echo "-----------------------------------------------------------------------------"
echo "Prepare kernel file..."
# Note: padding the kernel to set start offset of type 8 (root) does not work;
# boot loader always uses the actual kernel size (at offset 0x0c?) to find/check
# the root.
# CAUTION for a known problem: a kernel with a size that is an exact multiple
# 0x20000 bytes cannot be flashed, due to a bug in the loader.
# This condition is tested for in this script later on.
cp $TMPKERNELDIR/uImage $CURDIR/uImage
echo "-----------------------------------------------------------------------------"
echo "Checking kernel size..."
SIZEK=`stat $CURDIR/uImage -t --format %s`
SIZEKD=`printf "%d" $SIZEK`
SIZEKH=`printf "%08X" $SIZEK`
if [[ $SIZEKD < "1048577" ]]; then
  echo -e "\033[01;31m"
  echo "Kernel is smaller than 1 Mbyte." > /dev/stderr
  echo "Are you sure this is correct?" > /dev/stderr
  echo -e "\033[00m"
  echo "Exiting..."
  exit
fi
if [[ $SIZEKD > "3276799" ]]; then
  echo -e "\033[01;31m"
  echo "KERNEL TOO BIG: 0x$SIZEKH instead of max. 0x0031FFFF bytes" > /dev/stderr
  echo -e "\033[00m"
  echo "Exiting..."
  exit
else
  echo "KERNEL size is: $SIZEKD (0x$SIZEKH, max. 0x0031FFFF) bytes"
fi

# Note: fake root size is adjusted so that the type 7 partition is always flashed at 0x3A0000.
# This in turn will always flash the real root starting at 0x3E0000 (0x3C0000 + squashfs dummy)
# Determine fake root size
if [[ $SIZEKD < "3276800" ]] && [[ $SIZEKD > "3145728" ]]; then
  FAKESIZE="196385"
else
  FAKESIZE="999" #used to flag illegal kernel size
fi
if [[ $SIZEKD < "3145728" ]] && [[ $SIZEKD > "3014656" ]]; then
  FAKESIZE="196385"
fi
if [[ $SIZEKD < "3014656" ]] && [[ $SIZEKD > "2883584" ]]; then
  FAKESIZE="327455"
fi
if [[ $SIZEKD < "2883584" ]] && [[ $SIZEKD > "2752512" ]]; then
  FAKESIZE="458527"
fi
if [[ $SIZEKD < "2752512" ]] && [[ $SIZEKD > "2621440" ]]; then
  FAKESIZE="589599"
fi
if [[ $SIZEKD < "2621440" ]] && [[ $SIZEKD > "2490368" ]]; then
  FAKESIZE="720670"
fi
if [[ $SIZEKD < "2490368" ]] && [[ $SIZEKD > "2359296" ]]; then
  FAKESIZE="851741"
fi
if [[ $SIZEKD < "2359296" ]] && [[ $SIZEKD > "2228224" ]]; then
  FAKESIZE="982810"
fi
if [[ $SIZEKD < "2228224" ]] && [[ $SIZEKD > "2097152" ]]; then
  FAKESIZE="1113881"
fi
if [[ $SIZEKD < "2097152" ]] && [[ $SIZEKD > "1966080" ]]; then
  FAKESIZE="1244953"
fi
if [[ $SIZEKD < "1966080" ]] && [[ $SIZEKD > "1835008" ]]; then
  FAKESIZE="1376025"
fi
if [[ $SIZEKD < "1835008" ]] && [[ $SIZEKD > "1703936" ]]; then
  FAKESIZE="1507097"
fi
if [[ $SIZEKD < "1703936" ]] && [[ $SIZEKD > "1572864" ]]; then
  FAKESIZE="1638169"
fi
if [[ $SIZEKD < "1572864" ]] && [[ $SIZEKD > "1441792" ]]; then
  FAKESIZE="1769241"
fi
if [[ $SIZEKD < "1441792" ]] && [[ $SIZEKD > "1310720" ]]; then
  FAKESIZE="1900314"
fi
if [[ $SIZEKD < "1310720" ]] && [[ $SIZEKD > "1179650" ]]; then
  FAKESIZE="2031386"
fi
if [[ $SIZEKD < "1179648" ]] && [[ $SIZEKD > "1048576" ]]; then
  FAKESIZE="2162458"
fi
if [[ "$FAKESIZE" == "999" ]]; then
  echo -e "\033[01;31m"
  echo "This kernel cannot be flashed, due to its size being" > /dev/stderr
  echo "an exact multiple of 0x20000. This is a limitation of" > /dev/stderr
  echo "bootloader 6.00." > /dev/stderr
  echo "Rebuild the kernel by changing the configuration." > /dev/stderr
  echo -e "\033[00m"
  echo "Exiting..."
  exit
fi

echo "-----------------------------------------------------------------------------"
echo "Create dummy root squashfs 3.3 partition..."
# Create a dummy squashfs 3.3 partition for root, type 8 (Fake_ROOT)
if [ ! -e $CURDIR/seedfile ]; then
 dd if=/dev/urandom count=3538943 bs=1 of=$CURDIR/seedfile bs=1 skip=0 > /dev/null
fi
echo "dd if=./seedfile of=./tmp/DUMMY/dummy bs=1 skip=0 count=$FAKESIZE"
dd if=$CURDIR/seedfile of=$TMPDUMDIR/dummy bs=1 skip=0 count=$FAKESIZE > /dev/null
echo "MKSQUASHFS $TMPDUMDIR ./mtd_fakeroot.bin -nopad -le"
$MKSQUASHFS $TMPDUMDIR $CURDIR/mtd_fakeroot.bin -nopad -le > /dev/null
# Sign partition
$FUP -s $CURDIR/mtd_fakeroot.bin > /dev/null

echo "-----------------------------------------------------------------------------"
echo "Create dummy dev squashfs 3.3 partition..."
# Create a dummy squash partition for dev, type 7 (Fake_DEV)
echo "#!/bin/bash" > $TMPDUMDIR/dummy
echo "exit" >> $TMPDUMDIR/dummy
chmod 755 $TMPDUMDIR/dummy > /dev/null
echo "MKSQUASHFS $TMPDUMDIR ./mtd_fakedev.bin -nopad -le"
$MKSQUASHFS $TMPDUMDIR $CURDIR/mtd_fakedev.bin -nopad -le > /dev/null
# Sign partition
$FUP -s $CURDIR/mtd_fakedev.bin > /dev/null

echo "-----------------------------------------------------------------------------"
echo "Prepare entire root..."
# Create a jffs2 partition for the complete root
echo "MKFSJFFS2 -qUfl -e 0x20000 -r $TMPROOTDIR -o ./mtd_root.bin"
$MKFSJFFS2 -qUfl -e 0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin
echo "SUMTOOL -p -l -e 0x20000 -i ./mtd_root.bin -o ./mtd_root.sum"
$SUMTOOL -p -l -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum > /dev/null
# Padding the root up maximum size is required to force JFFS2 to find
# only erased flash blocks after the root on the initial kernel run.
echo "PAD 0x3C00000 ./mtd_root.sum ./mtd_root.pad"
$PAD 0x3C00000 $CURDIR/mtd_root.sum $CURDIR/mtd_root.pad
echo "-----------------------------------------------------------------------------"
echo "Checking root size..."
SIZE=`stat mtd_root.sum -t --format %s`
SIZEH=`printf "%08X" $SIZE`
SIZED=`printf "%d" $SIZE`
if [[ $SIZED > "62914560" ]]; then
  echo -e "\033[01;31m"
  echo "ROOT TOO BIG: 0x$SIZEH instead of 0x03C00000 bytes" > /dev/stderr
  echo -e "\033[00m"
  echo "Exiting..."
  exit
else
  echo "ROOT size is OK: $SIZED (0x$SIZEH, max. 0x3C00000) bytes"
fi

echo "-----------------------------------------------------------------------------"
echo "Split root into flash parts (one, app)..."
# Root part one size is 0x1D00000, partition type 1 (Fake_APP, extending into Real_ROOT)
# 
echo "dd if=./mtd_root.pad of=./mtd_root.bin bs=0x10000 skip=0x0000 count=0x01D0"
dd if=$CURDIR/mtd_root.pad of=$CURDIR/mtd_root.1.bin bs=65536 skip=0 count=464 > /dev/null
# Sign partition by preceding it with a squashfs dummy (will be flashed at 0x3C0000,
# real root starts at 0x3E0000)
cat $CURDIR/dummy.squash.signed.padded > $CURDIR/mtd_root.1.signed
cat $CURDIR/mtd_root.1.bin >> $CURDIR/mtd_root.1.signed
# Add some bytes to enforce flashing (will expand the file to 0x1D40000 bytes when flashed)
echo "Added to force flashing this partition." >> $CURDIR/mtd_root.1.signed

echo "-----------------------------------------------------------------------------"
echo "Split root into flash parts (two, config)..."
# Root part two, size 0x100000, partition type 2 (Config 0)
echo "dd if=./mtd_root.pad of=./mtd_config.bin bs=0x10000 skip=0x01D0 count=0x10"
dd if=$CURDIR/mtd_root.pad of=$CURDIR/mtd_config.bin bs=65536 skip=464 count=16 > /dev/null

echo "-----------------------------------------------------------------------------"
echo "Split root into flash parts (three, user)..."
# Root part three, max. size 0x1E00000, partition type 9 (User)
echo "dd if=$CURDIR/mtd_root.pad of=$CURDIR/mtd_user.bin bs=0x010000 skip=0x01E0 count=0x01E0"
dd if=$CURDIR/mtd_root.pad of=$CURDIR/mtd_user.bin bs=65536 skip=480 count=480 > /dev/null

echo "-----------------------------------------------------------------------"
echo "File sizes OK, creating IRD file..."
echo "FUP -c $OUTFILE -6 ./uImage -8 ./mtd_fakeroot.bin.signed -7 ./mtd_fakedev.bin.signed -1 ./mtd_root.1.signed -2 ./mtd_config.bin -9 ./mtd_user.bin"
$FUP -c $OUTDIR/$OUTFILE -6 $CURDIR/uImage -8 $CURDIR/mtd_fakeroot.bin.signed -7 $CURDIR/mtd_fakedev.bin.signed -1 $CURDIR/mtd_root.1.signed -2 $CURDIR/mtd_config.bin -9 $CURDIR/mtd_user.bin
# Set reseller ID
$FUP -r $OUTDIR/$OUTFILE $RESELLERID

echo "-----------------------------------------------------------------------------"
echo ""
echo "Preparation of full image flash file completed."
rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_fakeroot.bin
rm -f $CURDIR/mtd_fakeroot.bin.signed
rm -f $CURDIR/mtd_fakedev.bin
rm -f $CURDIR/mtd_fakedev.bin.signed
rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_root.sum
rm -f $CURDIR/mtd_root.pad
rm -f $CURDIR/mtd_root.1.bin
rm -f $CURDIR/mtd_root.1.signed
rm -f $CURDIR/mtd_config.bin
rm -f $CURDIR/mtd_user.bin

#zip $OUTDIR/$OUTFILE.zip $OUTDIR/$OUTFILE
