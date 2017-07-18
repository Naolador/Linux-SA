################################################################
#                  Restart/Stop Job Creater                    #
#  Author: Neil Wang                                           #
#  Date: 2015/04/10                                            #
#  Version: 0.1                                                #
#  Description: This script is used to create a resart job     #
#               through the given parameters.                  #
#               e.g.: Create "restart ndc-www1"                #
#                     or "restart ndc-www1 ~ ndc-www50"        #
################################################################

#!/bin/bash

function HELP {
        echo -e \\n"Useage $0 -a APPNAME {-t i -c ndc|edc -s STARTNUM -e ENDNUM}|{-t o -d DIR}"\\n
        echo -e "Use \"-a\" to specify the application name, e.g.: www, ws"
        echo -e "Use \"-c\" to specify the dc side, e.g.: ndc, edc"
        echo -e "Use \"-t i\" to create an individual restart job, e.g.: restart edc-wu1"
        echo -e " You need to use \"-s\" and \"-e\" to give the server range of individual restart job, e.g.: -s 1 -e 10 means create restart jobs for wu1 to wu10."
        echo -e "Use \"-t o\" to create an operational restart job."
        echo -e " You need to use \"-d\" to specify the directory name which server group file resides."\\n
        exit 1
}

while getopts ":a:c:t:s:e:d:h" opt
do
        case $opt in
        a)      #application name
        APP=${OPTARG,,}
        UAPP=${APP^^}
        ;;
        c)      #dc side
        DC=${OPTARG,,};;
        t)
        ACTION=$OPTARG;;
        s)      #start num
        SN=$OPTARG;;
        e)      #end num
        EN=$OPTARG;;
        d)
        DIR=$OPTARG;;
        h)
        HELP;;
        \?)
        echo -e \\n"Invalid Option!"
        HELP;;
        esac
done

if [ $# -eq 0 ]
        then
        echo -e \\n "Error, no argument specified!"
        HELP
fi
if [ -z "$APP" ]
        then
        echo "[ERROR] The application name must be specified!"
        exit 1
fi

if [ "$ACTION" == "i" ]
        then
        if [ -z "$DC" ]
                then
                echo "[ERROR] You must specify the ndc or edc side!"
                exit 1
        fi
        if [ "$SN" -gt "0" ]
                then
                if [ "$EN" -lt "$SN" ]
                        then
                        echo "[ERROR] The end number must equal to or greater than the start number!"
                        exit 1
                fi
                else
                        echo "[ERROR] The start number must be a numerical and greater than 0!"
                        exit 1
        fi
        if [ -d import/individual/$APP ]
                then
                echo "The directory import/individual/$APP already exist, I'll rename it"
                mv import/individual/$APP import/individual/$APP.`date +%Y%m%d%S`
                echo "Creating the directory to store xml files: import/individual/$APP"
                mkdir -p import/individual/$APP
                else
                        echo "Creating the directory to store xml files: import/individual/$APP"
                        mkdir -p import/individual/$APP
        fi
        for ((NUM=$SN;NUM<=$EN;NUM++))
        do
                echo "<joblist>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "  <job>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    <loglevel>INFO</loglevel>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    <sequence keepgoing=\"false\" strategy=\"node-first\">" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "      <command>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "        <jobref name=\"Stop ${DC}-${APP}${NUM}\" group=\"web/stop service/$UAPP/individual targets/$DC\"/>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "      </command>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "      <command>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "        <jobref name=\"Start ${DC}-${APP}${NUM}\" group=\"web/start service/$UAPP/individual targets/$DC\"/>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "      </command>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    </sequence>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    <description/>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    <name>Restart ${DC}-${APP}${NUM}</name>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    <context>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "      <project>SiteOps</project>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    </context>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "    <group>web/restart service/$UAPP/individual targets/$DC</group>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "  </job>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "</joblist>" >> import/individual/$APP/restart_${DC}_${APP}${NUM}.xml
                echo "Job restart_${DC}_${APP}${NUM} created."
                rd-jobs load -rf "import/individual/$APP/restart_${DC}_${APP}${NUM}.xml"
        done

else if [ "$ACTION" == "o" ]
        then
        if [[ "$UAPP" == "WWWSSL" || "$UAPP" == "WU" || "$UAPP" == "WS" || "$UAPP" == "WSAPI" || "$UAPP" == "WSAPISSL" || "$UAPP" == "SLAPCACHE" ]]
                then APP_FIX="WWW"
                else APP_FIX=$UAPP
        fi
        FILE="/blnfs/rundeck_servers/$APP_FIX/ARMPROD$UAPP"
        OLD_IFS=$IFS
        IFS=$'\n'
        if [ -d import/operational/$UAPP/restart ]
                then
                echo "The temporery directory import/operational/$UAPP/restart is already exist, I will rename it"
                mv import/operational/$UAPP/restart import/operational/$UAPP/restart.`date +%Y%m%d%S`
                echo "Creating temporery directories to store xml files in: import/operational/$UAPP/restart"
                mkdir -p import/operational/$UAPP/restart
                else
                        echo "Creating temporery directories to store xml files: import/operational/$UAPP/restart"
                        mkdir -p import/operational/$UAPP/restart
        fi
        for LIST in `cat $FILE`
                do
                        JOB_GROUP=`echo $LIST | awk -F "=>" '{print $1}'`
                        PRE_TARGET_GROUP=`echo $LIST | awk -F "=>" '{print $2}'`
                        TARGET_GROUP=`echo $PRE_TARGET_GROUP | sed 's,:,=,g'`
                        DC=`echo $TARGET_GROUP | awk -F "=" '{print $2}' | awk -F "-" '{print $1}'`
                        echo "<joblist>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "  <job>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    <loglevel>INFO</loglevel>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    <sequence keepgoing=\"false\" strategy=\"node-first\">" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "      <command>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "        <jobref name=\"Stop $JOB_GROUP\" group=\"web/stop service/$UAPP/operational partitions/$DC\" nodeStep=\"true\"/>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "      </command>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "      <command>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "        <jobref name=\"Start $JOB_GROUP\" group=\"web/start service/$UAPP/operational partitions/$DC\" nodeStep=\"true\"/>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "      </command>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    </sequence>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    <description/>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    <name>Restart $JOB_GROUP</name>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    <context>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "      <project>SiteOps</project>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    </context>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "    <group>web/restart service/$UAPP/operational partitions/$DC</group>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "  </job>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "</joblist>" >> import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml
                        echo "restart_${JOB_GROUP} created."
                        #rd-jobs load -rf "import/operational/$UAPP/restart/restart_${JOB_GROUP}.xml"
                done
        IFS=$OLD_IFS
        else
                echo "[ERROR] Operation mode (-t) is either i nor o, exit now!"
                exit 1
        fi
fi
