########################################################
#              HPPTD Instance Checker                  #
# Desc: Check whether the httpd is running or not, and #
#       drop an email to inform the administrator.     #
# Author: Neil Wang                                    #
# Date: 2017-02-20                                     #
# Ver: 0.1                                             #
########################################################

#!/bin/bash
SYSTEMCTL="/bin/systemctl"
STATUS=""
SUBJECT=""
SFILE=""

send_mail (){
    (
    echo "From: AWS Monitoring Agency <monitor@XXX.XXX>";
    echo "To: XXX@XXX.XXX"; 
    echo "Subject: $SUBJECT";
    echo "Mime-Version: 1.0";
    echo "Content-Type: text/html; charset=ISO-8859-1";
    echo "Content-Transfer-Encoding: 7bit";
    echo "Content-Disposition: inline";
    echo "<html>";
    echo "<body>";
    echo "<pre style="font: Arial">";
	${SYSTEMCTL} status httpd
	) | /usr/sbin/sendmail -t
}

if [ -f /tmp/httpd_status_ok ]
then
	SFILE=1
else
	SFILE=0
fi

STATUS=`${SYSTEMCTL} status httpd | grep running | grep -v grep`
if [ -n "$STATUS" ]
then
	if [ "$SFILE" == 0 ]
	then
		SUBJECT="Normal: Apache httpd is running."
		touch /tmp/httpd_status_ok
		send_mail
	fi
else
	SUBJECT="Critical: Apache httpd is dead!"
	rm -rf /tmp/httpd_status_ok
	send_mail
fi
