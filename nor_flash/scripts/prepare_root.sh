#!/bin/bash

CURDIR=$1
RELEASEDIR=$2

TMPROOTDIR=$3
TMPSTORAGEDIR=$4
TMPKERNELDIR=$5

find $RELEASEDIR -mindepth 1 -maxdepth 1 -exec cp -at$TMPROOTDIR -- {} +

if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
	cd $TMPROOTDIR/dev/
	if [ -e $TMPROOTDIR/var/etc/init.d/makedev ]; then
		$TMPROOTDIR/var/etc/init.d/makedev start
	else
		$TMPROOTDIR/etc/init.d/makedev start
	fi
	cd -
fi

# --- BOOT ---
mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage
rm -fr $TMPROOTDIR/boot

# --- VAR ---
mv $TMPROOTDIR/var/* $TMPSTORAGEDIR/

# mini-rcS and inittab
rm -f $TMPROOTDIR/etc
mkdir -p $TMPROOTDIR/etc/init.d
echo "#!/bin/sh" > $TMPROOTDIR/etc/init.d/rcS
echo "mount -n -t proc proc /proc" >> $TMPROOTDIR/etc/init.d/rcS
echo "mount -t jffs2 -o rw,noatime,nodiratime /dev/mtdblock3 /var" >> $TMPROOTDIR/etc/init.d/rcS
echo "mount --bind /var/etc /etc" >> $TMPROOTDIR/etc/init.d/rcS
echo "/etc/init.d/rcS &" >> $TMPROOTDIR/etc/init.d/rcS
chmod 755 $TMPROOTDIR/etc/init.d/rcS
cp -f $TMPSTORAGEDIR/etc/inittab $TMPROOTDIR/etc
