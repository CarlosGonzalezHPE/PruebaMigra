#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

#
# Functions
#


function lockUnlockUserAccounts
{
  logDebug "Executing function 'cleanupDatabaseTables'"

  /usr/bin/mysql -S /var/Mariadb/DEG_MGR_MD/mysql.sock -u root -D NRB_DSN_MD << EOF
  UPDATE NRB_USERS SET LOCKED = 'No';
EOF
  if [ $? -ne 0 ]
  then
    logError "Command '/usr/bin/mysql -S /var/Mariadb/DEG_MGR_MD/mysql.sock -u root -D DSN_NRB_MD << EOF; UPDATE NRB_USERS SET LOCKED = 'No'; EOF' failed"
    return 1
  fi

  logInfo "All users account have been unlocked"

  getConfigSection LOCKED_USERS > ${TMP_DIR}/locked_users
  if [ $? -lt 0 ]
  then
    logWarning "Unable to get section 'LOCKED_USERS'"
  fi

  while read LOCKED_USER
  do
    logDebug "Lockong user '${LOCKED_USER}'"
    /usr/bin/mysql -S /var/Mariadb/DEG_MGR_MD/mysql.sock -u root -D NRB_DSN_MD << EOF
    UPDATE NRB_USERS SET LOCKED = 'Yes' WHERE LOGIN = '${LOCKED_USER}';
EOF
    if [ $? -ne 0 ]
    then
      logError "Command '/usr/bin/mysql -S /var/Mariadb/DEG_MGR_MD/mysql.sock -u root -D DSN_NRB_MD << EOF; UPDATE NRB_USERS SET LOCKED = 'Yes' WHERE LOGIN = '${LOCKED_USER}'; EOF' failed"
      continue
    fi

    logInfo "User account with login '${LOCKED_USER}' has been locked"
  done < ${TMP_DIR}/locked_users
}


