#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

function process
{
  logDebug "Executing function 'process'"

  OUTPUT_DIR=$(getConfigParam GENERAL OUTPUT_DIR)
  if [ ${?} -ne 0 ] || [ -z ${OUTPUT_DIR} ]
  then
    logWarning "Unable to get mandatory parameter 'OUTPUT_DIR' in section 'GENERAL'"
    return 1
  fi
  logDebug "OUTPUT_DIR = ${OUTPUT_DIR}"

  SITE_SUFFIX=$(getConfigParam GENERAL SITE_SUFFIX)
  if [ ${?} -ne 0 ] || [ -z ${SITE_SUFFIX} ]
  then
    logWarning "Unable to get mandatory parameter 'SITE_SUFFIX' in section 'GENERAL'"
    return 1
  fi
  logDebug "SITE_SUFFIX = ${SITE_SUFFIX}"

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

  > ${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -S ${DATABASE_SOKET_FILEPATH} -D ${DATABASE_NAME} -e "source ${SCRIPT_BASEDIR}/sql/query.sql"
  if [ $(cat ${TMP_DIR}/query.out_err | grep "ERROR" | wc -l) -gt 0 ]
  then
    logError "Command '${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -p ${DATABASE_PASSWORD} -S ${DATABASE_SOKET_FILEPATH} -e \"source ${SCRIPT_BASEDIR}/sql/query.sql\"' failed"
    return 1
  fi

  VOLTE_FILEPATH=${TMP_DIR}/cdr-volte-$(date +"%Y%m%d_%H%M")${SITE_SUFFIX}.log
  VOWIFI_FILEPATH=${TMP_DIR}/cdr-vowifi-$(date +"%Y%m%d_%H%M")${SITE_SUFFIX}.log

  if [ -f ${VOLTE_FILEPATH} ]
  then
    logError "File '${VOLTE_FILEPATH}' already exists"
    return 1
  fi

  if [ -f ${VOWIFI_FILEPATH} ]
  then
    logError "File '${VOWIFI_FILEPATH}' already exists"
    return 1
  fi

  RES_CODE=0

  UPDATE_FILEPATH=${TMP_DIR}/updateDEG_AUTOPROVISIONING.sql

  awk -F \; -v out_VoWIFI=${VOWIFI_FILEPATH} -v out_VoLTE=${VOLTE_FILEPATH} -v out_update=${UPDATE_FILEPATH} '{
    timestamp_query = $1;
    username = $2;
    node_id = $3;
    command = $4;
    unique_id = $5;
    realm = $6;
    details = $7;
    request_id = $8;
    result_code = $9;
    provisioned = $10;
    if (toupper(details) == "VOWIFI") {
      print timestamp_query ";" timestamp_system ";" username ";" node_id ";" command ";" unique_id ";" realm ";VoWiFi;" request_id ";" result_code >> out_VoWIFI;
      print "UPDATE DEG_AUTOPROVISIONING SET PROVISIONED = \x27yes\x27 WHERE UNIQUE_ID = \x27"unique_id"\x27;" >> out_update;
    } else if (toupper(details) == "VOLTE") {
   	  print timestamp_query ";" timestamp_system ";" username ";" node_id ";" command ";" unique_id ";" realm ";VoLTE;" request_id ";" result_code >> out_VoLTE;
    }
  }' ${TMP_DIR}/cdr-result.csv

  if [ -s ${VOLTE_FILEPATH} ]
  then
    if [ -f ${OUTPUT_DIR}/LOG_VOLTE/$(basename ${VOLTE_FILEPATH}) ]
    then
      logError "File '${OUTPUT_DIR}/LOG_VOLTE/$(basename ${VOLTE_FILEPATH})' already exists"
      RES_CODE=1
    else
      mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}/LOG_VOLTE
      if [ $? -ne 0 ]
      then
        logError "Command of file 'mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}/LOG_VOLTE' failed"
        RES_CODE=1
      else
        /opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles/sh/sendFiles.sh -o DSI_VOLTE ${OUTPUT_DIR}/LOG_VOLTE/$(basename ${VOLTE_FILEPATH})
        if [ $? -ne 0 ]
        then
          logError "Distribution of file '$(basename ${VOLTE_FILEPATH})' failed"
          RES_CODE=1
        else
          logInfo "File '$(basename ${VOLTE_FILEPATH})' succesfully sent"
        fi
      fi
    fi
  else
    logWarning "File '${VOLTE_FILEPATH}' is empty"
  fi

  if [ -s ${VOWIFI_FILEPATH} ]
  then
    if [ -f ${OUTPUT_DIR}/LOG_VOWIFI/$(basename ${VOWIFI_FILEPATH}) ]
    then
      logError "File '${OUTPUT_DIR}/LOG_VOWIFI/$(basename ${VOWIFI_FILEPATH})' already exists"
      RES_CODE=1
    else
      mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}/LOG_VOWIFI
      if [ $? -ne 0 ]
      then
        logError "Command of file 'mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}/LOG_VOWIFI' failed"
        RES_CODE=1
      else
        /opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles/sh/sendFiles.sh -o DSI_VOWIFI ${OUTPUT_DIR}/LOG_VOWIFI/$(basename ${VOWIFI_FILEPATH})
        if [ $? -ne 0 ]
        then
          logError "Distribution of file '$(basename ${VOWIFI_FILEPATH})' failed"
          RES_CODE=1
        else
          logInfo "File '$(basename ${VOWIFI_FILEPATH})' succesfully sent"
        fi
      fi
    fi
  else
    logWarning "File '${VOWIFI_FILEPATH}' is empty"
  fi

  if [ -s ${UPDATE_FILEPATH} ]
  then
    logInfo "Updating table 'DEG_AUTOPROVISIONING'"
    > ${TMP_DIR}/updateDEG_AUTOPROVISIONING.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -S ${DATABASE_SOKET_FILEPATH} -D ${DATABASE_NAME} -e "source ${UPDATE_FILEPATH}"
    if [ $(cat ${TMP_DIR}/updateDEG_AUTOPROVISIONING.out_err | grep "ERROR" | wc -l) -gt 0 ]
    then
      logError "Command '${TMP_DIR}/updateDEG_AUTOPROVISIONING.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -S ${DATABASE_SOKET_FILEPATH} -D ${DATABASE_NAME} -e \"source ${UPDATE_FILEPATH}\"' failed"
      return 1
    fi
  fi

  return ${RES_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/opt/<%SIU_INSTANCE%>/scripts/provisioning/generateAutoprovisioningFiles
export SCRIPT_BASEDIR

. /opt/<%SIU_INSTANCE%>/scripts/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
