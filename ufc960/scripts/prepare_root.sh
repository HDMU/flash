#!/bin/bash

CURDIR=$1
RELEASEDIR=$2

TMPROOTDIR=$3
TMPSTORAGEDIR=$4
TMPKERNELDIR=$5

find $RELEASEDIR -mindepth 1 -maxdepth 1 -exec cp -at$TMPROOTDIR -- {} +

cd $TMPROOTDIR/dev/
$TMPROOTDIR/etc/init.d/makedev start
cd -

mkdir $TMPROOTDIR/root_rw
mkdir $TMPROOTDIR/storage
cp ../common/init_mini_fo $TMPROOTDIR/sbin/
chmod 777 $TMPROOTDIR/sbin/init_mini_fo

# --- BOOT ---
mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage

# --- STORAGE FOR MINI_FO ---
mkdir $TMPSTORAGEDIR/root_ro

#TODO: We need to strip the ROOT further as there is no chance that this will fit into the flash at the moment !!!
