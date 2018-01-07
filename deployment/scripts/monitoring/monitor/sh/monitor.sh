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

  ALARMS_DIR="$(getConfigParam ALARMS DIR)"
  if [ $? -lt 0 ] || [ -z ${ALARMS_DIR} ]
  then
    logError "Unable to get mandatory parameter 'DIR' in section 'ALARMS'"
    return 1
  fi
  logDebug "ALARMS_DIR = ${ALARMS_DIR}"

  ALARMS_FILENAME="$(getConfigParam ALARMS FILENAME)"
  if [ $? -lt 0 ] || [ -z "${ALARMS_FILENAME}" ]
  then
    logError "Unable to get mandatory parameter 'FILENAME' in section 'ALARMS'"
    return 1
  fi
  logDebug "ALARMS_FILENAME = ${ALARMS_FILENAME}"

  getConfigSection MONITORS > ${TMP_DIR}/monitors
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'MONITORS'"
    return 1
  fi

  while read MONITOR
  do
    logInfo "Fetching alarm file for monitor '${MONITOR}'"

    logDebug "Looking for file '<%SCRIPTS_DIR%>/monitoring/monitor-${MONITOR}/tmp/alarms'"

    if [ -f <%SCRIPTS_DIR%>/monitoring/monitor-${MONITOR}/tmp/alarms ]
    then
      mv <%SCRIPTS_DIR%>/monitoring/monitor-${MONITOR}/tmp/alarms ${TMP_DIR}/alarms.${MONITOR}
      if [ $? -ne 0 ]
      then
        logError "Command 'mv <%SCRIPTS_DIR%>/monitoring/monitor-${MONITOR}/tmp/alarms ${TMP_DIR}/alarms.${MONITOR}' failed"
      fi
      cat ${TMP_DIR}/alarms.${MONITOR} >> ${TMP_DIR}/alarms.tmp

      logWarning "Fetched alarm file for monitor '${MONITOR}'"
    else
      logInfo "No alarm file available for monitor '${MONITOR}'"
    fi
  done < ${TMP_DIR}/monitors

  if [ ! -s ${TMP_DIR}/alarms.tmp ]
  then
    logWarning "No alarms reported"
    return 0
  fi

  while read ALARM_DATA
  do
    ALARM_ID=$(getNextAlarmId)
    if [ $? -ne 0 ]
    then
      logError "Unable to get next Alarm Id"
      return 1
    fi

    echo ${ALARM_ID}"#"${ALARM_DATA} >> ${TMP_DIR}/alarms
  done < ${TMP_DIR}/alarms.tmp

  ACTUAL_ALARMS_FILENAME=$(eval echo "${ALARMS_FILENAME}")
  logDebug "ACTUAL_ALARMS_FILENAME = ${ACTUAL_ALARMS_FILENAME}"

  mv ${TMP_DIR}/alarms ${ALARMS_DIR}/${ACTUAL_ALARMS_FILENAME}
  if [ $? -ne 0 ]
  then
    logError "Command 'mv ${TMP_DIR}/alarms ${ALARMS_DIR}/${ACTUAL_ALARMS_FILENAME}}' failed"
    return 1
  fi

  logInfo "Alarms file '${ACTUAL_ALARMS_FILENAME}' created and moved to directory '${ALARMS_DIR}'"
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/monitoring/monitor
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
