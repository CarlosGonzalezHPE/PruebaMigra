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

  ...

  > ${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -p ${DATABASE_PASSWORD} -S ${DATABASE_SOKET_FILEPATH} -e "source ${SCRIPT_BASEDIR}/sql/query.sql"
  if [ $(cat ${TMP_DIR}/query.out | grep "ERROR" | wc -l) -gt 0 ]
  then
    logError "Command '${TMP_DIR}/query.out_err 2>&1 ${MYSQL_PATH} -u ${DATABASE_USERNAME} -p ${DATABASE_PASSWORD} -S ${DATABASE_SOKET_FILEPATH} -e \"source ${SCRIPT_BASEDIR}/sql/query.sql\"' failed"
    endOfExecution 1
  fi

  VOLTE_FILEPATH=${TMP_DIR}/cdr-volte-$(date +"%Y%m%d_%H%M")${SITE_INDEX}
  VOWIFI_FILEPATH=${TMP_DIR}/cdr-vowifi-$(date +"%Y%m%d_%H%M")${SITE_INDEX}

  awk -F \; -v out_VoWIFI=${VOLTE_FILEPATH} -v out_VoLTE=${VOWIFI_FILEPATH} '{
    timestamp_query = $1;
    timestamp_system = $2;
    username = $3;
    node_id = $4;

    ...

    if (command == "VOWIF") {
      print timestamp_query ";" timestamp_system ";" ... >> out_VoWIFI;
    } else if (command == "VOLTE") {
      print timestamp_query ";" timestamp_system ";" ... >> out_VoLTE;
    }
  }'${TMP_DIR}/query.out_err
  ... formateo fichero

  if [ -s ${VOLTE_FILEPATH}]
  then
    mv ${VOLTE_FILEPATH} ${OUTPUT_DIR}

    /opt/SIU_MANAGER/scripts/distribution/sh/distribute.sh VOLTE ${OUTPUT_DIR}/$(basename ${VOLTE_FILEPATH})
    if [ $? -ne 0 ]
    then
      logError "Distribution of file '$(basename ${VOLTE_FILEPATH}' failed"
    fi
  else
    logWarning "File '${VOLTE_FILEPATH}' is empty"
  fi

  if [ -s ${VOWIFI_FILEPATH}]
  then
    mv ${VOWIFI_FILEPATH} ${OUTPUT_DIR}

    /opt/SIU_MANAGER/scripts/distribution/sh/distribute.sh VOWIFI ${OUTPUT_DIR}/$(basename ${VOWIFI_FILEPATH})
    if [ $? -ne 0 ]
    then
      logError "Distribution of file '$(basename ${VOWIFI_FILEPATH}' failed"
    fi
  else
    logWarning "File '${VOWIFI_FILEPATH}' is empty"
  fi
}


#
# Main
#

SCRIPT_BASEDIR=/opt/SIU_MANAGER/scripts/generateAutoprovCDRs
export SCRIPT_BASEDIR

. /opt/SIU_MANAGER/scripts/common/common.sh


process

endOfExecution
