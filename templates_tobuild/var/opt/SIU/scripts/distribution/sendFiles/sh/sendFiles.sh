#!/bin/bash
#-------------------------------------------------------------------------------
# Orange Mediacion eIUM
#
# HPE CMS Iberia, 2017
#-------------------------------------------------------------------------------

#
# Functions
#

function process
{
  logDebug "Executing function 'process'"

  PROTOCOL="$(getConfigParam ${RUN_LABEL} PROTOCOL)"
  if [ $? -lt 0 ] || [ "${PROTOCOL}" == "" ]
  then
    logError "Unable to get mandatory parameter 'PROTOCOL' in section '${RUN_LABEL}'"
    return 1
  fi
  logDebug "PROTOCOL = ${PROTOCOL}"

  case "${PROTOCOL}" in
    "SFTP_PASSWORD")
      DESTINATION_PASSWORD="$(getConfigParam ${RUN_LABEL} DESTINATION_PASSWORD)"
      if [ $? -lt 0 ] || [ -z ${DESTINATION_PASSWORD} ]
      then
        logError "Unable to get mandatory parameter 'DESTINATION_PASSWORD' in section '${RUN_LABEL}'"
        return 1
      fi
      logDebug "DESTINATION_PASSWORD = ${DESTINATION_PASSWORD}"
      ;;
    "SFTP_KEY")
      ;;
    *)
      logError "Unsupported pvalue '${PROTOCOL}' for parameter 'PROTOCOL'"
      return 1
      ;;
  esac

  DESTINATION_HOST="$(getConfigParam ${RUN_LABEL} DESTINATION_HOST)"
  if [ $? -lt 0 ] || [ -z ${DESTINATION_HOST} ]
  then
    logError "Unable to get mandatory parameter 'DESTINATION_HOST' in section '${RUN_LABEL}'"
    return 1
  fi
  logDebug "DESTINATION_HOST = ${DESTINATION_HOST}"

  DESTINATION_USER="$(getConfigParam ${RUN_LABEL} DESTINATION_USER)"
  if [ $? -lt 0 ] || [ -z ${DESTINATION_USER} ]
  then
    logError "Unable to get mandatory parameter 'DESTINATION_USER' in section '${RUN_LABEL}'"
    return 1
  fi
  logDebug "DESTINATION_USER = ${DESTINATION_USER}"

  CHMOD_DIRECTORIES="$(getConfigParam ${RUN_LABEL} CHMOD_DIRECTORIES)"
  if [ $? -lt 0 ]
  then
    logError "Unable to get parameter 'CHMOD_DIRECTORIES' in section '${RUN_LABEL}'"
    return 1
  fi
  logDebug "CHMOD_DIRECTORIES = ${CHMOD_DIRECTORIES}"

  CHMOD_FILES="$(getConfigParam ${RUN_LABEL} CHMOD_FILES)"
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory 'CHMOD_FILES' in section '${RUN_LABEL}'"
    return 1
  fi
  logDebug "CHMOD_FILES = ${CHMOD_FILES}"

  OUTPUT_DIR="$(getConfigParam ${RUN_LABEL} OUTPUT_DIR)"
  if [ $? -lt 0 ] || [ -z ${OUTPUT_DIR} ]
  then
    logError "Unable to get mandatory parameter 'OUTPUT_DIR' in section '${RUN_LABEL}'"
    return 1
  fi
  logDebug "OUTPUT_DIR = ${OUTPUT_DIR}"

  >/dev/null 2>&1 cd ${OUTPUT_DIR}
  if [ $? -ne 0 ]
  then
    logError "Unable to access to directory '${OUTPUT_DIR}'"
    >/dev/null 2>&1 cd -
    return 1
  fi

  ARCHIVE_DIR="$(getConfigParam ${RUN_LABEL} ARCHIVE_DIR)"
  if [ $? -lt 0 ] || [ -z ${DESTINATION_DIR} ]
  then
    logDebug "Parameter 'DESTINATION_DIR' not defined in section '${RUN_LABEL}.${OUTPUT_TYPE}'"
  else
    logDebug "ARCHIVE_DIR = ${ARCHIVE_DIR}"

    >/dev/null 2>&1 cd ${ARCHIVE_DIR}
    if [ $? -ne 0 ]
    then
      logError "Unable to access to directory '${ARCHIVE_DIR}'"
      >/dev/null 2>&1 cd -
      return 1
    fi
  fi

  getConfigSection ${RUN_LABEL}.OUTPUT_TYPES > ${TMP_DIR}/output_types
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section '${RUN_LABEL}.OUTPUT_TYPES'"
    return 1
  fi

  while read OUTPUT_TYPE
  do
    DESTINATION_DIR="$(getConfigParam ${RUN_LABEL}.${OUTPUT_TYPE} DESTINATION_DIR)"
    if [ $? -lt 0 ] || [ -z ${DESTINATION_DIR} ]
    then
      logError "Unable to get mandatory parameter 'DESTINATION_DIR' in section '${RUN_LABEL}.${OUTPUT_TYPE}'"
      return 1
    fi
    logDebug "DESTINATION_DIR = ${DESTINATION_DIR}"

    FILENAME_PERLREGEX="$(getConfigParam ${RUN_LABEL}.${OUTPUT_TYPE} FILENAME_PERLREGEX)"
    if [ $? -lt 0 ] || [ -z ${FILENAME_PERLREGEX} ]
    then
      logError "Unable to get mandatory parameter 'FILENAME_PERLREGEX' in section '${RUN_LABEL}.${OUTPUT_TYPE}'"
      return 1
    fi
    logDebug "FILENAME_PERLREGEX = ${FILENAME_PERLREGEX}"

    2>> ${LOG_FILEPATH} ls ${OUTPUT_DIR}/${OUTPUT_TYPE} | while read FILENAME
    do
      FILEPATH=${OUTPUT_DIR}/${OUTPUT_TYPE}/${FILENAME}

      MATCH=$(echo ${FILENAME} | grep -P "${FILENAME_PERLREGEX}")
      if [ -z ${MATCH} ]
      then
        continue
      fi

      logInfo "Procesing file '${FILEPATH}'"

      TMP_PREFIX=.tmp_HPEDEG_$(date +"%Y%m%d%H%M%S")
      logDebug "TMP_PREFIX = ${TMP_PREFIX}"

      case "${PROTOCOL}" in
        "SFTP_KEY")
           > ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "#!/bin/bash"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "/usr/bin/sftp ${DESTINATION_USER}@${DESTINATION_HOST} << EOD"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "cd ${DESTINATION_DIR}"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "pwd"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "lcd ${OUTPUT_DIR}/${OUTPUT_TYPE}"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "put ${FILENAME} ${TMP_PREFIX}.${FILENAME}"
          if [ ! -z ${CHMOD_FILES} ]
          then
            >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "chmod ${CHMOD_FILES} ${TMP_PREFIX}.${FILENAME}"
          fi
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "rename ${TMP_PREFIX}.${FILENAME} ${FILENAME}"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "ls ${FILENAME}"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "bye"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "EOD"
          ;;
        "SFTP_PASSWORD")
           > ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "#!/bin/bash"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "/usr/bin/expect << EOD"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "spawn /usr/bin/sftp ${DESTINATION_USER}@${DESTINATION_HOST}"
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"password:\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"${DESTINATION_PASSWORD}\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"cd ${DESTINATION_DIR}\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"pwd\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"lcd ${OUTPUT_DIR}/${OUTPUT_TYPE}\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"put ${FILENAME} ${TMP_PREFIX}.${FILENAME}\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          if [ ! -z ${CHMOD_FILES} ]
          then
            >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"chmod ${CHMOD_FILES} ${TMP_PREFIX}.${FILENAME}\r\""
            >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          fi
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"rename ${TMP_PREFIX}.${FILENAME} ${FILENAME}\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"ls ${FILENAME}\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "expect \"sftp>\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "send \"bye\r\""
          >> ${TMP_DIR}/sftp.send_file.${FILENAME}.sh echo "EOD"
          ;;
      esac

      case "${PROTOCOL}" in
        "SFTP_KEY" | "SFTP_PASSWORD")
          chmod 744 ${TMP_DIR}/sftp.send_file.${FILENAME}.sh
          ${TMP_DIR}/sftp.send_file.${FILENAME}.sh > ${TMP_DIR}/sftp.send_file.${FILENAME}.out 2>&1

          if [ $(grep "Remote working directory: ${DESTINATION_DIR}" ${TMP_DIR}/sftp.send_file.${FILENAME}.out | wc -l) -gt 0 ]
          then
            if [ $(tail -n 2 ${TMP_DIR}/sftp.send_file.${FILENAME}.out | head -n 1 | grep "^${FILENAME}" | wc -l) -gt 0 ]
            then
              logInfo "File '${FILENAME}' successfully sent"
              echo "${FILENAME}" >> ${TMP_DIR}/sent_files
            else
              logError "Unable to send file '${FILENAME}'"
              echo "--------" >> ${LOG_FILEPATH}
              cat ${TMP_DIR}/sftp.send_file.${FILENAME}.out >> ${LOG_FILEPATH}
              echo "--------" >> ${LOG_FILEPATH}
              return 1
            fi
          else
            logError "Unable to move to destination directory '${DESTINATION_DIR}'"
            echo "--------" >> ${LOG_FILEPATH}
            cat ${TMP_DIR}/sftp.send_file.${FILENAME}.out >> ${LOG_FILEPATH}
            echo "--------" >> ${LOG_FILEPATH}
            return 1
          fi
          ;;
      esac

      if [ ! -z ${ARCHIVE_DIR} ]
      then
        mv ${FILEPATH} ${ARCHIVE_DIR}
        if [ $? -ne 0 ]
        then
          logError "Command 'mv ${FILEPATH} ${ARCHIVE_DIR}' failed"
        fi
      else
        logWarning "File '${FILEPATH}' deleted"
        rm -f ${FILEPATH}
        if [ $? -ne 0 ]
        then
          logError "Command 'rm -f ${FILEPATH}' failed"
        fi
      fi
    done
  done < ${TMP_DIR}/output_types
}


#
# Main
#

while getopts "o:" OPT
do
  case ${OPT} in
    o)
      RUN_LABEL=${OPTARG}
      export RUN_LABEL
      ;;
    *)
      echo "Error: Bad option '${OPT}'"
      exit 1
      ;;
  esac
done

if [ -z ${RUN_LABEL} ]
then
  echo "Usage: sendFiles.sh -o <RUN_LABEL>"
  exit 1
fi

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/distribution/sendFiles
export SCRIPT_BASEDIR

. /var/opt/<%SIU_INSTANCE%>/scripts/common/common.sh

logDebug "RUN_LABEL = ${RUN_LABEL}"

EXIT_CODE=0
CURRENT_DATE=$(date +"%Y%m%d")

process
if [ $? -ne 0 ]
then
  EXIT_CODE=$?
  logWarning "Function 'process' executed with errors"
fi

endOfExecution ${EXIT_CODE}
