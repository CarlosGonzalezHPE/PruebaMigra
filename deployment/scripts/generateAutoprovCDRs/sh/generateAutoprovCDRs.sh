#!/bin/bash
#-------------------------------------------------------------------------------
# Orange Spain DEG
#
# HPE CMS Iberia, 2017
#-------------------------------------------------------------------------------
# Descripcion: Script comun
#-------------------------------------------------------------------------------


function process
{
  logDebug "Executing function 'process'"

  DATABASE_NAME=$(getConfigParam DATA DATABASE_NAME)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_NAME} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'GENERAL'"
    endOfExecution 1
  fi
 DATABASE_USERNAME=$(getConfigParam DATA DATABASE_USERNAME)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_USERNAME} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'GENERAL'"
    endOfExecution 1
  fi
DATABASE_PASSWORD=$(getConfigParam DATA DATABASE_PASSWORD)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_PASSWORD} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'GENERAL'"
    endOfExecution 1
  fi
DATABASE_SOKET_FILEPATH=$(getConfigParam DATA DATABASE_SOKET_FILEPATH)
  if [ ${?} -ne 0 ] || [ -z ${DATABASE_SOKET_FILEPATH} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'GENERAL'"
    endOfExecution 1
  fi
MYSQL_PATH=$(getConfigParam DATA MYSQL_PATH)
  if [ ${?} -ne 0 ] || [ -z ${MYSQL_PATH} ]
  then
    logWarning "Unable to get mandatory parameter 'DATABASE_NAME' in section 'GENERAL'"
    endOfExecution 1
  fi

  > ${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -S ${DATABASE_SOKET_FILEPATH} -D ${DATABASE_NAME} -e "source ${SCRIPT_BASEDIR}/sql/query.sql"
  if [ $(cat ${TMP_DIR}/query.out_err | grep "ERROR" | wc -l) -gt 0 ]
  then
    logError "Command '${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -p ${DATABASE_PASSWORD} -S ${DATABASE_SOKET_FILEPATH} -e \"source ${SCRIPT_BASEDIR}/sql/query.sql\"' failed"
    endOfExecution 1
  fi

  VOLTE_FILEPATH=${TMP_DIR}/cdr-volte-$(date +"%Y%m%d_%H%M")${SITE_INDEX}.log
  VOWIFI_FILEPATH=${TMP_DIR}/cdr-vowifi-$(date +"%Y%m%d_%H%M")${SITE_INDEX}.log

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
 ################################################33 ... formateo fichero

  if [ -s ${VOLTE_FILEPATH} ]
  then
    mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}
  fi
   # /opt/SIU_MANAGER/scripts/distribution/sh/distribute.sh VOLTE ${OUTPUT_DIR}/$(basename ${VOLTE_FILEPATH})
  #  if [ $? -ne 0 ]
   # then
   #  logError "Distribution of file '$(basename ${VOLTE_FILEPATH}' failed"
 # else
  #  logWarning "File '${VOLTE_FILEPATH}' is empty"
 # fi
 

  if [ -s ${VOWIFI_FILEPATH} ]
  then
    mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}
  fi
#    /opt/SIU_MANAGER/scripts/distribution/sh/distribute.sh VOWIFI ${OUTPUT_DIR}/$(basename ${VOWIFI_FILEPATH})
  #  if [ $? -ne 0 ]
   # then
    #  logError "Distribution of file '$(basename ${VOWIFI_FILEPATH}' failed"
 # else
  #  logWarning "File '${VOWIFI_FILEPATH}' is empty"
 # fi
}


#
# Main
#

SCRIPT_BASEDIR=/opt/SIU_MANAGER/scripts/generateAutoprovCDRs
export SCRIPT_BASEDIR

. /opt/SIU_MANAGER/scripts/common/common.sh


process

endOfExecution
