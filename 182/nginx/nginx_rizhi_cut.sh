#!/bin/bash
LOG_DIR="/usr/local/nginx/logs/"
BACK_DIR=`date +%Y/%m/`  
BACK_LOGS="/usr/local/nginx/logs/${BACK_DIR}"
DATE_NAME=`date +%Y%m%d `
if [ -d ${BACK_LOGS} ];then
        echo 
else
	/bin/mkdir -p  ${BACK_LOGS}
fi
for log in `ls /usr/local/nginx/logs/|grep -v -E "nginx.pid|[0-9].*"`;do

	/bin/mv ${LOG_DIR}/$log ${BACK_LOGS}/${DATE_NAME}_${log}

done
kill -USR1 `cat  /usr/local/nginx/logs/nginx.pid`
########del last month logdate#
YEAR=`date +%Y`
MONTH=`date +%m`
MONTH=`expr $MONTH - 2`
if [ $MONTH -eq 1 ]; then
    MONTH=12
    YEAR=`expr $YEAR - 1`
fi
 
if [ $MONTH -lt 10 ]; then
    MONTH="0${MONTH}"
fi
DEL_DIR=/usr/local/nginx/logs/${YEAR}/${MONTH}/
rm -fr ${DEL_DIR}

