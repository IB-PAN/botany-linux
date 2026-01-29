#!/bin/bash

mkdir -p computer_infos/"$HOSTNAME"

#cat /proc/cpuinfo | grep -F 'model name' | head -n1 | awk -F':' '{$2 = gensub(/^[ \t]*|[ \t]*$/,"","g",$2); print $2}' > computer_infos/"$HOSTNAME"/cpu.txt
cat /proc/cpuinfo > computer_infos/"$HOSTNAME"/cpuinfo.txt
lshw -C display > computer_infos/"$HOSTNAME"/gpu.txt
lshw > computer_infos/"$HOSTNAME"/lshw.txt
dmidecode > computer_infos/"$HOSTNAME"/dmidecode.txt
dmidecode -t 2 -q > computer_infos/"$HOSTNAME"/motherboard.txt
dmidecode -t 1 -q > computer_infos/"$HOSTNAME"/system_information.txt
#dmidecode -s system-serial-number > computer_infos/"$HOSTNAME"/system_serial_number.txt
dmidecode -t 1 -q | grep -P '(^[^\s].+$|Serial Number:)' > computer_infos/"$HOSTNAME"/system_serial_number.txt
dmidecode -t 2 -q | grep -P '(^[^\s].+$|Serial Number:)' >> computer_infos/"$HOSTNAME"/system_serial_number.txt
dmidecode -t 3 -q | grep -P '(^[^\s].+$|Serial Number:)' >> computer_infos/"$HOSTNAME"/system_serial_number.txt
dmidecode -t memory -q > computer_infos/"$HOSTNAME"/memory.txt
ip address > computer_infos/"$HOSTNAME"/ip.txt
hostnamectl > computer_infos/"$HOSTNAME"/hostname.txt
