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

  RETURN_CODE=0

  HOSTNAME_OSS=$(getOssHostname $(hostname | cut -d "." -f 1))
  if [ $? -ne 0 ]
  then
    logError "Unable to get OSS hostname"
    return 1
  fi
  logDebug "HOSTNAME_OSS = ${HOSTNAME_OSS}"

  KPI_FILE_PATH=$(getConfigParam DATA KPI_FILE_PATH)
  if [ ${?} -ne 0 ] || [ -z ${KPI_FILE_PATH} ]
  then
    logWarning "Unable to get mandatory parameter 'KPI_FILE_PATH' in section 'DATA'"
    return 1
  fi
  logDebug "KPI_FILE_PATH = ${KPI_FILE_PATH}"

  ACTUAL_KPI_FILE_PATH=$(eval echo "${KPI_FILE_PATH}")
  logDebug "ACTUAL_KPI_FILE_PATH = ${ACTUAL_KPI_FILE_PATH}"

  DATABASE_NAME=$(getConfigParam DATA DATABASE_NAME)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_NAME} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi
  logDebug "DATABASE_NAME = ${DATABASE_NAME}"

  DATABASE_USERNAME=$(getConfigParam DATA DATABASE_USERNAME)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_USERNAME} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi
  logDebug "DATABASE_USERNAME = ${DATABASE_USERNAME}"

  DATABASE_PASSWORD=$(getConfigParam DATA DATABASE_PASSWORD)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_PASSWORD} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi
  logDebug "DATABASE_PASSWORD = ${DATABASE_PASSWORD}"

  DATABASE_SOKET_FILEPATH=$(getConfigParam DATA DATABASE_SOKET_FILEPATH)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_SOKET_FILEPATH} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi
  logDebug "DATABASE_SOKET_FILEPATH = ${DATABASE_SOKET_FILEPATH}"

  if [ ! -e ${DATABASE_SOKET_FILEPATH} ]
  then
    logError "File ' ${DATABASE_SOKET_FILEPATH}' not found. MariasDB instance for App Servers may be down"
    return 1
  fi

  MYSQL_PATH=$(getConfigParam DATA MYSQL_PATH)
  if [ ${?} -ne 0 ] || [ -z ${MYSQL_PATH} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi

  logInfo "Computing Number of APNS pending notifications"

  > ${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -S ${DATABASE_SOKET_FILEPATH} -D ${DATABASE_NAME} --execute "select count(*) from deg_apns_message_to_be_sent"

  cat ${TMP_DIR}/query-dsi-files.out_err | tail -n 1 | awk ' BEGIN { header_found = 0 } {
    if (header_found == 0) {
      if ($0 ~ "count(*)") {
        header_found = 1;
      }
    } else {
      if (match($0, /^[0-9]+$/)) {
        print $0;
        exit;
      }
    }
  }' > ${TMP_DIR}/num_pending_notifs

  if [ ! -s ${TMP_DIR}/num_pending_notifs ]
  then
    logError "Unable to compute number of pending APNS notifications"
    return 1
  fi

  let NUM_PENDING_NOTIFS=$(cat ${TMP_DIR}/num_pending_notifs)
  logDebug "NUM_PENDING_NOTIFS = ${NUM_PENDING_NOTIFS}"

  echo > ${ACTUAL_KPI_FILE_PATH}
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
    logError "Command 'echo > ${ACTUAL_KPI_FILE_PATH}' failed"
  fi

  getConfigSection ALARM_LIMITS > ${TMP_DIR}/alarm_limits
  if [ $? -lt 0 ] || [ ! -s ${TMP_DIR}/alarm_limits ]
  then
    logInfo "No alarm limit defined"
    return ${RETURN_CODE}
  fi

  while read ALARM_LIMIT
  do
    logDebug "Checking Alarm Limit '${ALARM_LIMIT}'"

    THRESHOLD_PENDING_NOTIF="$(getConfigParam ${ALARM_LIMIT} THRESHOLD_PENDING_NOTIF)"
    if [ $? -lt 0 ] || [ -z "${THRESHOLD_PENDING_NOTIF}" ]
    then
      logError "Unable to get mandatory parameter 'THRESHOLD_PENDING_NOTIF' in section '${ALARM_LIMIT}'"
      return 1
    fi
    logDebug "THRESHOLD_PENDING_NOTIF = ${THRESHOLD_PENDING_NOTIF}"

    if [ ${NUM_PENDING_NOTIFS} -ge ${THRESHOLD_PENDING_NOTIF} ]
    then
      logWarning "Alarm condition detected"

      ALARM_ID="$(getConfigParam ${ALARM_LIMIT} ALARM_ID)"
      if [ $? -lt 0 ] || [ -z "${ALARM_ID}" ]
      then
        logError "Unable to get mandatory parameter 'ALARM_ID' in section '${ALARM_LIMIT}'"
        return 1
      fi
      logDebug "ALARM_ID = ${ALARM_ID}"

      ALARM_TEXT="$(getConfigParam ${ALARM_LIMIT} ALARM_TEXT)"
      if [ $? -lt 0 ] || [ -z "${ALARM_TEXT}" ]
      then
        logError "Unable to get mandatory parameter 'ALARM_TEXT' in section '${ALARM_LIMIT}'"
        return 1
      fi
      logDebug "ALARM_TEXT = ${ALARM_TEXT}"

      ACTUAL_ALARM_TEXT=$(eval echo "${ALARM_TEXT}")
      logDebug "ACTUAL_ALARM_TEXT = ${ACTUAL_ALARM_TEXT}"

      logAlarmError ${ALARM_ID} "${ACTUAL_ALARM_TEXT}"
    fi
  done < ${TMP_DIR}/alarm_limits

  return ${RETURN_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/oam/job-apns
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/common/common.sh

EXIT_CODE=0
CURRENT_DATE=$(date +%Y%m%d)

process
RESULT=$?
if [ ${RESULT} -ne 0 ]
then
  EXIT_CODE=${RESULT}
  logWarning "Function 'process' executed with errors"
  if [ "${ALARMING_ENABLED}" = "TRUE" ]
  then
    logAlarmError DegAlarm10.9 "Job execution failed (job-apns)"
  fi
fi

endOfExecution ${EXIT_CODE}
