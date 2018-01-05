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
    MOUNT_POINT=$(echo ${LINE} | cut -d ":" -f 1)

    logInfo "Checking usage of Filesystem '${MOUNT_POINT}'"

    if [ $(mount | grep ${MOUNT_POINT} | wc -l) -lt 1 ]
    then
      logWarning "Filesystem '${MOUNT_POINT}' is not mounted"
      continue
    fi

    let USAGE=$(df -h ${FS} | awk -v fs="${MOUNT_POINT}" '{ if ($6 ~ fs) { print $5 } else if ($5 ~ fs) { print $4 }}' | tr -d "%")

    echo ${LINE} | cut -d ":" -f 2 | sed -e "s|,| |g" | while read ENTRY
    do
      let LIMIT=$(echo ${ENTRY} | cut -d "-" -f 1)
      SEVERITY=$(echo ${ENTRY} | cut -d "-" -f 2)

      if [ ${USAGE} -ge ${LIMIT} ]
      then
        ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
        ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

        addAlarm "$(hostname | cut -d "." -f 1) filesystem ${MOUNT_POINT}" "${SEVERITY}" "${ALARM_DESCRIPTION}" "${ALARM_ADDITIONAL_INFO}"
        if [ $? -ne 0 ]
        then
          logError "Unable to add alarm"
          return 1
        fi

        break
      else
        logDebug "No alarm condition detected for filesystem '${MOUNT_POINT}'"
      fi
    done
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
