#!/bin/bash
FIRST=0
NLST="/var/tmp/client_new.lst"
OLST="/var/tmp/client_old.lst"
NODES1="/var/tmp/nodes1.lst"
NODES2="/var/tmp/nodes2.lst"
NODES_FIX="/var/tmp/client_fix.lst"
SEND=0
echo "" > $NODES1
echo "" > $NODES2
echo "" > $NODES_FIX

send_mail (){
    (
    echo "From: AWS TOKYO Agency <monitor@tokyo.aws.com>";
    echo "To: suwwr@hotmail.com";
    echo "Subject: New Activity on Shadowsocks Detected!";
    echo "Mime-Version: 1.0";
    echo "Content-Type: text/html; charset=ISO-8859-1";
    echo "Content-Transfer-Encoding: 7bit";
    echo "Content-Disposition: inline";
    echo "<html>";
    echo "<body>";
    echo "<pre style="font: Arial">";
    echo $TITLE1
    cat ${NODES1}
    echo ""
    echo $TITLE2
    cat ${NODES2}
    echo ""
    printf "%s\n" "${TITLE3[@]}"
    echo "</pre>";
    echo "</body>";
    echo "</html>";
    ) | /usr/sbin/sendmail -t
}

if [ ! -s "$OLST" ]
then
    touch "$OLST"
    FIRST=1
fi
netstat -an | grep 10086 | grep ESTABLISHED | grep -v grep | awk '{print $5}' | awk -F ":" '{print $1}' | sort -nu > $NLST

if [ "$FIRST" = 1 ]
then
    if [ -s "$NLST" ]
    then
        cat $NLST > $NODES1
        TITLE1="Client list initialized on shadowsocks:"
        send_mail
        cp -a $NLST $OLST
        exit $?
    else
        exit $?
    fi
fi

comm -23 <(sort $NLST) <(sort $OLST)  > $NODES1
if [ -s "$NODES1" ]
then
    TITLE1="New client(s) joined in shadowsocks:"
    SEND=1
fi

comm -23 <(sort $NLST) <(sort $NODES1)  > $NODES_FIX
comm -23 <(sort $OLST) <(sort $NODES_FIX)  > $NODES2
if [ -s "$NODES2" ]
then
    TITLE2="Client(s) left from shadowsocks:"
    SEND=1
fi

if [ "$SEND" = 1 ]
then
    TITLE3=("Summary:")
    for i in `cat $NLST`
    do
        TITLE3+=(${i})
    done
    send_mail
fi
cp -a $NLST $OLST
