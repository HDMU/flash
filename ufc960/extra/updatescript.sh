cmd=VFD=flash update
cmd=sleep 2
cmd=VFD=loading Image
cmd=usb reset; fatload usb 0:1 a4040000 /kathrein/ufc960/update.img
cmd=sleep 1
cmd=protect off a0040000 a0ffffff
cmd=VFD=erase wait 3 min
cmd=erase a0040000 a0ffffff
cmd=VFD=flash wait 6 min
cmd=sleep 1
cmd=cp.b a4040000 a0040000 fc0000
cmd=sleep 1
cmd=set bootargs
cmd=set ipaddr 192.168.2.215
cmd=set serverip 192.168.2.1
cmd=set gateway 192.168.2.1
cmd=set netmask 255.255.255.0
cmd=set bootargs ''console=ttyAS0,115200 root=/dev/mtdblock2 ro ip=${ipaddr}:${serverip}:${gateway}:${netmask}:kathrein:eth0:off mem=128m init=/bin/devinit coprocessor_mem=4m@0x10000000,4m@0x10400000''
cmd=set bootcmd 'bootm a0040000'
cmd=saveenv
cmd=crc32 a0040000 fc0000
cmd=crc32 a4040000 fc0000
cmd=VFD=ready to go
cmd=sleep 2
cmd=reset
cmd=EOF
