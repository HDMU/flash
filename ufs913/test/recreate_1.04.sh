URL="https://www.kathrein.de/esc-kathrein/data/receiver/ufs-913/"
FILE="ufs913_fw1.04.zip"

FILE_DATA="ufs913.software.V1.04.B39.data"
FILE_DATA_NEW="ufs913.software.V1.04.B39.data.new"

if [ ! -e ${FILE} ]; then
  wget "${URL}/${FILE}"
fi

echo "unzip ${FILE} < echo \"n\""
unzip ${FILE} << EOF
n
EOF

../mup x  ${FILE_DATA} > ${FILE_DATA}.x.xml
../mup xx ${FILE_DATA} > ${FILE_DATA}.xx.xml

../mup v ${FILE_DATA}
echo "This test checks if our checksum calculation routine works correctly"
echo "The line \"Image is correct\" should be displayed"
sleep 4


../mup e ${FILE_DATA}

sudo ../mup c ${FILE_DATA_NEW} << EOF
3
0x00000000, 0x0, 0, u-boot.ufs913.bin
0x000A0000, 0x0, 0, uImage.emergency.ufs913
0x00260000, 0x0, 0, emergency.ufs913
0x00400000, 0x0, 0, uImage.ufs913
0x00660000, 0x0, 0, rootfs.ufs913.cramfs
0x00060000, 0x0, 0, ufs913_mtd1.data
0x02800000, 0x05800000, 2, _0580_5_app.cramfs
;
EOF

../mup x ${FILE_DATA}.new > ${FILE_DATA_NEW}.x.xml
../mup xx ${FILE_DATA}.new > ${FILE_DATA_NEW}.xx.xml

diff -Nu ${FILE_DATA}.x.xml ${FILE_DATA_NEW}.x.xml
