#!/bin/bash
FILE="/etc/netplan/50-cloud-init.yaml"
IPPRE=$(shuf -i 30-254 -n 1)
HSPRE=$(shuf -i 1-200 -n 1)
read -p "Please enter your new IP address [ default: 192.168.56.${IPPRE} ]:" IP
read -p "Please enter your new prefix [ default: 24 ]:" PREFIX
read -p "Please input your new hostname [ default: new${HSPRE} ]" HS
IP=${IP:=192.168.56.${IPPRE}}
PREFIX=${PREFIX:=24}
HS=${HS:=new${HSPRE}}
echo "Backuping current file to ${FILE}.bak"
cp -a ${FILE} ${FILE}.bak
sed -i -E "s|(addresses:.+)192.168.56.11/24(])|\1${IP}/${PREFIX}\2|" $FILE
test $? -eq 0 && hostnamectl set-hostname $HS
if [ $? -eq 0 ]
then
    echo "Provision completed, please reboot your server."
else
    echo "Provision failed! Reverting to the backup file."
    rm -f ${FILE}
    mv ${FILE}.bak ${FILE}
fi
