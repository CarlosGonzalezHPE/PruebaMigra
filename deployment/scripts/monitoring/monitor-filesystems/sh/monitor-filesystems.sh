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

  getConfigSection FILESYSTEMS > ${TMP_DIR}/filesystems
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'FILESYSTEMS'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/filesystems ]
  then
    logWarning "No filesystems to be monitorized"
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

  while read FILESYSTEM
  do
    MOUNT_POINT="$(getConfigParam ${FILESYSTEM} MOUNT_POINT)"
    if [ $? -lt 0 ] || [ -z "${ALARM_DESCRIPTION}" ]
    then
      logError "Unable to get mandatory parameter 'MOUNT_POINT' in section '${FILESYSTEM}'"
      return 1
    fi
    logDebug "MOUNT_POINT = ${MOUNT_POINT}"

    logInfo "Checking usage of Filesystem '${MOUNT_POINT}'"

    getConfigSection ${FILESYSTEM}_LIMITS > ${TMP_DIR}/${FILESYSTEM}.limits
    if [ $? -lt 0 ]
    then
      logError "Unable to get mandatory section '${FILESYSTEM}_LIMITS'"
      return 1
    fi

    if [ $(mount | grep ${MOUNT_POINT} | wc -l) -lt 1 ]
    then
      logWarning "Filesystem '${MOUNT_POINT}' is not mounted"
      continue
    fi

    let USAGE=$(df -h ${FS} | awk -v fs="${MOUNT_POINT}" '{ if ($6 ~ fs) { print $5 } else if ($5 ~ fs) { print $4 }}' | tr -d "%")
    logDebug "USAGE = ${USAGE}"

    while read LIMIT
    do
      THRESHOLD="$(getConfigParam ${FILESYSTEM}_${LIMIT} THRESHOLD)"
      if [ $? -lt 0 ] || [ -z ${THRESHOLD} ]
      then
        logError "Unable to get mandatory parameter 'THRESHOLD' in section '${FILESYSTEM}_${LIMIT}'"
        return 1
      fi
      logDebug "THRESHOLD = ${THRESHOLD}"

      SEVERITY="$(getConfigParam ${FILESYSTEM}_${LIMIT} SEVERITY)"
      if [ $? -lt 0 ] || [ -z ${SEVERITY} ]
      then
        logError "Unable to get mandatory parameter 'SEVERITY' in section '${FILESYSTEM}_${LIMIT}'"
        return 1
      fi
      logDebug "SEVERITY = ${SEVERITY}"

      if [ ${USAGE} -ge ${THRESHOLD} ]
      then
        ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
        ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

        logDebug "ACTUAL_ALARM_DESCRIPTION = ${ACTUAL_ALARM_DESCRIPTION}"
        logDebug "ACTUAL_ALARM_ADDITIONAL_INFO"

        addAlarm "$(hostname | cut -d "." -f 1)-filesystem-${MOUNT_POINT}" "${SEVERITY}" "${ACTUAL_ALARM_DESCRIPTION}" "${ACTUAL_ALARM_ADDITIONAL_INFO}"
        if [ $? -ne 0 ]
        then
          logError "Unable to add alarm"
          return 1
        fi

        break
      fi

      logInfo "No alarm condition detected for filesystem '${MOUNT_POINT}'"
    done < ${TMP_DIR}/${FILESYSTEM}.limits
  done < ${TMP_DIR}/filesystems
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/monitoring/monitor-filesystems
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/monitoring/common/common.sh

process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
