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

  ENABLE_SIMULATION="$(getConfigParam GENERAL ENABLE_SIMULATION)"
  if [ $? -lt 0 ] || [ -z "${ENABLE_SIMULATION}" ]
  then
    logWarning "Unable to get parameter 'ENABLE_SIMULATION' in section 'GENERAL'"
  else
    if [ "${ENABLE_SIMULATION}" != "TRUE"]
    then
      ENABLE_SIMULATION=FALSE
    fi
  fi
  logDebug "ENABLE_SIMULATION = ${ENABLE_SIMULATION}"

  /var/opt/<%SIU_INSTANCE%>/KPI/scripts/KPIReport.sh
  if [ $? -ne 0 ]
  then
    logError "Command '/var/opt/<%SIU_INSTANCE%>/KPI/scripts/KPIReport.sh' failed"
    return 1
  fi

  for FILEPATH in $(2>/dev/null ls /var/opt/<%SIU_INSTANCE%>/KPI/reports/*_RequestType_KPI.dat)
  do
    logDebug "Processing file '${FILEPATH}'"

    FILENAME=$(basename ${FILEPATH})
    HOSTNAME=$(echo ${FILENAME} | cut -d "_" -f 1)
    logDebug "FILENAME = ${FILENAME}"
    logDebug "HOSTNAME = ${HOSTNAME}"

    HOSTNAME_OSS=$(getOssHostname ${HOSTNAME})
    if [ $? -ne 0 ]
    then
      logWarning "Unable to get OSS hostname. Set to original hostname"
      HOSTNAME_OSS=${HOSTNAME}
    fi
    logDebug "HOSTNAME_OSS = ${HOSTNAME_OSS}"

    NEW_FILENAME="hpedeg-service_kpis_request_types-${HOSTNAME_OSS}-"$(echo ${FILENAME} | cut -d "_" -f 2 | cut -c 1-12)
    logDebug "NEW_FILENAME = ${NEW_FILENAME}"

    if [ "${ENABLE_SIMULATION}" = "FALSE" ]
    then
      cp ${FILEPATH} /var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}
      RESULT=$?
    else
      cat ${FILEPATH} | awk -F \| -v seed=${RANDOM} '
      function randint(n)
      {
        return int(n * rand());
      }
      BEGIN
      {
        srand(seed);
      }
      {
        prefix = $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7;
        action = $5;

        if ((action == "DER") || (action == "getAuthentication") || (action == "postChallenge") || (action == "getPhoneNumber") || (action == "getEntitlement") || (action == "enablePushNotificationEntitlement") || (action == "getPhoneServicesAccountStatus") || (action == "updatePushToken")) {
          success = randint(1000);
          unsuccess = int(success * rand());
          average_time = sprintf("%.3f", rand());
          print prefix"|"success"|"unsuccess"|"average_time;
        }
        else {
          print $0;
        }
      }' > /var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}
      RESULT=$?
    fi

    if [ ${RESULT} -ne 0 ]
    then
      logError "Command 'cp ${FILEPATH} /var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}' failed"
      RETURN_CODE=1
    else
      logInfo "File '${FILEPATH}' successfully processed and moved to path '/var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}'"
      mv ${FILEPATH} ${FILEPATH}.processed
      if [ $? -ne 0 ]
      then
        logError "Command 'mv ${FILEPATH} ${FILEPATH}.processed' failed"
        RETURN_CODE=1
      fi
    fi
  done


  for FILEPATH in $(2>/dev/null ls /var/opt/<%SIU_INSTANCE%>/KPI/reports/*_ReturnCode_KPI.dat)
  do
    logDebug "Processing file '${FILEPATH}'"

    FILENAME=$(basename ${FILEPATH})
    HOSTNAME=$(echo ${FILENAME} | cut -d "_" -f 1)
    logDebug "FILENAME = ${FILENAME}"
    logDebug "HOSTNAME = ${HOSTNAME}"

    HOSTNAME_OSS=$(getOssHostname ${HOSTNAME})
    if [ $? -ne 0 ]
    then
      logWarning "Unable to get OSS hostname. Set to original hostname"
      HOSTNAME_OSS=${HOSTNAME}
    fi
    logDebug "HOSTNAME_OSS = ${HOSTNAME_OSS}"

    NEW_FILENAME="hpedeg-service_kpis_return_codes-${HOSTNAME_OSS}-"$(echo ${FILENAME} | cut -d "_" -f 2 | cut -c 1-12)
    logDebug "NEW_FILENAME = ${NEW_FILENAME}"


    cp ${FILEPATH} /var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}
    if [ $? -ne 0 ]
    then
      logError "Command 'cp ${FILEPATH} /var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}' failed"
      RETURN_CODE=1
    else
      logInfo "File '${FILEPATH}' successfully processed and moved to path '/var/opt/<%SIU_INSTANCE%>/KPI/OSS/${NEW_FILENAME}'"

      mv ${FILEPATH} ${FILEPATH}.processed
      if [ $? -ne 0 ]
      then
        logError "Command 'mv ${FILEPATH} ${FILEPATH}.processed' failed"
        RETURN_CODE=1
      fi
    fi
  done

  return ${RETURN_CODE}
}


SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/kpis/job-service-kpis
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/common/common.sh

EXIT_CODE=0

process
if [ $? -ne 0 ]
then
  EXIT_CODE=$?
  logWarning "Function 'proces' executed with errors"
fi

endOfExecution ${EXIT_CODE}
