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

  getConfigSection LIMITS > ${TMP_DIR}/limits
  if [ $? -lt 0 ]
  then
    logError "Unable to get section 'LIMITS'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/limits ]
  then
    logWarning "No Memory usage limits defined"
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

  logInfo "Checking Memory usage"

  free -m | egrep "Mem:|-/+" | awk '
  {
    ratio = (100 * $3) / $2;
    if (ratio > 0) {
      print ratio;
    }
  }' > ${TMP_DIR}/ratio

  if [ ! -s ${TMP_DIR}/ratio ]
  then
    logError "Unable to compute memory usage ratio"
    return 1
  fi

  let RATIO=$(cat ${TMP_DIR}/ratio | head -n 1 | cut -d "." -f 1)
  logDebug "RATIO = ${RATIO}"

  if [ ! -n "${RATIO}" ]
  then
    logError "Unable to compute memory usage ratio"
    return 1
  fi

  ACTUAL_KPI_DESCRIPTION=$(eval echo "${KPI_DESCRIPTION}")
  ACTUAL_KPI_ADDITIONAL_INFO=$(eval echo "${KPI_ADDITIONAL_INFO}")

  logDebug "ACTUAL_KPI_DESCRIPTION = ${ACTUAL_KPI_DESCRIPTION}"
  logDebug "ACTUAL_KPI_ADDITIONAL_INFO = ${ACTUAL_KPI_ADDITIONAL_INFO}"

  addKpi "$(hostname | cut -d "." -f 1)-memory" "${ACTUAL_KPI_DESCRIPTION}" "${ACTUAL_KPI_ADDITIONAL_INFO}"

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

    if [ ${RATIO} -ge ${THRESHOLD} ]
    then
      ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
      ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

      logDebug "ACTUAL_ALARM_DESCRIPTION = ${ACTUAL_ALARM_DESCRIPTION}"
      logDebug "ACTUAL_ALARM_ADDITIONAL_INFO = ${ACTUAL_ALARM_ADDITIONAL_INFO}"

      addAlarm "$(hostname | cut -d "." -f 1)-memory" "${SEVERITY}" "${ACTUAL_ALARM_DESCRIPTION}" "${ACTUAL_ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi

      return 0
    fi
  done < ${TMP_DIR}/limits

  if [ ! -s ${WORK_DIR}/alarms ]
  then
    logInfo "No alarm condition detected for memory usage"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/jobs/monitoring/monitor-memory
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/jobs/monitoring/job-common/sh/job-common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
