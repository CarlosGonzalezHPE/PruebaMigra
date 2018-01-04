#!/bin/bash
#-------------------------------------------------------------------------------
# Orange Spain DEG
#
# HPE CMS Iberia, 2017
#-------------------------------------------------------------------------------
# Descripcion: Script comun
#-------------------------------------------------------------------------------

#
# Variables
#

#
# Functions
#

function getNextAlarmId
{
  logDebug "Execution function 'getNewAlarmId'"

  typeset local SOURCE=$1
  if [ -s ${COMMON_CTRL_DIR}/nextAlarmId ]
  then
    ALARM_ID=$(head -n 1 ${COMMON_CTRL_DIR}/nextAlarmId )
    if [ ${ALARM_ID} -ge 99999 ]
    then
      let NEXT_ALARM_ID=0
    else
      let NEXT_ALARM_ID=${ALARM_ID}+1
    fi
    echo ${NEXT_ALARM_ID} > ${COMMON_CTRL_DIR}/nextAlarmId
    echo ${NEXT_ALARM_ID}
    return 0
  else
    logError "Unable to get next Alarm Id"
    return 1
  fi
}


function addAlarm
{
  ELEMENT=$1
  SEVERITY=$2
  DESCRIPTION=$3
  ADDITIONAL_INFO=$4

  TIMESTAMP=$(date +'%Y%m%d%H%M%S')

  echo "${TIMESTAMP}#${ELEMENT}#${SEVERITY}#${DESCRIPTION}#${ADDITIONAL_INFO}" >> ${TMP_DIR}/alarms

  logWarning "Alarm condition detected: ${TIMESTAMP}#${ELEMENT}#${SEVERITY}#${DESCRIPTION}#${ADDITIONAL_INFO}"
}


#
# Main
#

. /opt/<%SIU_INSTANCE%>/scripts/common/common.sh

COMMON_CTRL_DIR=/opt/<%SIU_INSTANCE%>/scripts/monitoring/ctrl
export COMMON_CTRL_DIR

mkdir -p ${COMMON_CTRL_DIR}

>/dev/null 2>&1 cd ${DIR}
if [ $? -ne 0 ]
then
  logError "Unable to access to directory '${COMMON_CTRL_DIR}'"
  >/dev/null 2>&1 cd -
  endOfExecution 1
fi
