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

  getConfigSection ALARM_LIMITS > ${TMP_DIR}/alarm_limits
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'ALARM_LIMITS'"
    return 1
  fi

  getConfigSection CERTIFICATES > ${TMP_DIR}/certificates
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'CERTIFICATES'"
    return 1
  fi

  while read CERTIFICATE
  do
    logDebug "Processing certificate '${CERTIFICATE}'"

    FILEPATH="$(getConfigParam ${CERTIFICATE} FILEPATH)"
    if [ $? -ne 0 ]
    then
      logError "Unable to get mandatory parameter 'FILEPATH' in section '${CERTIFICATE}'"
      RETURN_CODE=1
      continue
    fi
    logDebug "FILEPATH = ${FILEPATH}"

    PASSPHRASE="$(getConfigParam ${CERTIFICATE} PASSPHRASE)"
    if [ $? -ne 0 ]
    then
      logError "Unable to get mandatory parameter 'PASSPHRASE' in section '${CERTIFICATE}'"
      RETURN_CODE=1
      continue
    fi
    logDebug "PASSPHRASE = ${PASSPHRASE}"

     > ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "#!/bin/bash"
    >> ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "/usr/bin/expect << EOD"
    >> ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "spawn keytool -v -list -keystore ${FILEPATH}"
    >> ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "set timeout 4"
    >> ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "expect \"Enter keystore password:\""
    >> ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "send \"${PASSPHRASE}\r\""
    >> ${TMP_DIR}/keytool-${CERTIFICATE}.sh echo "EOD"

    chmod 744 ${TMP_DIR}/keytool-${CERTIFICATE}.sh

    > ${TMP_DIR}/keytool-${CERTIFICATE}.out_err 2>&1 ${TMP_DIR}/keytool-${CERTIFICATE}.sh

    CURRENT_TIMESTAMP=$(date +"%s")
    EXPIRATION_TIMESTAMP=$(date +"%s" -d "$(cat ${TMP_DIR}/keytool-${CERTIFICATE}.out_err | awk '/Valid from:/ { match($0, /.*until: ([: a-zA-Z0-9]+)/, v); print v[1]; }')")

    REMAINING_DAYS=$(echo "(${EXPIRATION_TIMESTAMP}-${CURRENT_TIMESTAMP})/24/3600" | bc)

    while read ALARM_LIMIT
    do
      THRESHOLD_DAYS="$(getConfigParam ${ALARM_LIMIT} THRESHOLD_DAYS)"
      if [ $? -lt 0 ] || [ -z ${THRESHOLD_DAYS} ]
      then
        logError "Unable to get mandatory parameter 'THRESHOLD_DAYS' in section '${ALARM_LIMIT}'"
        return 1
      fi
      logDebug "THRESHOLD_DAYS = ${THRESHOLD_DAYS}"

      if [ ${REMAINING_DAYS} -le ${THRESHOLD_DAYS} ]
      then
        logWarning "Alarm condition detected for certificate '${CERTIFICATE}'"

        ALARM_ID="$(getConfigParam ${ALARM_LIMIT} ALARM_ID)"
        if [ $? -lt 0 ] || [ -z ${THRESHOLD_DAYS} ]
        then
          logError "Unable to get mandatory parameter 'ALARM_ID' in section '${ALARM_LIMIT}'"
          return 1
        fi
        logDebug "ALARM_ID = ${ALARM_ID}"

        ALARM_TEXT="$(getConfigParam ${ALARM_LIMIT} ALARM_TEXT)"
        if [ $? -lt 0 ] || [ -z ${THRESHOLD_DAYS} ]
        then
          logError "Unable to get mandatory parameter 'ALARM_TEXT' in section '${ALARM_LIMIT}'"
          return 1
        fi
        logDebug "ALARM_TEXT = ${ALARM_TEXT}"

        ACTUAL_ALARM_TEXT=$(eval echo "${ALARM_TEXT}")

        logAlarmError ${ALARM_ID} "${ACTUAL_ALARM_TEXT}"
        break
      fi
    done < ${TMP_DIR}/alarm_limits
  done < ${TMP_DIR}/certificates

  return ${RETURN_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/oam/job-cert
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
    logAlarmError DegAlarm10.9 "Job execution failed (job-cert)"
  fi
fi

endOfExecution ${EXIT_CODE}
