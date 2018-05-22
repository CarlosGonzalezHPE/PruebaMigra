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

  getConfigSection DOMAINS > ${TMP_DIR}/domains
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'DOMAINS'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/domains ]
  then
    logWarning "No domain defined for monitoring"
    return 0
  fi

  while read DOMAIN
  do
    logDebug "Processing domain '${DOMAIN}'"

    DOMAIN_NAME="$(getConfigParam ${DOMAIN} DOMAIN_NAME)"
    if [ $? -ne 0 ] || [ -z "${DOMAIN_NAME}" ]
    then
      logError "Unable to get mandatory parameter 'DOMAIN_NAME' in section '${DOMAIN}'"
      echo ${CERTIFICATE} >> ${TMP_DIR}/failed_domains
      continue
    fi
    logDebug "DOMAIN_NAME = ${DOMAIN_NAME}"

    EXPECTED_IP_ADDRESSES="$(getConfigParam ${DOMAIN} EXPECTED_IP_ADDRESSES)"
    if [ $? -ne 0 ] || [ -z "${EXPECTED_IP_ADDRESSES}" ]
    then
      logError "Unable to get mandatory parameter 'EXPECTED_IP_ADDRESSES' in section '${DOMAIN}'"
      echo ${EXPECTED_IP_ADDRESSES} >> ${TMP_DIR}/failed_domains
      continue
    fi
    logDebug "EXPECTED_IP_ADDRESSES = ${EXPECTED_IP_ADDRESSES}"

    > ${TMP_DIR}/dig.${DOMAIN}.out_err 2>&1 dig +recurse ${DOMAIN_NAME} A

    cat ${TMP_DIR}/dig.${DOMAIN}.out_err | awk -v DOMAIN_NAME=${DOMAIN_NAME} 'BEGIN { answer_found = 0 } {
     if (answer_found == 0) {
        if (match($0, /ANSWER SECTION:/, v1)) {
          answer_found = 1;
        }
      } else if ($1 == DOMAIN_NAME".") {
        print $5;
      }
    }' > ${TMP_DIR}/resolved_ip_addresses.${DOMAIN}

    if [ $(echo ${EXPECTED_IP_ADDRESSES} | grep -f ${TMP_DIR}/resolved_ip_addresses.${DOMAIN} | wc -l) -lt 1 ]
    then
      logWarning "Alarm condition detected for domain '${DOMAIN}'"
      echo "${DOMAIN}" > ${TMP_DIR}/alarm_condition

      ALARM_ID="$(getConfigParam ${DOMAIN} ALARM_ID)"
      if [ $? -lt 0 ] || [ -z "${ALARM_ID}" ]
      then
        logError "Unable to get mandatory parameter 'ALARM_ID' in section '${DOMAIN}'"
        return 1
      fi
      logDebug "ALARM_ID = ${ALARM_ID}"

      ALARM_TEXT="$(getConfigParam ${DOMAIN} ALARM_TEXT)"
      if [ $? -lt 0 ] || [ -z "${ALARM_TEXT}" ]
      then
        logError "Unable to get mandatory parameter 'ALARM_TEXT' in section '${DOMAIN}'"
        return 1
      fi
      logDebug "ALARM_TEXT = ${ALARM_TEXT}"

      ACTUAL_ALARM_TEXT=$(eval echo "${ALARM_TEXT}")
      logDebug "ACTUAL_ALARM_TEXT = ${ACTUAL_ALARM_TEXT}"

      logAlarmError ${ALARM_ID} "${ACTUAL_ALARM_TEXT}"
    fi
  done < ${TMP_DIR}/domains

  if [ -f ${TMP_DIR}/failed_domains ]
  then
    RESULT_CODE=1
  fi

  if [ ! -f ${TMP_DIR}/alarm_condition ]
  then
    logInfo "No alarm condition detected"
  fi

  return ${RETURN_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/oam/job-dig
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
