#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

function process
{
  logDebug "Executing function 'process'"

  SITE_SUFFIX=$(getConfigParam GENERAL SITE_SUFFIX)
  if [ ${?} -ne 0 ] || [ -z ${SITE_SUFFIX} ]
  then
    logWarning "Unable to get mandatory parameter 'SITE_SUFFIX' in section 'GENERAL'"
    return 1
  fi

  DATABASE_NAME=$(getConfigParam DATA DATABASE_NAME)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_NAME} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi

  DATABASE_USERNAME=$(getConfigParam DATA DATABASE_USERNAME)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_USERNAME} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi

  DATABASE_PASSWORD=$(getConfigParam DATA DATABASE_PASSWORD)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_PASSWORD} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
    return 1
  fi

  DATABASE_SOKET_FILEPATH=$(getConfigParam DATA DATABASE_SOKET_FILEPATH)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_SOKET_FILEPATH} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'DATA'"
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

  awk -F \; -v out_VoWIFI=${VOLTE_FILEPATH} -v out_VoLTE=${VOWIFI_FILEPATH} '{
    timestamp_query = $1;
    timestamp_system = $2;
    username = $3;
    node_id = $4;
    command = $5;
    unique_id = $6;
    Realm = $7;
    Details = $8;
    Request_id = $9;
    Result_code = $10;
    Provisioned = $11;
    if (Details == "VoWIFI") {
      	print timestamp_query ";" timestamp_system ";" username ";" node_id ";" command ";" unique_id ";" Realm ";" Details ";" Request_id ";" Resultcode ";" Provisioned ";" >> out_VoWIFI;
    } else if (Details == "VoLTE") {
   	print timestamp_query ";" timestamp_system ";" username ";" node_id ";" command ";" unique_id ";" Realm ";" Details ";" Request_id ";" Resultcode ";" Provisioned ";"  >> out_VoLTE;
    }
  }' ${TMP_DIR}/cdr-result.csv

  if [ -s ${VOLTE_FILEPATH} ]
  then
    if [ -f ${OUTPUT_DIR}/$(basename ${VOLTE_FILEPATH}) ]
    then
      logError "File '${OUTPUT_DIR}/$(basename ${VOLTE_FILEPATH})' already exists"
      RES_CODE=1
    else
      mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}
      if [ $? -ne 0 ]
      then
        logError "Command of file 'mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}' failed"
        RES_CODE=1
      else
        /opt/<%SIU_INSTANCE%>/scripts/sendFiles/sh/sendFiles.sh VOLTE ${OUTPUT_DIR}/$(basename ${VOLTE_FILEPATH})
        if [ $? -ne 0 ]
        then
          logError "Distribution of file '$(basename ${VOLTE_FILEPATH}' failed"
          RES_CODE=1
        else
          logInfo "File '$(basename ${VOLTE_FILEPATH}' succesfully sent"
        fi
      fi
    fi
  else
    logWarning "File '${VOLTE_FILEPATH}' is empty"
  fi

  if [ -s ${VOWIFI_FILEPATH} ]
  then
    if [ -f ${OUTPUT_DIR}/$(basename ${VOWIFI_FILEPATH}) ]
    then
      logError "File '${OUTPUT_DIR}/$(basename ${VOWIFI_FILEPATH})' already exists"
      RES_CODE=1
    else
      mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}
      if [ $? -ne 0 ]
      then
        logError "Command of file 'mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}' failed"
        RES_CODE=1
      else
        /opt/<%SIU_INSTANCE%>/scripts/sendFiles/sh/sendFiles.sh VOWIFI ${OUTPUT_DIR}/$(basename ${VOWIFI_FILEPATH})
        if [ $? -ne 0 ]
        then
          logError "Distribution of file '$(basename ${VOWIFI_FILEPATH}' failed"
          RES_CODE=1
        else
          logInfo "File '$(basename ${VOWIFI_FILEPATH}' succesfully sent"
        fi
      fi
    fi
  else
    logWarning "File '${VOWIFI_FILEPATH}' is empty"
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
