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

  CHECK_NUMBER="$(getConfigParam CPU CHECK_NUMBER)"
  if [ $? -lt 0 ] || [ -z ${CHECK_NUMBER} ]
  then
    logError "Unable to get mandatory parameter 'CHECK_NUMBER' in section 'CPU'"
    return 1
  fi
  logDebug "CHECK_NUMBER = ${CHECK_NUMBER}"

  CHECK_INTERVAL="$(getConfigParam CPU CHECK_INTERVAL)"
  if [ $? -lt 0 ] || [ -z ${CHECK_INTERVAL} ]
  then
    logError "Unable to get mandatory parameter 'CHECK_INTERVAL' in section 'CPU'"
    return 1
  fi
  logDebug "CHECK_INTERVAL = ${CHECK_INTERVAL}"

  CPU_HIGH_DATA="$(getConfigParam CPU HIGH_LIMIT)"
  if [ $? -lt 0 ] || [ -z ${CPU_HIGH_DATA} ]
  then
    logError "Unable to get mandatory parameter 'HIGH_LIMIT' in section 'CPU'"
    return 1
  fi
  logDebug "CPU_HIGH_DATA = ${CPU_HIGH_DATA}"

  let CPU_HIGH_LIMIT=$(echo ${CPU_HIGH_DATA} | cut -d "-" -f 1)
  CPU_HIGH_SEVERITY=$(echo ${CPU_HIGH_DATA} | cut -d "-" -f 2)
  logDebug "CPU_HIGH_LIMIT = ${CPU_HIGH_LIMIT}"
  logDebug "CPU_HIGH_SEVERITY = ${CPU_HIGH_SEVERITY}"

  CPU_LOW_DATA="$(getConfigParam CPU LOW_LIMIT)"
  if [ $? -lt 0 ] || [ -z ${CPU_LOW_DATA} ]
  then
    logError "Unable to get mandatory parameter 'LOW_LIMIT' in section 'CPU'"
    return 1
  fi
  logDebug "CPU_LOW_DATA = ${CPU_LOW_DATA}"

  let CPU_LOW_LIMIT=$(echo ${CPU_LOW_DATA} | cut -d "-" -f 1)
  CPU_LOW_SEVERITY=$(echo ${CPU_LOW_DATA} | cut -d "-" -f 2)
  logDebug "CPU_LOW_LIMIT = ${CPU_LOW_LIMIT}"
  logDebug "CPU_LOW_SEVERITY = ${CPU_LOW_SEVERITY}"

  ALARM_DESCRIPTION="$(getConfigParam ALARM DESCRIPTION)"
  if [ $? -lt 0 ] || [ -z ${ALARM_DESCRIPTION} ]
  then
    logError "Unable to get mandatory parameter 'DESCRIPTION' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_DESCRIPTION = ${ALARM_DESCRIPTION}"

  ALARM_ADDITIONAL_INFO="$(getConfigParam ALARM ADDITIONAL_INFO)"
  if [ $? -lt 0 ] || [ -z ${ALARM_ADDITIONAL_INFO} ]
  then
    logError "Unable to get mandatory parameter 'ADDITIONAL_INFO' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_ADDITIONAL_INFO = ${ALARM_ADDITIONAL_INFO}"

  let IDLE_TIME=$(mpstat ${CHECK_INTERVAL} ${CHECK_NUMBER} | tail -n 1 | awk '{print $11}' | cut -d "." -f 1)

  if [ -n "${IDLE_TIME}" ]
  then
    if [ ${IDLE_TIME} -le ${CPU_HIGH_LIMIT} ]
    then
      LIMIT=${CPU_HIGH_LIMIT}
      SEVERITY=${CPU_HIGH_SEVERITY}
    else
      if [ ${IDLE_TIME} -le ${CPU_HIGH_LOW} ]
      then
        LIMIT=${CPU_LOW_LIMIT}
        SEVERITY=${CPU_LOW_SEVERITY}
      else
        logDebug "No alarma condition detected for CPU usage"
        return 0
      fi
    fi

    ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
    ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

    addAlarm "$(hostname | cut -d "." -f 1) memory" "${SEVERITY}" "${ALARM_DESCRIPTION}" "${ALARM_ADDITIONAL_INFO}"
    if [ $? -ne 0 ]
    then
      logError "Unable to add alarm"
      return 1
    fi
  else
    logError "Unable to get CPU idle time"
    return 1
  fi
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/monitoring/monitor-cpu
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
