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

  HOSTNAME_OSS=$(getOssHostname $(hostname | cut -d "." -f 1))
  if [ $? -ne 0 ]
  then
    logError "Unable to get OSS hostname"
    return 1
  fi
  logDebug "HOSTNAME_OSS = ${HOSTNAME_OSS}"

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
    SEVERITY=$(echo ${LINE} | cut -d ":" -f 2 | cut -d "," -f 4)

    logInfo "Checking running status of process '${PROCESS}'"

    let RUNNING_INSTANCES=$(ps -edaf | grep "${PATTERN}" | grep -v "grep" | wc -l)

    if [ ${RUNNING_INSTANCES} -lt ${MIN_INSTANCES} ] || [ ${RUNNING_INSTANCES} -gt ${MAX_INSTANCES} ]
    then
      ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
      ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

      addAlarm "${HOSTNAME_OSS}" "${SEVERITY}" "${ACTUAL_ALARM_DESCRIPTION}" "${ACTUAL_ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi
    else
      logDebug "No alarm condition detected for process '${PROCESS}'"
    fi

    ACTUAL_KPI_DESCRIPTION=$(eval echo "${KPI_DESCRIPTION}")
    ACTUAL_KPI_ADDITIONAL_INFO=$(eval echo "${KPI_ADDITIONAL_INFO}")

    logDebug "ACTUAL_KPI_DESCRIPTION = ${ACTUAL_KPI_DESCRIPTION}"
    logDebug "ACTUAL_KPI_ADDITIONAL_INFO = ${ACTUAL_KPI_ADDITIONAL_INFO}"

    addKpi "${HOSTNAME_OSS}" "${ACTUAL_KPI_DESCRIPTION}" "${ACTUAL_KPI_ADDITIONAL_INFO}"
  done < ${TMP_DIR}/processes

  if [ ! -s ${WORK_DIR}/alarms ]
  then
    logInfo "No alarm condition detected for processes"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/monitoring/job-monitor-processes
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/jobs/monitoring/job-common/sh/job-common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
