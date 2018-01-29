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

  getConfigSection PROCESSES > ${TMP_DIR}/processes
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'PROCESSES'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/processes ]
  then
    logWarning "No processes to be monitorized"
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

  while read LINE
  do
    PROCESS=$(echo ${LINE} | cut -d ":" -f 1)
    PATTERN=$(echo ${LINE} | cut -d ":" -f 2 | cut -d "," -f 1)
    MIN_INSTANCES=$(echo ${LINE} | cut -d ":" -f 2 | cut -d "," -f 2)
    MAX_INSTANCES=$(echo ${LINE} | cut -d ":" -f 2 | cut -d "," -f 3)
    SEVERITY=$(echo ${LINE} | cut -d ":" -f 2 | cut -d "," -f 3)

    logInfo "Checking running status of process '${PROCESS}'"

    let RUNNING_INSTANCES=$(ps -edaf | grep "${PATTERN}" | grep -v "grep" | wc -l)

    if [ ${RUNNING_INSTANCES} -lt ${MIN_INSTANCES} ] || [ ${RUNNING_INSTANCES} -gt ${MAX_INSTANCES} ]
    then
      ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
      ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

      addAlarm "$(hostname | cut -d "." -f 1)-process-${PROCESS}" "${SEVERITY}" "${ACTUAL_ALARM_DESCRIPTION}" "${ACTUAL_ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi
    else
      logDebug "No alarm condition detected for process '${PROCESS}'"

      ACTUAL_KPI_DESCRIPTION=$(eval echo "${KPI_DESCRIPTION}")
      ACTUAL_KPI_ADDITIONAL_INFO=$(eval echo "${KPI_ADDITIONAL_INFO}")

      logDebug "ACTUAL_KPI_DESCRIPTION = ${ACTUAL_KPI_DESCRIPTION}"
      logDebug "ACTUAL_KPI_ADDITIONAL_INFO = ${ACTUAL_KPI_ADDITIONAL_INFO}"

      addKpi "$(hostname | cut -d "." -f 1)-cpu" "${ACTUAL_KPI_DESCRIPTION}" "${ACTUAL_KPI_ADDITIONAL_INFO}"
    fi
  done < ${TMP_DIR}/processes

  if [ ! -s ${WORK_DIR}/alarms ]
  then
    logInfo "No alarm condition detected for processes"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/monitoring/monitor-processes
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
