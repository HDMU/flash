#!/bin/bash

CURDIR=$1
RELEASEDIR=$2
TMPROOTDIR=$3
TMPKERNELDIR=$4
OWNLANG=$5
OWNCOUNTRY=$6

echo "Copying release image..."
cp -a $RELEASEDIR/* $TMPROOTDIR

cd $TMPROOTDIR/dev/
$TMPROOTDIR/etc/init.d/makedev start
cd - > /dev/null

echo "Move kernel..."
mv $TMPROOTDIR/boot/uImage $TMPKERNELDIR/uImage

echo "Strip Root..."
# Language support: remove everything but English, German and own language
mv $TMPROOTDIR/usr/local/share/enigma2/po $TMPROOTDIR/usr/local/share/enigma2/po.old
mkdir $TMPROOTDIR/usr/local/share/enigma2/po
cp -r $TMPROOTDIR/usr/local/share/enigma2/po.old/en $TMPROOTDIR/usr/local/share/enigma2/po
cp -r $TMPROOTDIR/usr/local/share/enigma2/po.old/de $TMPROOTDIR/usr/local/share/enigma2/po
# Add own language if given
if [[ ! "$OWNLANG" == "" ]]; then
  cp -r $TMPROOTDIR/usr/local/share/enigma2/po.old/$OWNLANG $TMPROOTDIR/usr/local/share/enigma2/po
fi
sudo rm -rf $TMPROOTDIR/usr/local/share/enigma2/po.old

#mv $TMPROOTDIR/usr/local/share/enigma2/countries $TMPROOTDIR/usr/local/share/enigma2/countries.old
#mkdir $TMPROOTDIR/usr/local/share/enigma2/countries
#cp -r $TMPROOTDIR/usr/local/share/enigma2/countries.old/missing.* $TMPROOTDIR/usr/local/share/enigma2/countries
#cp -r $TMPROOTDIR/usr/local/share/enigma2/countries.old/en.* $TMPROOTDIR/usr/local/share/enigma2/countries
#cp -r $TMPROOTDIR/usr/local/share/enigma2/countries.old/de.* $TMPROOTDIR/usr/local/share/enigma2/countries
#if [[ ! "$OWNLANG" == "" ]]; then
#  cp -r $TMPROOTDIR/usr/local/share/enigma2/countries.old/$OWNLANG.* $TMPROOTDIR/usr/local/share/enigma2/countries
#fi
#sudo rm -rf $TMPROOTDIR/usr/local/share/enigma2/countries.old

# Update /usr/lib/enigma2/python/Components/Language.py
# First remove all language lines from it
#sed -i -e '/\t\tself.addLanguage(/d' $TMPROOTDIR/usr/lib/enigma2/python/Components/Language.py
# Add en and ge
#sed -i "s/country!/&\n\t\tself.addLanguage(\"Deutsch\",     \"de\", \"DE\")\n\t\tself.addLanguage(\"English\",     \"en\", \"EN\")/g" $TMPROOTDIR/usr/lib/enigma2/python/Components/Language.py
# Add own language if given
#if [[ ! "$OWNLANG" == "" ]]; then
 # sed -i 's/("English",     "en", "EN")/&\n\t\tself.addLanguage(\"Your own\",    \"'$OWNLANG'", \"'$OWNCOUNTRY'\")/g' $TMPROOTDIR/usr/lib/enigma2/python/Components/Language.py
#fi
#rm $TMPROOTDIR/usr/lib/enigma2/python/Components/Language.pyo
# Compile Language.py
#python -O -m py_compile $TMPROOTDIR/usr/lib/enigma2/python/Components/Language.py


# we need libav files
#if [ -d $TMPROOTDIR/usr/lib/gstreamer-0.10 ]; then
#  rm -f $TMPROOTDIR/usr/lib/libav*
#fi

#remove all .py-files
find $TMPROOTDIR/usr/lib/ -name '*.pyc' -exec rm {} \;
find $TMPROOTDIR/usr/lib/ -not -name 'mytest.py' -name '*.py' -exec rm -f {} \;
