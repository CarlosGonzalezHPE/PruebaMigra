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

  > ${TMP_DIR}/query-dsi-files.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -S ${DATABASE_SOKET_FILEPATH} -D ${DATABASE_NAME} -e "source ${SCRIPT_BASEDIR}/sql/query-dsi-files.sql"
  if [ $(cat ${TMP_DIR}/query-dsi-files.out_err | grep "ERROR" | wc -l) -gt 0 ]
  then
    logError "Command '${TMP_DIR}/query-dsi-files.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -p ${DATABASE_PASSWORD} -S ${DATABASE_SOKET_FILEPATH} -e \"source ${SCRIPT_BASEDIR}/sql/query-dsi-files.sql\"' failed"
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
      print timestamp_query ";" username ";" node_id ";" command ";" unique_id ";" realm ";VoWiFi;" request_id ";" result_code >> out_VoWIFI;
      print "UPDATE DEG_AUTOPROVISIONING SET PROVISIONED = \x27yes\x27 WHERE UNIQUE_ID = \x27"unique_id"\x27;" >> out_update;
    } else if (toupper(details) == "VOLTE") {
   	  print timestamp_query ";" username ";" node_id ";" command ";" unique_id ";" realm ";VoLTE;" request_id ";" result_code >> out_VoLTE;
    }
  }' ${TMP_DIR}/cdr-result.csv

  NUM_REGISTERS=0

  if [ -s ${VOLTE_FILEPATH} ]
  then
    mkdir -p ${OUTPUT_DIR}/LOG_VOLTE

    if [ -f ${OUTPUT_DIR}/LOG_VOLTE/$(basename ${VOLTE_FILEPATH}) ]
    then
      logError "File '${OUTPUT_DIR}/LOG_VOLTE/$(basename ${VOLTE_FILEPATH})' already exists"
      RES_CODE=1
    else
      let NUM_REGISTERS_VOLTE=$(wc -l ${VOLTE_FILEPATH} | cut -d " " -f 1)
      mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}/LOG_VOLTE

      if [ $? -ne 0 ]
      then
        logError "Command 'mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}/LOG_VOLTE' failed"
        RES_CODE=1
      else
        /var/opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles/sh/sendFiles.sh -o DSI_VOLTE

        RESULT=$?
        if [ ${RESULT} -eq 2 ]
        then
          logWarning "File '$(basename ${VOLTE_FILEPATH})' successfully generated but not sent as distribution is disabled"
        else
          if [ ${RESULT} -ne 0 ]
          then
            logError "Command '/var/opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles/sh/sendFiles.sh -o DSI_VOLTE' failed"
            RES_CODE=1
          else
            logInfo "File '$(basename ${VOLTE_FILEPATH})' successfully generated and sent"
            let NUM_REGISTERS=${NUM_REGISTERS}+${NUM_REGISTERS_VOLTE}
          fi
        fi
      fi
    fi
  else
    logWarning "File '${VOLTE_FILEPATH}' is empty"
  fi

  if [ -s ${VOWIFI_FILEPATH} ]
  then
    mkdir -p ${OUTPUT_DIR}/LOG_VOWIFI

    if [ -f ${OUTPUT_DIR}/LOG_VOWIFI/$(basename ${VOWIFI_FILEPATH}) ]
    then
      logError "File '${OUTPUT_DIR}/LOG_VOWIFI/$(basename ${VOWIFI_FILEPATH})' already exists"
      RES_CODE=1
    else
      let NUM_REGISTERS_VOWIFI=$(wc -l ${VOWIFI_FILEPATH} | cut -d " " -f 1)
      mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}/LOG_VOWIFI
      if [ $? -ne 0 ]
      then
        logError "Command 'mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}/LOG_VOWIFI' failed"
        RES_CODE=1
      else
        /var/opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles/sh/sendFiles.sh -o DSI_VOWIFI

        RESULT=$?
        if [ ${RESULT} -eq 2 ]
        then
          logWarning "File '$(basename ${VOWIFI_FILEPATH})' successfully generated but not sent as distribution is disabled"
        else
          if [ ${RESULT} -ne 0 ]
          then
            logError "Command '/var/opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles/sh/sendFiles.sh -o DSI_VOWIFI' failed"
            RES_CODE=1
          else
            logInfo "File '$(basename ${VOWIFI_FILEPATH})' successfully generated and sent"
            let NUM_REGISTERS=${NUM_REGISTERS}+${NUM_REGISTERS_VOWIFI}
          fi
        fi
      fi
    fi
  else
    logWarning "File '${VOWIFI_FILEPATH}' is empty"
  fi

  HOSTNAME_OSS=$(getOssHostname $(hostname | cut -d "." -f 1))
  if [ $? -ne 0 ]
  then
    logError "Unable to get OSS hostname"
    RES_CODE=1
  else
    logDebug "HOSTNAME_OSS = ${HOSTNAME_OSS}"

    KPI_FILENAME=hpedeg-service_kpis_provisioning-${HOSTNAME_OSS}-$(date +"%Y%m%d%H%M")
    echo ${NUM_REGISTERS} > ${TMP_DIR}/${KPI_FILENAME}

    mv ${TMP_DIR}/${KPI_FILENAME} /var/opt/<%SIU_INSTANCE%>/KPI/OSS
    if [ $? -ne 0 ]
    then
      logError "Command 'mv ${TMP_DIR}/${KPI_FILENAME} /var/opt/<%SIU_INSTANCE%>/KPI/OSS' failed"
      RES_CODE=1
    fi
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

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/provisioning/job-dsi-files
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/common/common.sh

EXIT_CODE=0
CURRENT_DATE=$(date +%Y%m%d)

process
if [ $? -ne 0 ]
then
  EXIT_CODE=$?
  logWarning "Function 'process' executed with errors"
fi

endOfExecution ${EXIT_CODE}
