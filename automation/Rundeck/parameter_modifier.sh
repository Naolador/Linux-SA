#!/bin/bash
##########################################################
#                                                        #
#        Rundeck Job Option Parameter Modifier           #
# Author: Neil Wang                                      #
# Version: 0.1                                           #
# Date:   2015/05/23                                     #
# Description: Change a job option value in Rundeck.     #
#                                                        #
##########################################################

function HELP {
	echo -e \\n "Usage $0 -F FILE -s ScriptFile -n OPTNAME -v VALUE -V VALUES -f FOCE -r REQUIRE -L"\\n
	echo -e "-F Specify the filename (xml format)."
	echo -e "-s Specify the new script file location."
	echo -e "-n Specify the option name."
	echo -e "-v Specify the new option value."
	echo -e "-s Specify the new allowed option values,format: \"v1,v2,v3...\""
	echo -e "-f Force use the value in values list. Set 0 to disable, 1 to enable."
	echo -e "-r Make the option's value is required. Set 0 to disable, 1 to enable."
	echo -e "-L Update the job to Rundeck immediately."\\n
	exit 1
}

if [ $# -eq 0 ]
then
	echo -e \\n "Error, no argument specified!"
	HELP
fi

while getopts :F:n:s:v:V:f:r:Lh ARG
do
	case $ARG in
	F)              #get job file name
		FILE=$OPTARG;;
	n)              #get option name
		NAME="name=\"$OPTARG\"";;
	s)                              #set new script file location
		SCRIPT="$OPTARG";;
	v)              #set new option value
		VALUE="value=\"$OPTARG\"";;
	V)              #set new option values
		VALUES="values=\"$OPTARG\"";;
	f)              #set whether the value is enforcedvalues
		if [ "$OPTARG" -eq 0 ]
		then FORCE="enforcedvalues=\"false\""
			elif [ "$OPTARG" -eq 1 ]
			then FORCE="enforcedvalues=\"true\""
		else echo "Error, invalid option value for -f"
		exit 1
		fi;;
	r)              #set whether the value is required
		if [ "$OPTARG" -eq 0 ]
		then REQUIRE="required=\"false\""
			elif [ "$OPTARG" -eq 1 ]
			then REQUIRE="required=\"true\""
			else echo "Error, invalid option value for -r"
			exit 1
		fi;;
	L)              #Update job now?
		LOAD="1";;
	\?) 
		echo "Error, invalid option!"
		HELP;;
	h)              #print help
		HELP;;
	esac
done

LINE=`cat "$FILE" | grep -n "$NAME" | awk -F : '{print $1}'`
if [[ -z "$LINE" && "$SCRIPT" ]]
then
	echo "Your option name does not exist! Please check your input."; exit 1
	else
	echo "Making backup: $FILE.`date +%Y%m%d`"
cp -a $FILE $FILE.`date +%Y%m%d`
fi
if [ ! -z "$SCRIPT" ]
then
	sed -i "s@<scriptfile>.*@<scriptfile>$SCRIPT</scriptfile>@" $FILE
fi
HAVE_DESCP=`cat "$FILE" | grep -n "$NAME" | grep -o "/>"`
if [ -z "$HAVE_DESCP" ]
then
	DESC=">"
	else
	DESC="/>"
fi
if [ ! -z "$VALUE" ]
then
	VER_V=`cat "$FILE" | grep "$NAME" | grep -w value`
	if [ -z "$VER_V" ]
	then
		echo "No previously value defined, will append one."
		sed -i "${LINE}s@"${DESC}"@ ${VALUE}${DESC}@" "$FILE"
		else
		sed -i "${LINE}s/\bvalue\b=\"[[:alnum:]]\{1,\}\"/${VALUE}/" ${FILE}
	fi
fi
if [ ! -z "$VALUES" ]
then
	VER_VS=`cat "$FILE" | grep "$NAME" | grep -w values`
	if [ -z "$VER_VS" ]
	then
		echo "No previously values defined, will append one."
		sed -i "${LINE}s@"${DESC}"@ ${VALUES}${DESC}@" "$FILE"
	else
		sed -i "${LINE}s/\bvalues\b=\"[[:alnum:],]\{1,\}\"/${VALUES}/" ${FILE}
	fi
fi
if [ ! -z "$FORCE" ]
then    
	VER_F=`cat "$FILE" | grep "$NAME" | grep -w enforcedvalues`
	if [ -z "$VER_F" ]
	then
		echo "No previously force value defined, will append one."
		sed -i "${LINE}s@"${DESC}"@ ${FORCE}${DESC}@" "$FILE"
	else
	sed -i "${LINE}s/\benforcedvalues\b=\"[[:alnum:]]\{1,\}\"/${FORCE}/" ${FILE}
	fi
fi
if [ ! -z "$REQUIRE" ]
then
	VER_R=`cat "$FILE" | grep "$NAME" | grep -w required`
	if [ -z "$VER_R" ]
	then
		echo "No previously require value defined, will append one."
		sed -i "${LINE}s@"${DESC}"@ ${REQUIRE}${DESC}@" "$FILE"
	else
	sed -i "${LINE}s/\brequired\b=\"[[:alnum:]]\{1,\}\"/${REQUIRE}/" ${FILE}
	fi
fi
if [ -n "$LOAD" ]
then
	echo "Updating new job definitions to Rundeck......"
	rd-jobs load -f $FILE;
fi
