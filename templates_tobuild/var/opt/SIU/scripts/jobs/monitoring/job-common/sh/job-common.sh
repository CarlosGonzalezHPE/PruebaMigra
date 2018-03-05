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

function getNextId
{
  logDebug "Execution function 'getNewId'"

  if [ $# -ne 1 ]
  then
    logError "Usage: getNewId <LABEL>"
    return 1
  fi

  LABEL=$1

  exec 200>${COMMON_CTRL_DIR}/lock.${LABEL}
  flock 200

  if [ ! -s ${COMMON_CTRL_DIR}/id.${LABEL} ]
  then
    echo 1 > ${COMMON_CTRL_DIR}/id.${LABEL}
    logWarning "File '${COMMON_CTRL_DIR}/id.${LABEL}' created. Next Id reset to 1"
  fi

  ID=$(head -n 1 ${COMMON_CTRL_DIR}/id.${LABEL} )

  if [ ! -n ${ID} ]
  then
    echo 1 > ${COMMON_CTRL_DIR}/id.${LABEL}
    logWarning "Content of file '${COMMON_CTRL_DIR}/id.${LABEL}' invalid. Next Id reset to 1"
  fi

  if [ ${ID} -ge 99999 ]
  then
    let NEXT_ID=0
  else
    let NEXT_ID=${ID}+1
  fi
  echo ${NEXT_ID} > ${COMMON_CTRL_DIR}/id.${LABEL}

  flock -u 200

  printf "%5.5d" ${ID}
}


function addAlarm
{
  logDebug "Execution function 'addAlarm'"

  ELEMENT=$1
  SEVERITY=$2
  DESCRIPTION=$3
  ADDITIONAL_INFO=$4

  logDebug "ELEMENT         = ${ELEMENT}"
  logDebug "SEVERITY        = ${SEVERITY}"
  logDebug "DESCRIPTION     = ${DESCRIPTION}"
  logDebug "ADDITIONAL_INFO = ${ADDITIONAL_INFO}"

  TIMESTAMP=$(date +'%Y%m%d%H%M%S')

  ALARM_ID=$(getNextId ALARM)
  if [ $? -ne 0 ]
  then
    logError "Unable to get next Alarm Id"
    return 1
  fi

  ALARM_TEXT=$(eval echo "${ALARM_ID}#${ELEMENT}#${TIMESTAMP}#${SEVERITY}#${DESCRIPTION}#${ADDITIONAL_INFO}")
  echo ${ALARM_TEXT} >> ${WORK_DIR}/alarms

  logWarning "Alarm condition detected: ${ALARM_TEXT}"
}


function addKpi
{
  logDebug "Execution function 'addKpi'"

  ELEMENT=$1
  DESCRIPTION=$2
  ADDITIONAL_INFO=$3

  logDebug "ELEMENT         = ${ELEMENT}"
  logDebug "DESCRIPTION     = ${DESCRIPTION}"
  logDebug "ADDITIONAL_INFO = ${ADDITIONAL_INFO}"

  TIMESTAMP=$(date +'%Y%m%d%H%M%S')

  KPI_TEXT=$(eval echo "${ELEMENT}#${TIMESTAMP}#${DESCRIPTION}#${ADDITIONAL_INFO}")
  echo ${KPI_TEXT} >> ${WORK_DIR}/kpis
}


#
# Main
#

. <%SCRIPTS_DIR%>/common/common.sh

COMMON_CTRL_DIR=<%SCRIPTS_DIR%>/jobs/monitoring/ctrl
export COMMON_CTRL_DIR

mkdir -p ${COMMON_CTRL_DIR}

>/dev/null 2>&1 cd ${COMMON_CTRL_DIR}
if [ $? -ne 0 ]
then
  logError "Unable to access to directory '${COMMON_CTRL_DIR}'"
  >/dev/null 2>&1 cd -
  endOfExecution 1
fi
