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

  getConfigSection INTERFACES > ${TMP_DIR}/interfaces
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'INTERFACES'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/interfaces ]
  then
    logWarning "No network interfaces to be monitorized"
    return 0
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
    INTERFACE=$(echo ${LINE} | cut -d ":" -f 1)
    IP_ADDRESS=$(echo ${LINE} | cut -d ":" -f 2)

    logInfo "Checking status of Network Interface '${INTERFACE} (${IP_ADDRESS})'"

    set +e
    ping -c 4 -w 10 ${IP_ADDRESS} >> ${LOG_FILEPATH} 2>&1
    PING_RESULT=$?
    set -e

    if [ "${PING_RESULT}" -ne "0" ]
    then
      ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
      ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

      addAlarm "$(hostname | cut -d "." -f 1) network ${INTERFACE}" "${SEVERITY}" "${ALARM_DESCRIPTION}" "${ALARM_ADDITIONAL_INFO}"
      if [ $? -ne 0 ]
      then
        logError "Unable to add alarm"
        return 1
      fi

       logDebug "No alarm condition detected for Network Interface '${INTERFACE}' (${IP_ADDRESS})"
    fi
  done < ${TMP_DIR}/interfaces
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/monitoring/monitor-network
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
