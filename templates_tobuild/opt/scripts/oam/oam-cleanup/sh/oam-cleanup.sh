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

  getConfigSection ELEMENTS > ${TMP_DIR}/elements
  if [ $? -lt 0 ]
  then
    logError "Unable to get section 'ELEMENTS'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/elements ]
  then
    logWarning "No elements found to be cleaned"
    return 0
  fi

  while read ELEMENT
  do
    logInfo "Processing element '${ELEMENT}'"

    DIRECTORY="$(getConfigParam ${ELEMENT} DIRECTORY)"
    if [ $? -lt 0 ] || [ -z ${DIRECTORY} ]
    then
      logError "Unable to get mandatory parameter 'DIRECTORY' in section '${ELEMENT}'"
      return 1
    fi
    logDebug "DIRECTORY = ${DIRECTORY}"

    >/dev/null 2>&1 cd ${DIRECTORY}
    if [ $? -ne 0 ]
    then
      logError "Unable to access to directory '${DIRECTORY}'"
      >/dev/null 2>&1 cd -
      return 1
    fi

    FILENAME_REGEX="$(getConfigParam ${ELEMENT} FILENAME_REGEX)"
    if [ $? -lt 0 ] || [ -z ${FILENAME_REGEX} ]
    then
      logError "Unable to get mandatory parameter 'FILENAME_REGEX' in section '${ELEMENT}'"
      return 1
    fi
    logDebug "FILENAME_REGEX = ${FILENAME_REGEX}"

    DAYS_BEFORE_DELETION="$(getConfigParam ${ELEMENT} DAYS_BEFORE_DELETION)"
    if [ $? -lt 0 ]
    then
      logError "Unable to get parameter 'DAYS_BEFORE_DELETION' in section '${ELEMENT}'"
      return 1
    fi
    logDebug "DAYS_BEFORE_DELETION = ${DAYS_BEFORE_DELETION}"

    if [ ! -z ${DAYS_BEFORE_DELETION} ]
    then
      find ${DIRECTORY} -type f -mtime +${DAYS_BEFORE_DELETION} > ${TMP_DIR}/deletion_files
      while read FILEPATH
      do
        FILENAME=$(basename ${FILEPATH})

        MATCH=$(echo ${FILENAME} | grep -P "${FILENAME_REGEX}")
        if [ -z ${MATCH} ]
        then
          logDebug "File '${FILENAME}' does not match patterns '${FILENAME_REGEX}'"
          continue
        fi

        rm -f ${FILEPATH}
        if [ $? -ne 0 ]
        then
          logError "Command 'rm -f ${FILEPATH}' failed"
          return 1
        fi

        logInfo "File '${FILEPATH}' deleted"
      done < ${TMP_DIR}/deletion_files
    fi

    DAYS_BEFORE_COMPRESSION="$(getConfigParam ${ELEMENT} DAYS_BEFORE_COMPRESSION)"
    if [ $? -lt 0 ]
    then
      logError "Unable to get parameter 'DAYS_BEFORE_COMPRESSION' in section '${ELEMENT}'"
      return 1
    fi
    logDebug "DAYS_BEFORE_COMPRESSION = ${DAYS_BEFORE_COMPRESSION}"

    if [ ! -z ${DAYS_BEFORE_COMPRESSION} ]
    then
      find ${DIRECTORY} -type f -mtime +${DAYS_BEFORE_COMPRESSION} > ${TMP_DIR}/compression_files
      while read FILEPATH
      do
        FILENAME=$(basename ${FILEPATH})

        MATCH=$(echo ${FILENAME} | grep -P "${FILENAME_REGEX}$")
        if [ -z ${MATCH} ]
        then
          logDebug "File '${FILENAME}' does not match patterns '${FILENAME_REGEX}'"
          continue
        fi

        gzip -f ${FILEPATH}
        if [ $? -ne 0 ]
        then
          logError "Command 'gzip -f ${FILEPATH}' failed"
          return 1
        fi

        logInfo "File '${FILEPATH}' compressed with GZIP"
      done < ${TMP_DIR}/compression_files
    fi
  done < ${TMP_DIR}/elements
}


#
# Main
#

SCRIPT_BASEDIR=/opt/scripts/oam/oam-cleaner
export SCRIPT_BASEDIR

. /opt/scripts/common/common.sh

EXIT_CODE=0
CURRENT_DATE=$(date +%Y%m%d)

process
if [ $? -ne 0 ]
then
  EXIT_CODE=$?
  logWarning "Function 'process' executed with errors"
fi

endOfExecution ${EXIT_CODE}

