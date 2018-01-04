#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

#
# Functions
#

function process
{
  logDebug "Executing function 'process'"

  IDLE_TIME_CHECK_NUMBER="$(getConfigParam IDLE_TIME CHECK_NUMBER)"
  if [ $? -lt 0 ] || [ -z ${IDLE_TIME_CHECK_NUMBER} ]
  then
    logError "Unable to get mandatory parameter 'CHECK_NUMBER' in section 'IDLE_TIME'"
    return 1
  fi
  logDebug "IDLE_TIME_CHECK_NUMBER = ${IDLE_TIME_CHECK_NUMBER}"

  IDLE_TIME_CHECK_INTERVAL="$(getConfigParam IDLE_TIME CHECK_INTERVAL)"
  if [ $? -lt 0 ] || [ -z ${IDLE_TIME_CHECK_INTERVAL} ]
  then
    logError "Unable to get mandatory parameter 'CHECK_INTERVAL' in section 'IDLE_TIME'"
    return 1
  fi
  logDebug "IDLE_TIME_CHECK_INTERVAL = ${IDLE_TIME_CHECK_INTERVAL}"

  IDLE_TIME_LIMIT="$(getConfigParam IDLE_TIME LIMIT)"
  if [ $? -lt 0 ] || [ -z ${IDLE_TIME_LIMIT} ]
  then
    logError "Unable to get mandatory parameter 'LIMIT' in section 'IDLE_TIME'"
    return 1
  fi
  logDebug "IDLE_TIME_LIMIT = ${IDLE_TIME_LIMIT}"

  IDLE_TIME_ALARM_SEVERITY="$(getConfigParam IDLE_TIME ALARM_SEVERITY)"
  if [ $? -lt 0 ] || [ -z ${IDLE_TIME_ALARM_SEVERITY} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_SEVERITY' in section 'IDLE_TIME'"
    return 1
  fi
  logDebug "IDLE_TIME_ALARM_SEVERITY = ${IDLE_TIME_ALARM_SEVERITY}"

  IDLE_TIME_ALARM_DESCRIPTION="$(getConfigParam IDLE_TIME ALARM_DESCRIPTION)"
  if [ $? -lt 0 ] || [ -z ${IDLE_TIME_ALARM_DESCRIPTION} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_DESCRIPTION' in section 'IDLE_TIME'"
    return 1
  fi
  logDebug "IDLE_TIME_ALARM_DESCRIPTION = ${IDLE_TIME_ALARM_DESCRIPTION}"

  IDLE_TIME_ALARM_ADDITIONAL_INFO="$(getConfigParam IDLE_TIME ALARM_ADDITIONAL_INFO)"
  if [ $? -lt 0 ] || [ -z ${IDLE_TIME_ALARM_ADDITIONAL_INFO} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_ADDITIONAL_INFO' in section 'IDLE_TIME'"
    return 1
  fi
  logDebug "IDLE_TIME_ALARM_ADDITIONAL_INFO = ${IDLE_TIME_ALARM_ADDITIONAL_INFO}"

  let IDLE_TIME=$(mpstat ${CHECK_INTERVAL} ${CHECK_NUMBER} | tail -n 1 | awk '{print $11}' | cut -d "." -f 1)

  if [ -n "${IDLE_TIME}" ]
  then
    if [ ${IDLE_TIME} -le ${IDLE_TIME_LIMIT} ]
    then
      addAlarm "$(hostname | cut -d "." -f 1) cpu idle time" "${IDLE_TIME_ALARM_SEVERITY}" "${IDLE_TIME_ALARM_DESCRIPTION}" "${IDLE_TIME_ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi
    fi
  else
    logWarning "Unable to get CPU idle time"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=/opt/<%SIU_INSTANCE%>/scripts/monitoring/monitor-cpu
export SCRIPT_BASEDIR

. /opt/<%SIU_INSTANCE%>/scripts/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
