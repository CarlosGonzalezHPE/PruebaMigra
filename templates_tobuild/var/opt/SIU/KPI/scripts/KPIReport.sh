#!/bin/sh
#-------------------------------------------------------------------------------
#
# Project : HP-DEG
#
# Version : 1.0
# Author : HP CMS
#
# Component: KPIReport.sh
# Description: Tool to generate KPI for DEG.
#
# Usage: KPIReport.sh
#
#-------------------------------------------------------------------------------

export TZ=GMT
KPI_LOG_DIR=/var/opt/SIU_MANAGER/KPI/log
SUFFIX=$(date +%Y%m%d%H%M%S)
KPI_LOG_FILENAME=KPI.log.${SUFFIX}

touch ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}

JAVA_LOG=${KPI_LOG_FILENAME}
echo "$(date +"%F %H:%M:%S %3N") INFO : ==================================START====================================" >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}


InstancePIDFile="/tmp/KPIinstance.pid"
if [ -e "${InstancePIDFile}" ]
then
    pid=$(cat ${InstancePIDFile})
    if [ -e /proc/${pid} ]
    then
		check_pid=$(ps -p ${pid} | grep KPI | wc -l)
		if [ $check_pid -gt 0 ]
		then
        echo "$(date +"%F %H:%M:%S %3N")  PID  ${pid} belongs to KPI " >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}
	    echo "$(date +"%F %H:%M:%S %3N") ERROR : Can not run $0: Exiting from KPI report execution as Process ${pid} is still running." >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}
		echo "$(date +"%F %H:%M:%S %3N") INFO : ==================================END======================================" >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}
        exit 0
    else
		echo "$(date +"%F %H:%M:%S %3N")  PID ${pid}  not belongs to KPI " >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}
        # Clean up previous instance.pid file
        rm -f $InstancePIDFile
        fi
	else
        # Clean up previous instance.pid file
		echo "$(date +"%F %H:%M:%S %3N") INFO : No other KPI instance is running." >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}
        rm -f $InstancePIDFile
    fi
fi

       # Inserting new pid
        echo "$$" > ${InstancePIDFile}
echo "$(date +"%F %H:%M:%S %3N") INFO : KPI program is about to start executing." >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}
echo "$(date +"%F %H:%M:%S %3N") INFO : ==================================END======================================" >> ${KPI_LOG_DIR}/${KPI_LOG_FILENAME}


CURDIR=`dirname $0`
cd $CURDIR

. ./setenv.sh

sleep 1

#$JAVA_HOME/bin/java  -Duser.timezone=GMT com.hp.deg.kpi.KPIReport
$JAVA_HOME/bin/java  -Duser.timezone=GMT com.hp.deg.kpi.KPIReport $JAVA_LOG

rm /var/opt/SIU_MANAGER/KPI/log/$JAVA_LOG

cd /var/opt/SIU_MANAGER/KPI/log
if [ -e KPI.log.yyyyMMddHHmmss ]
then
  rm KPI.log.yyyyMMddHHmmss
fi
