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

  ALARM_DESCRIPTION="$(getConfigParam ALARM ALARM_DESCRIPTION)"
  if [ $? -lt 0 ] || [ -z ${ALARM_DESCRIPTION} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_DESCRIPTION' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_DESCRIPTION = ${ALARM_DESCRIPTION}"

  ALARM_ADDITIONAL_INFO="$(getConfigParam ALARM ALARM_ADDITIONAL_INFO)"
  if [ $? -lt 0 ] || [ -z ${ALARM_ADDITIONAL_INFO} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_ADDITIONAL_INFO' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_ADDITIONAL_INFO = ${ALARM_ADDITIONAL_INFO}"

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

      addAlarm "$(hostname | cut -d "." -f 1) process ${PROCESS}" "${SEVERITY}" "${ALARM_DESCRIPTION}" "${ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi
    else
      logDebug "No alarm condition detected for process '${PROCESS}'"
    fi
  done < ${TMP_DIR}/processes
}


#
# Main
#

SCRIPT_BASEDIR=/opt/<%SIU_INSTANCE%>/scripts/monitoring/monitor-network
export SCRIPT_BASEDIR

. /opt/<%SIU_INSTANCE%>/scripts/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