function process
{
  logDebug "Executing function 'process'"

  OUTPUT_DIR=${WORK_DIR}/$(date +"%Y%m%d%H%M")
  mkdir -p ${OUTPUT_DIR}

  >/dev/null 2>&1 cd ${OUTPUT_DIR}
  if [ $? -ne 0 ]
  then
    logError "Unable to access to directory '${OUTPUT_DIR}'"
    >/dev/null 2>&1 cd -
    return 1
  fi
  logDebug "OUTPUT_DIR = ${OUTPUT_DIR}"

  DEFAULT_INTERVAL_MINUTES="$(getConfigParam GENERAL DEFAULT_INTERVAL_MINUTES)"
  if [ $? -lt 0 ] || [ -z ${DEFAULT_INTERVAL_MINUTES} ]
  then
    logError "Unable to get mandatory parameter 'DEFAULT_INTERVAL_MINUTES' in section 'GENERAL'"
    return 1
  fi
  logDebug "DEFAULT_INTERVAL_MINUTES = ${DEFAULT_INTERVAL_MINUTES}"

  MAX_INTERVAL_MINUTES="$(getConfigParam GENERAL MAX_INTERVAL_MINUTES)"
  if [ $? -lt 0 ] || [ -z ${MAX_INTERVAL_MINUTES} ]
  then
    logError "Unable to get mandatory parameter 'MAX_INTERVAL_MINUTES' in section 'GENERAL'"
    return 1
  fi
  logDebug "MAX_INTERVAL_MINUTES = ${MAX_INTERVAL_MINUTES}"

  IGNORED_LAST_MINUTES="$(getConfigParam GENERAL IGNORED_LAST_MINUTES)"
  if [ $? -lt 0 ] || [ -z ${IGNORED_LAST_MINUTES} ]
  then
    logError "Unable to get mandatory parameter 'IGNORED_LAST_MINUTES' in section 'GENERAL'"
    return 1
  fi
  logDebug "IGNORED_LAST_MINUTES = ${IGNORED_LAST_MINUTES}"

  REMOTE_PEER_IPADDRESS="$(getConfigParam GENERAL REMOTE_PEER_IPADDRESS)"
  if [ $? -lt 0 ] || [ -z ${REMOTE_PEER_IPADDRESS} ]
  then
    logError "Unable to get mandatory parameter 'REMOTE_PEER_IPADDRESS' in section 'GENERAL'"
    return 1
  fi
  logDebug "REMOTE_PEER_IPADDRESS = ${REMOTE_PEER_IPADDRESS}"

  TIMESTAMP_NOW=$(date +"%s")
  TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES=$(date +"%s" -d "${IGNORED_LAST_MINUTES} minutes ago")
  logDebug "TIMESTAMP_NOW = ${TIMESTAMP_NOW}"
  logDebug "TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES = ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES}"

  getConfigSection TABLES > ${TMP_DIR}/tables
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'TABLES'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/tables ]
  then
    return 0
  fi

  RETURN_CODE=0

  while read TABLE
  do
    logDebug "Processing table '${TABLE}'"

    DB_INSTANCE="$(getConfigParam ${TABLE} DB_INSTANCE)"
    if [ $? -lt 0 ] || [ -z ${DB_INSTANCE} ]
    then
      logError "Unable to get mandatory parameter 'DB_INSTANCE' in section '${TABLE}'"
      RETURN_CODE=1
      continue
    fi
    logDebug "DB_INSTANCE = ${DB_INSTANCE}"

    DB_DSN="$(getConfigParam ${TABLE} DB_DSN)"
    if [ $? -lt 0 ] || [ -z ${DB_INSTANCE} ]
    then
      logError "Unable to get mandatory parameter 'DB_DSN' in section '${TABLE}'"
      RETURN_CODE=1
      continue
    fi
    logDebug "DB_DSN = ${DB_DSN}"

    DATETIME_FIELD="$(getConfigParam ${TABLE} DATETIME_FIELD)"
    if [ $? -lt 0 ] || [ -z "${DATETIME_FIELD}" ]
    then
      logError "Unable to get mandatory parameter 'DATETIME_FIELD' in section '${TABLE}'"
      RETURN_CODE=1
      continue
    fi
    logDebug "DATETIME_FIELD = ${DATETIME_FIELD}"

    DATETIME_FORMAT="$(getConfigParam ${TABLE} DATETIME_FORMAT)"
    if [ $? -lt 0 ] || [ -z "${DATETIME_FORMAT}" ]
    then
      logError "Unable to get mandatory parameter 'DATETIME_FORMAT' in section '${TABLE}'"
      RETURN_CODE=1
      continue
    fi
    logDebug "DATETIME_FORMAT = ${DATETIME_FORMAT}"

    getConfigSection ${TABLE}.FIELDS > ${TMP_DIR}/${TABLE}.fields
    if [ $? -lt 0 ]
    then
      logError "Unable to get mandatory section '${TABLE}.FIELDS'"
      RETURN_CODE=1
      continue
    fi

    if [ ! -s ${TMP_DIR}/${TABLE}.fields ]
    then
      logError "No fields defined for table '${TABLE}'"
      RETURN_CODE=1
      continue
    fi

    if [ ! -s ${CTRL_DIR}/${TABLE}.timestamp_last_execution ]
    then
      TIMESTAMP_LAST_EXECUTION=$(date +"%s" -d "${DEFAULT_INTERVAL_MINUTES} minutes ago")
    else
      TIMESTAMP_LAST_EXECUTION=$(cat ${CTRL_DIR}/${TABLE}.timestamp_last_execution | head -n 1 | grep -P "^\d{10}$")

      if [ -z ${TIMESTAMP_LAST_EXECUTION} ] || [ ${TIMESTAMP_LAST_EXECUTION} -lt $(date +"%s" -d "${MAX_INTERVAL_MINUTES} minutes ago") ] || [ ${TIMESTAMP_LAST_EXECUTION} -ge $(date +"%s") ]
      then
        logWarning "Invalid value '${TIMESTAMP_LAST_EXECUTION}' for parameter 'TIMESTAMP_LAST_EXECUTION'. Set to default"
        TIMESTAMP_LAST_EXECUTION=$(date +"%s" -d '${DEFAULT_INTERVAL_MINUTES} minutes ago')
      fi
    fi
    logDebug "TIMESTAMP_LAST_EXECUTION = ${TIMESTAMP_LAST_EXECUTION}"

    if [ ${TIMESTAMP_LAST_EXECUTION} -ge ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES} ]
    then
      logWarning "Ignored last minutes '${IGNORED_LAST_MINUTES}' have not been reached yet. Table is skipped"
      continue
    fi

    case "${DATETIME_FORMAT}" in
      "DATETIME")
        DATETIME_CONDITION="UNIX_TIMESTAMP(${DATETIME_FIELD}) >= ${TIMESTAMP_LAST_EXECUTION} AND UNIX_TIMESTAMP(${DATETIME_FIELD}) < ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES}"
        ;;
      "TIMESTAMP")
        DATETIME_CONDITION="${DATETIME_FIELD} >= ${TIMESTAMP_LAST_EXECUTION}000 AND ${DATETIME_FIELD} < ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES}000"
        ;;
      *)
        logError "Unsupported datetime format '${DATETIME_FORMAT}'"
        RETURN_CODE=1
        continue
        ;;
    esac

    AUX_SQL_QUERY="SELECT "
    while read FIELD
    do
      AUX_SQL_QUERY=${AUX_SQL_QUERY}${FIELD}","
    done < ${TMP_DIR}/${TABLE}.fields

    SQL_QUERY=$(echo ${AUX_SQL_QUERY} | sed 's/.$//')" FROM ${TABLE} WHERE ${DATETIME_CONDITION} ORDER BY ${DATETIME_FIELD}"
    logDebug "SQL_QUERY = ${SQL_QUERY}"

    echo ${SQL_QUERY} > ${TMP_DIR}/query-${TABLE}.sql
    echo "INTO OUTFILE '"${OUTPUT_DIR}/query-${TABLE}.csv"'" >> ${TMP_DIR}/query-${TABLE}.sql
    echo "FIELDS TERMINATED BY ','" >> ${TMP_DIR}/query-${TABLE}.sql
    echo "LINES TERMINATED BY '\n';" >> ${TMP_DIR}/query-${TABLE}.sql

    > ${TMP_DIR}/query-${TABLE}.out 2> ${TMP_DIR}/query-${TABLE}.err /usr/bin/mysql -sN -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} -e "source ${TMP_DIR}/query-${TABLE}.sql"

    if [ $(grep -i error ${TMP_DIR}/query-${TABLE}.out | wc -l) -gt 0 ] || [ -s ${TMP_DIR}/query-${TABLE}.err ]
    then
      logError "Command '> ${TMP_DIR}/query-${TABLE}.out 2> ${TMP_DIR}/query-${TABLE}.err /usr/bin/mysql -sN -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} -e "source ${TMP_DIR}/query-${TABLE}.sql"' failed"
      RETURN_CODE=1
      continue
    fi

    echo ${TIMESTAMP_NOW} > ${CTRL_DIR}/${TABLE}.timestamp_last_execution
    if [ $? -ne 0 ]
    then
      logError "Command 'echo ${TIMESTAMP_NOW} > ${CTRL_DIR}/${TABLE}.timestamp_last_execution' failed"
      RETURN_CODE=1
    fi
  done < ${TMP_DIR}/tables

  return ${RETURN_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/oam/job-dbrep
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
fi

endOfExecution ${EXIT_CODE}
