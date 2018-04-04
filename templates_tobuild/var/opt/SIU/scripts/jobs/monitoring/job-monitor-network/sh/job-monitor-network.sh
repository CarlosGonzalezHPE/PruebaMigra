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
    HOST=$(echo ${LINE} | cut -d ";" -f 1)
    INTERFACE=$(echo ${LINE} | cut -d ";" -f 2)
    IP_ADDRESS=$(echo ${LINE} | cut -d ";" -f 3)
    CURRENT_HOST=$(hostname | cut -d "." -f 1)

    logDebug "HOST = ${HOST}"
    logDebug "INTERFACE = ${INTERFACE}"
    logDebug "IP_ADDRESS = ${IP_ADDRESS}"
    logDebug "CURRENT_HOST = ${CURRENT_HOST}"

    if [ "${HOST}" != "${CURRENT_HOST}" ]
    then
      logDebug "Host '${HOST}' does not match current host '${CURRENT_HOST}'"
      continue
    fi

    logInfo "Checking status of Network Interface '${INTERFACE} (${IP_ADDRESS})'"

    set +e
    ping -c 4 -w 10 ${IP_ADDRESS} >> ${TMP_DIR}/ping.out_err 2>&1
    PING_RESULT=$?
    set -e

    if [ "${PING_RESULT}" -ne "0" ]
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
      logInfo "No alarm condition detected for Network Interface '${INTERFACE}' (${IP_ADDRESS})"

      ACTUAL_KPI_DESCRIPTION=$(eval echo "${KPI_DESCRIPTION}")
      ACTUAL_KPI_ADDITIONAL_INFO=$(eval echo "${KPI_ADDITIONAL_INFO}")

      logDebug "ACTUAL_KPI_DESCRIPTION = ${ACTUAL_KPI_DESCRIPTION}"
      logDebug "ACTUAL_KPI_ADDITIONAL_INFO = ${ACTUAL_KPI_ADDITIONAL_INFO}"

      addKpi "${HOSTNAME_OSS}" "${ACTUAL_KPI_DESCRIPTION}" "${ACTUAL_KPI_ADDITIONAL_INFO}"
    fi
  done < ${TMP_DIR}/interfaces

  if [ ! -s ${WORK_DIR}/alarms ]
  then
    logInfo "No alarm condition detected for Network Interfaces"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/monitoring/job-monitor-network
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/jobs/monitoring/job-common/sh/job-common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
