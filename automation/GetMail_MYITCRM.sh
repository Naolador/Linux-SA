###########################################################################################
# This tool is used to fetch customers' E-mails and export it to a text file.             #
# It connects to the default database: myitcrm. If the database is not what you're using, #
# please change the database name by changing the "user" and"db" value.                   #
#                                                            -- Neil Wang 11/09/2018      #
###########################################################################################
#!/bin/bash
user="myitcrm"
db="myitcrm"
echo "======= MYITCRM Customer E-mail Exporting Tool ======="
read -sp "Please input password for myitcrm database: " passvar
if [ "$passvar" ]
then
    if [ -f customeremail.txt ]
    then
        echo -e "\nFound existing email list file, backing up the old file."
        mv customeremail.txt customeremail.txt.`date +%H%M%d%m%Y`
    fi
    mysql -u ${user} -p${passvar} -D ${db} -e "select CUSTOMER_EMAIL from MYIT_TABLE_CUSTOMER;"|cut -f 2|grep -v "CUSTOMER_EMAIL" 1> customeremail.txt
    if [ "$?" -ne 0 ]
    then
        echo -e "\nCouldn't export customers' email list. Please check the database connection and try again."
        exit 1
    else
        echo -e "\n[OK] The email list has been exported to 'customeremail.txt' under current directory."
    fi
else
    echo -e "\n[ERROR] No password is detected. Exit now."
    exit 1
fi
