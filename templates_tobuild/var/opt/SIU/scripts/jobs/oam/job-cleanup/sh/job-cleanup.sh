#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

#
# Functions
#

[#SECTION_BEGIN:MANAGER#]
function cleanupDatabaseTables
{
  logDebug "Executing function 'cleanupDatabaseTables'"

  if [ ! -d /var/opt/SIU_MANAGER ]
  then
    logInfo "Directory '/var/opt/SIU_MANAGER' is not accessible. Database tables backup does not apply"
    return 0
  fi

  getConfigSection DATABASE_TABLES > ${TMP_DIR}/database_tables
  if [ $? -lt 0 ]
  then
    logError "Unable to get section 'FILES'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/database_tables ]
  then
    logWarning "No database tables found to be cleaned"
    return 0
  fi

  while read LINE
  do
    DB_INSTANCE=$(echo ${LINE} | cut -d ";" -f 1)
    DB_DSN=$(echo ${LINE} | cut -d ";" -f 2)
    DB_TABLENAME=$(echo ${LINE} | cut -d ";" -f 3)
    TIMESTAMP_FIELD=$(echo ${LINE} | cut -d ";" -f 4)
    MAX_DAYS=$(echo ${LINE} | cut -d ";" -f 5)

    logDebug "Cleaning table '${DB_TABLENAME}'"

    logDebug "DB_INSTANCE = ${DB_INSTANCE}"
    logDebug "DB_DSN = ${DB_DSN}"
    logDebug "DB_TABLENAME = ${DB_TABLENAME}"
    logDebug "MAX_DAYS = ${MAX_DAYS}"

    CURRENT_TIMESTAMP=$(( $(date +%s) * 1000 ))
    MAX_MILISECONDS=$(( ${MAX_DAYS} * 24 * 60 * 60 * 1000 ))
    MIN_TIMESTAMP=$(( CURRENT_TIMESTAMP - MAX_MILISECONDS ))

    /usr/bin/mysql -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} << EOF
    DELETE FROM ${DB_DSN}.${DB_TABLENAME} WHERE ${TIMESTAMP_FIELD} < ${MIN_TIMESTAMP};
EOF
    if [ $? -ne 0 ]
    then
      logError "Command '/usr/bin/mysql -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} << EOF DELETE FROM ${DB_DSN}.${DB_TABLENAME} WHERE ${TIMESTAMP_FIELD} < ${MIN_TIMESTAMP}; EOF' failed"
      echo "${DB_TABLENAME}" >> ${TMP_DIR}/database_files.failed
    else
      logInfo "Table '${DB_TABLENAME}' cleaned up"
    fi
  done < ${TMP_DIR}/database_tables

  if [ -s ${TMP_DIR}/database_files.failed ]
  then
    return 1
  fi
}
[#SECTION_END#]

function cleanupFiles
{
  logDebug "Executing function 'cleanupFiles'"

  getConfigSection FILES > ${TMP_DIR}/files
  if [ $? -lt 0 ]
  then
    logError "Unable to get section 'FILES'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/files ]
  then
    logWarning "No files found to be cleaned"
    return 0
  fi

  while read FILE
  do
    logInfo "Cleaning up object '${FILE}'"

    DIRECTORY="$(getConfigParam ${FILE} DIRECTORY)"
    if [ $? -lt 0 ] || [ -z ${DIRECTORY} ]
    then
      logError "Unable to get mandatory parameter 'DIRECTORY' in section '${FILE}'"
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

    FILENAME_REGEX="$(getConfigParam ${FILE} FILENAME_REGEX)"
    if [ $? -lt 0 ] || [ -z ${FILENAME_REGEX} ]
    then
      logError "Unable to get mandatory parameter 'FILENAME_REGEX' in section '${FILE}'"
      return 1
    fi
    logDebug "FILENAME_REGEX = ${FILENAME_REGEX}"

    DAYS_BEFORE_DELETION="$(getConfigParam ${FILE} DAYS_BEFORE_DELETION)"
    if [ $? -lt 0 ]
    then
      logError "Unable to get parameter 'DAYS_BEFORE_DELETION' in section '${FILE}'"
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

    DAYS_BEFORE_COMPRESSION="$(getConfigParam ${FILE} DAYS_BEFORE_COMPRESSION)"
    if [ $? -lt 0 ]
    then
      logError "Unable to get parameter 'DAYS_BEFORE_COMPRESSION' in section '${FILE}'"
      return 1
    fi
    logDebug "DAYS_BEFORE_COMPRESSION = ${DAYS_BEFORE_COMPRESSION}"

    if [ ! -z ${DAYS_BEFORE_COMPRESSION} ]
    then
      find ${DIRECTORY} -type f -mtime +${DAYS_BEFORE_COMPRESSION} > ${TMP_DIR}/compression_files
      while read FILEPATH
      do
        FILENAME=$(basename ${FILEPATH})

        MATCH=$(echo ${FILENAME} | grep -P "${FILENAME_REGEX}" | grep -v ".gz$")
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
  done < ${TMP_DIR}/files
}


function process
{
  logDebug "Executing function 'process'"

  RETURN_CODE=0

  logInfo "Cleaning up Database Tables"
  cleanupDatabaseTables
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  logInfo "Cleaning up Files"
  cleanupFiles
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  return ${RETURN_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/oam/job-cleanup
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

