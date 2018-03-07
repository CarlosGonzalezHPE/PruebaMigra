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
KPI_LOG=/var/opt/SIU_MANAGER/KPI/log
touch $KPI_LOG/KPI.log.$(date +%Y%m%d%H%M%S)
LOG_FILE=`ls -1rt $KPI_LOG|tail -1`
JAVA_LOG=$LOG_FILE
echo "$(date +"%F %H:%M:%S %3N") INFO : ==================================START====================================" >> $KPI_LOG/$LOG_FILE



InstancePIDFile="/tmp/KPIinstance.pid"
if [ -e "${InstancePIDFile}" ]
then
    pid=$(cat ${InstancePIDFile})
    if [ -e /proc/${pid} ]
    then
		check_pid=$(ps -p ${pid} | grep KPI | wc -l)
		if [ $check_pid -gt 0 ]
		then
        echo "$(date +"%F %H:%M:%S %3N")  PID  ${pid} belongs to KPI " >> $KPI_LOG/$LOG_FILE
	    echo "$(date +"%F %H:%M:%S %3N") ERROR : Can not run $0: Exiting from KPI report execution as Process ${pid} is still running." >> $KPI_LOG/$LOG_FILE
		echo "$(date +"%F %H:%M:%S %3N") INFO : ==================================END======================================" >> $KPI_LOG/$LOG_FILE
        exit 0
    else
		echo "$(date +"%F %H:%M:%S %3N")  PID ${pid}  not belongs to KPI " >> $KPI_LOG/$LOG_FILE
        # Clean up previous instance.pid file
        rm -f $InstancePIDFile
        fi
	else
        # Clean up previous instance.pid file
		echo "$(date +"%F %H:%M:%S %3N") INFO : No other KPI instance is running." >> $KPI_LOG/$LOG_FILE
        rm -f $InstancePIDFile
    fi
fi

       # Inserting new pid
        echo "$$" > ${InstancePIDFile}
echo "$(date +"%F %H:%M:%S %3N") INFO : KPI program is about to start executing." >> $KPI_LOG/$LOG_FILE
echo "$(date +"%F %H:%M:%S %3N") INFO : ==================================END======================================" >> $KPI_LOG/$LOG_FILE


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


#
# Added by HPE CMS Iberia delivery team
#

mkdir -p /opt/oss/kpis

for FILEPATH in $(2>/dev/null ls /var/opt/SIU_MANAGER/KPI/reports/*_RequestType_KPI.dat)
do
  FILENAME=$(basename ${FILEPATH})
  NEW_FILENAME="hpedeg-service_kpis_request_types-"$(echo ${FILENAME} | cut -d "_" -f 1)"-"$(echo ${FILENAME} | cut -d "_" -f 2 | cut -c 1-12)

  cp ${FILEPATH} /opt/oss/kpis/${NEW_FILENAME}
  if [ $? -ne 0 ]
  then
    echo "$(date +"%F %H:%M:%S %3N") ERROR : Command 'cp ${FILEPATH} /opt/oss/kpis/${NEW_FILENAME}' failed." >> $KPI_LOG/$LOG_FILE
  else
    echo "$(date +"%F %H:%M:%S %3N") INFO : Copied and renamed file '/opt/oss/kpis/${NEW_FILENAME}'" >> $KPI_LOG/$LOG_FILE
    mv ${FILEPATH} ${FILEPATH}.moved
  fi
done

for FILEPATH in $(2>/dev/null ls /var/opt/SIU_MANAGER/KPI/reports/*_ReturnCode_KPI.dat)
do
  FILENAME=$(basename ${FILEPATH})
  NEW_FILENAME="hpedeg-service_kpis_return_codes-"$(echo ${FILENAME} | cut -d "_" -f 1)"-"$(echo ${FILENAME} | cut -d "_" -f 2 | cut -c 1-12)

  cp ${FILEPATH} /opt/oss/kpis/${NEW_FILENAME}
  if [ $? -ne 0 ]
  then
    echo "$(date +"%F %H:%M:%S %3N") ERROR : Command 'cp ${FILEPATH} /opt/oss/kpis/${NEW_FILENAME}' failed." >> $KPI_LOG/$LOG_FILE
  else
    echo "$(date +"%F %H:%M:%S %3N") INFO : Copied and renamed file '/opt/oss/kpis/${NEW_FILENAME}'" >> $KPI_LOG/$LOG_FILE
    mv ${FILEPATH} ${FILEPATH}.moved
  fi
done
