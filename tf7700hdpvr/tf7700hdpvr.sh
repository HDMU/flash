#!/bin/bash
if [ `id -u` = 0 ]; then
	echo "Do not run this script as root. Try it again without su/sudo command."
	echo "Bye Bye..."
	exit
fi

CURDIR=`pwd`
BASEDIR=$CURDIR/../..

TUFSBOXDIR=$BASEDIR/tufsbox
CDKDIR=$BASEDIR/cvs/cdk
TFINSTALLERDIR=$CDKDIR/tfinstaller

mkdir -p $CURDIR/out
rm -rf $CURDIR/out/*
cp $TFINSTALLERDIR/Enigma_Installer.ini $CURDIR/out/
cp $TFINSTALLERDIR/Enigma_Installer.tfd $CURDIR/out/
cp $TFINSTALLERDIR/uImage $CURDIR/out/

cd $TUFSBOXDIR/release_neutrino/
tar -cvzf $CURDIR/out/rootfs.tar.gz *
cd -

echo "REMEMBER THAT AUDIO.ELF and VIDEO.ELF have to exist"
