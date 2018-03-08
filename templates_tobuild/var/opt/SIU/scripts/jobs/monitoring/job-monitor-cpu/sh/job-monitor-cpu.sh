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

  CHECK_NUMBER="$(getConfigParam GENERAL CHECK_NUMBER)"
  if [ $? -lt 0 ] || [ -z ${CHECK_NUMBER} ]
  then
    logError "Unable to get mandatory parameter 'CHECK_NUMBER' in section 'GENERAL'"
    return 1
  fi
  logDebug "CHECK_NUMBER = ${CHECK_NUMBER}"

  CHECK_INTERVAL="$(getConfigParam GENERAL CHECK_INTERVAL)"
  if [ $? -lt 0 ] || [ -z ${CHECK_INTERVAL} ]
  then
    logError "Unable to get mandatory parameter 'CHECK_INTERVAL' in section 'GENERAL'"
    return 1
  fi
  logDebug "CHECK_INTERVAL = ${CHECK_INTERVAL}"

  getConfigSection LIMITS > ${TMP_DIR}/limits
  if [ $? -lt 0 ]
  then
    logError "Unable to get section 'LIMITS'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/limits ]
  then
    logWarning "No CPU usage limits defined"
    return 0
  fi

  ALARM_DESCRIPTION="$(getConfigParam ALARM DESCRIPTION)"
  if [ $? -lt 0 ] || [ -z "${ALARM_DESCRIPTION}" ]
  then
    logError "Unable to get mandatory parameter 'DESCRIPTION' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_DESCRIPTION = ${ALARM_DESCRIPTION}"

  ALARM_ADDITIONAL_INFO="$(getConfigParam ALARM ADDITIONAL_INFO)"
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory parameter 'ADDITIONAL_INFO' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_ADDITIONAL_INFO = ${ALARM_ADDITIONAL_INFO}"

  KPI_DESCRIPTION="$(getConfigParam KPI DESCRIPTION)"
  if [ $? -lt 0 ] || [ -z "${KPI_DESCRIPTION}" ]
  then
    logError "Unable to get mandatory parameter 'DESCRIPTION' in section 'KPI'"
    return 1
  fi
  logDebug "KPI_DESCRIPTION = ${KPI_DESCRIPTION}"

  KPI_ADDITIONAL_INFO="$(getConfigParam KPI ADDITIONAL_INFO)"
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory parameter 'ADDITIONAL_INFO' in section 'KPI'"
    return 1
  fi
  logDebug "KPI_ADDITIONAL_INFO = ${KPI_ADDITIONAL_INFO}"

  logInfo "Checking CPU usage"

  mpstat ${CHECK_INTERVAL} ${CHECK_NUMBER} | awk '
  BEGIN { T = 0; N = 0; }
  {
    split($13, v, "%");
    T = T + v[1];
    N = N + 1;
  }
  END { printf("%f", T / N); }' > ${TMP_DIR}/idle_time

  if [ ! -s ${TMP_DIR}/idle_time ]
  then
     logError "Unable to compute idle time"
     return 1
  fi

  let IDLE_TIME=$(cat ${TMP_DIR}/idle_time | head -n 1 | cut -d "." -f 1)
  logDebug "IDLE_TIME = ${IDLE_TIME}"

  if [ ! -n "${IDLE_TIME}" ]
  then
    logError "Unable to compute idle time"
    return 1
  fi

  ACTUAL_KPI_DESCRIPTION=$(eval echo "${KPI_DESCRIPTION}")
  ACTUAL_KPI_ADDITIONAL_INFO=$(eval echo "${KPI_ADDITIONAL_INFO}")

  logDebug "ACTUAL_KPI_DESCRIPTION = ${ACTUAL_KPI_DESCRIPTION}"
  logDebug "ACTUAL_KPI_ADDITIONAL_INFO = ${ACTUAL_KPI_ADDITIONAL_INFO}"

  addKpi "$(hostname | cut -d "." -f 1)-cpu" "${ACTUAL_KPI_DESCRIPTION}" "${ACTUAL_KPI_ADDITIONAL_INFO}"

  while read LIMIT
  do
    THRESHOLD="$(getConfigParam ${LIMIT} THRESHOLD)"
    if [ $? -lt 0 ] || [ -z ${THRESHOLD} ]
    then
      logError "Unable to get mandatory parameter 'THRESHOLD' in section '${LIMIT}'"
      return 1
    fi
    logDebug "THRESHOLD = ${THRESHOLD}"

    SEVERITY="$(getConfigParam ${LIMIT} SEVERITY)"
    if [ $? -lt 0 ] || [ -z ${SEVERITY} ]
    then
      logError "Unable to get mandatory parameter 'SEVERITY' in section '${LIMIT}'"
      return 1
    fi
    logDebug "SEVERITY = ${SEVERITY}"

    if [ ${IDLE_TIME} -le ${THRESHOLD} ]
    then
      ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
      ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

      logDebug "ACTUAL_ALARM_DESCRIPTION = ${ACTUAL_ALARM_DESCRIPTION}"
      logDebug "ACTUAL_ALARM_ADDITIONAL_INFO = ${ACTUAL_ALARM_ADDITIONAL_INFO}"

      addAlarm "$(hostname | cut -d "." -f 1)-cpu" "${SEVERITY}" "${ACTUAL_ALARM_DESCRIPTION}" "${ACTUAL_ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi

      break
    fi
  done < ${TMP_DIR}/limits

  if [ ! -s ${WORK_DIR}/alarms ]
  then
    logInfo "No alarm condition detected for CPU usage"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/monitoring/job-monitor-cpu
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/jobs/monitoring/job-common/sh/job-common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
