#!/bin/sh

CURDIR=`pwd`
CDK=$CURDIR/../../cvs/cdk

mv $CDK/Patches/linux-sh4-ufs913_setup_stm24_0209.patch $CDK/Patches/linux-sh4-ufs913_setup_stm24_0209.patch.org
mv $CDK/Patches/linux-sh4-2.6.32.46-0209_ufs913.config.debug $CDK/Patches/linux-sh4-2.6.32.46-0209_ufs913.config.debug.org

cp $CURDIR/extra/linux-sh4-ufs913_setup_stm24_0209.patch $CDK/Patches/linux-sh4-ufs913_setup_stm24_0209.patch
cp $CURDIR/extra/.config $CDK/Patches/linux-sh4-2.6.32.46-0209_ufs913.config.debug

rm $CDK/.deps/linux-kernel
rm $CDK/.deps/linux-kernel.do_*

cd $CDK
make linux-kernel
cp $CDK/linux-sh4-2.6.32.46_stm24_0209/arch/sh/boot/uImage.gz $CURDIR/extra/uImage_rootmtd7
cd $CURDIR

rm $CDK/Patches/linux-sh4-ufs913_setup_stm24_0209.patch
rm $CDK/Patches/linux-sh4-2.6.32.46-0209_ufs913.config.debug
mv $CDK/Patches/linux-sh4-ufs913_setup_stm24_0209.patch.org $CDK/Patches/linux-sh4-ufs913_setup_stm24_0209.patch
mv $CDK/Patches/linux-sh4-2.6.32.46-0209_ufs913.config.debug.org $CDK/Patches/linux-sh4-2.6.32.46-0209_ufs913.config.debug
