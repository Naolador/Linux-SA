########################################################
#              Port Connectivity Checker               #
# Desc: Check whether the port is accessable or not.   #
#       Users can also choose to drop an email when    #
#       it was failed to reach the port.               #
# Author: Neil Wang                                    #
# Date: 2017-03-03                                     #
# Ver: 0.1                                             #
########################################################

#!/bin/bash
DIG=/usr/bin/dig && [ -x "$DIG" ] || DIG=/usr/sbin/dig && [ -x "$DIG" ] || DIG=/bin/dig && [ -x "$DIG" ] || echo "dig is not found! exiting." || exit 3
NC=/usr/bin/nc && [ -x "$NC" ] || NC=/usr/local/bin/nc && [ -x "$NC" ] || NC=/bin/nc && [ -x "$DIG" ] || NC=none

HELP (){
	echo "Usage: $0 [ -r recipient@email.com ] -s ( hostname | ip ) -p port_number"
	echo "	-r:  Send the result through an email when the port was failed, instead of printing on the screen."
	echo "	-s:  Define the FQDN format of hostname or ip address you'd like to check."
	echo "	-p:  Specify the port number you'd like to check."
	exit 1
}
send_mail (){
    (
    echo "From: AWS Monitoring Agency <monitor@`hostname`>";
    echo "To: $RECIPIENT"; 
    echo "Subject: $SUBJECT";
    echo "Mime-Version: 1.0";
    echo "Content-Type: text/html; charset=ISO-8859-1";
    echo "Content-Transfer-Encoding: 7bit";
    echo "Content-Disposition: inline";
    echo "<html>";
    echo "<body>";
    echo "<pre style="font: Arial">";
	echo $CONTENT;
	) | /usr/sbin/sendmail -t
}

while getopts ":r:s:p:" opt;do
	case "$opt" in
	r) RECIPIENT=$OPTARG;;
	s) TARGET=$OPTARG;;
	p) PORT=$OPTARG;;
	h) HELP;;
	\?) HELP;;
	:) echo "Option -$OPTARG requires an argument!" >&2 ;exit 1;;
	esac
done

if [[ $# -eq 0 ]]
then
	echo "This command requires arguments!"
	HELP
fi
if [[ "$TARGET" =~ ^[A-Za-z].* ]]
then
	DOMAIN=`$DIG $TARGET | grep "ANSWER SECTION"`
	if [ -z "$DOMAIN" ]
	then
		if [ -n "$RECIPIENT" ]
		then
			SUBJECT="Critical: Name resolution of $TARGET failed!"
			send_mail
			exit 5
		else
			echo "ERROR: Name resolution failed!"
		exit 5
		fi
	fi
elif [[ "$TARGET" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
then
	:
else
	echo "Invalid hostname/IP format! Please check your input and try again."
	exit 2
fi

echo "Connecting to ${TARGET}:${PORT}..."
if [ "$NC" = none ]
then
	$NC -vw5 $TARGET $PORT > /dev/null
	if [ $? != 0 ]
	then
		if [ -n "$RECIPIENT" ]
		then
			SUBJECT="Critical: Port $PORT on $TARGET is Unreachable!"
			CONTENT="Unable to access ${TARGET}:${PORT}. Please check your network connectivity or server status."
			send_mail
			exit 4
		else
			echo "Failure: Port is blocked!"
			exit 4
		fi
	else
		echo "Success: Port is open."
	fi
elif (:</dev/tcp/${TARGET}/${PORT})2>/dev/null
then
	echo "Success: Port is open."
	elif [ -n "$RECIPIENT" ]
	then
		SUBJECT="Critical: Port $PORT on $TARGET is Unreachable!"
		CONTENT="Unable to access ${TARGET}:${PORT}. Please check your network connectivity or server status."
		send_mail
		exit 4
		else
			echo "Port is blocked!"
			exit 4
fi

