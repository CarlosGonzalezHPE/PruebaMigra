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
  mkdir -p ${OUTPUT_DIR}/remote

  >/dev/null 2>&1 cd ${OUTPUT_DIR}/remote
  if [ $? -ne 0 ]
  then
    logError "Unable to access to directory '${OUTPUT_DIR}/remote'"
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

  SLEEP_MINUTES_BEFORE_FECTH="$(getConfigParam GENERAL SLEEP_MINUTES_BEFORE_FECTH)"
  if [ $? -lt 0 ] || [ -z ${SLEEP_MINUTES_BEFORE_FECTH} ]
  then
    logError "Unable to get mandatory parameter 'SLEEP_MINUTES_BEFORE_FECTH' in section 'GENERAL'"
    return 1
  fi
  logDebug "SLEEP_MINUTES_BEFORE_FECTH = ${SLEEP_MINUTES_BEFORE_FECTH}"

  REMOTE_PEER_IPADDRESS="$(getConfigParam GENERAL REMOTE_PEER_IPADDRESS)"
  if [ $? -lt 0 ] || [ -z ${REMOTE_PEER_IPADDRESS} ]
  then
    logError "Unable to get mandatory parameter 'REMOTE_PEER_IPADDRESS' in section 'GENERAL'"
    return 1
  fi
  logDebug "REMOTE_PEER_IPADDRESS = ${REMOTE_PEER_IPADDRESS}"

  TIMESTAMP_NOW=$(date +"%s")
  TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES=$(date +"%s" -d "-${IGNORED_LAST_MINUTES} minutes")
  TIMESTAMP_START_FETCHING_REMOTE_FILES=$(date +"%s" -d "+${SLEEP_MINUTES_BEFORE_FECTH} minutes")
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

  logDebug "Dumping local tables"

  while read TABLE
  do
    logInfo "Dumping table '${TABLE}'"

    DB_INSTANCE="$(getConfigParam ${TABLE} DB_INSTANCE)"
    if [ $? -lt 0 ] || [ -z ${DB_INSTANCE} ]
    then
      logError "Unable to get mandatory parameter 'DB_INSTANCE' in section '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "DB_INSTANCE = ${DB_INSTANCE}"

    DB_DSN="$(getConfigParam ${TABLE} DB_DSN)"
    if [ $? -lt 0 ] || [ -z ${DB_INSTANCE} ]
    then
      logError "Unable to get mandatory parameter 'DB_DSN' in section '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "DB_DSN = ${DB_DSN}"

    DATETIME_FIELD="$(getConfigParam ${TABLE} DATETIME_FIELD)"
    if [ $? -lt 0 ] || [ -z "${DATETIME_FIELD}" ]
    then
      logError "Unable to get mandatory parameter 'DATETIME_FIELD' in section '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "DATETIME_FIELD = ${DATETIME_FIELD}"

    DATETIME_FORMAT="$(getConfigParam ${TABLE} DATETIME_FORMAT)"
    if [ $? -lt 0 ] || [ -z "${DATETIME_FORMAT}" ]
    then
      logError "Unable to get mandatory parameter 'DATETIME_FORMAT' in section '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      > ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "DATETIME_FORMAT = ${DATETIME_FORMAT}"

    getConfigSection ${TABLE}.FIELDS > ${TMP_DIR}/${TABLE}.fields
    if [ $? -lt 0 ]
    then
      logError "Unable to get mandatory section '${TABLE}.FIELDS'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi

    if [ ! -s ${TMP_DIR}/${TABLE}.fields ]
    then
      logError "No fields defined for table '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi

    if [ ! -s ${CTRL_DIR}/${TABLE}.timestamp_last_execution ]
    then
      TIMESTAMP_LAST_EXECUTION=$(date +"%s" -d "-${DEFAULT_INTERVAL_MINUTES} minutes")
    else
      TIMESTAMP_LAST_EXECUTION=$(cat ${CTRL_DIR}/${TABLE}.timestamp_last_execution | head -n 1 | grep -P "^\d{10}$")

      if [ -z ${TIMESTAMP_LAST_EXECUTION} ] || [ ${TIMESTAMP_LAST_EXECUTION} -lt $(date +"%s" -d "-${MAX_INTERVAL_MINUTES} minutes") ] || [ ${TIMESTAMP_LAST_EXECUTION} -ge $(date +"%s") ]
      then
        logWarning "Invalid value '${TIMESTAMP_LAST_EXECUTION}' for parameter 'TIMESTAMP_LAST_EXECUTION'. Set to default"
        TIMESTAMP_LAST_EXECUTION=$(date +"%s" -d '-${DEFAULT_INTERVAL_MINUTES} minutes')
      fi
    fi
    logDebug "TIMESTAMP_LAST_EXECUTION = ${TIMESTAMP_LAST_EXECUTION}"

    if [ ${TIMESTAMP_LAST_EXECUTION} -ge ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES} ]
    then
      logWarning "Ignored last minutes '${IGNORED_LAST_MINUTES}' have not been reached yet. Table is skipped"
      touch ${TMP_DIR}/${TABLE}.skipped
      continue
    fi

    case "${DATETIME_FORMAT}" in
      "DATETIME")
        SELECT_DATETIME="SELECT UNIX_TIMESTAMP(${DATETIME_FIELD})"
        DATETIME_CONDITION="UNIX_TIMESTAMP(${DATETIME_FIELD}) >= ${TIMESTAMP_LAST_EXECUTION} AND UNIX_TIMESTAMP(${DATETIME_FIELD}) < ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES}"
        ;;
      "TIMESTAMP")
        SELECT_DATETIME="SELECT ${DATETIME_FIELD} DIV 1000"
        DATETIME_CONDITION="${DATETIME_FIELD} >= ${TIMESTAMP_LAST_EXECUTION}000 AND ${DATETIME_FIELD} < ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES}000"
        ;;
      *)
        logError "Unsupported datetime format '${DATETIME_FORMAT}'"
        touch ${TMP_DIR}/${TABLE}.failed
        continue
        ;;
    esac

    AUX_SELECT_KEY=
    AUX_SELECT_FIELDS=
    while read FIELD_LINE
    do
      FIELD_NAME=$(echo ${FIELD_LINE} | cut -d ";" -f 1)
      FIELD_TYPE=$(echo ${FIELD_LINE} | cut -d ";" -f 2)
      FIELD_ATTRIBUTE=$(echo ${FIELD_LINE} | cut -d ";" -f 3)

      if [ "${FIELD_ATTRIBUTE}" = "key" ]
      then
        AUX_SELECT_KEY=${AUX_SELECT_KEY}"'"${FIELD_NAME}"=',"${FIELD_NAME}",';',"
      else
        AUX_SELECT_FIELDS=${AUX_SELECT_FIELDS}${FIELD_NAME}","
      fi
    done < ${TMP_DIR}/${TABLE}.fields

    logDebug "AUX_SELECT_KEY = ${AUX_SELECT_KEY}"
    logDebug "AUX_SELECT_FIELDS = ${AUX_SELECT_FIELDS}"

    SELECT_KEY=${AUX_SELECT_KEY/%?????/}
    if [ -z ${SELECT_KEY} ]
    then
      logError "No key defined to select data from table '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "SELECT_KEY = ${SELECT_KEY}"

    SELECT_FIELDS=${AUX_SELECT_FIELDS/%?/}
    if [ -z ${SELECT_FIELDS} ]
    then
      logError "No fields defined to select data from table '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "SELECT_FIELDS = ${SELECT_FIELDS}"

    SQL_QUERY="CONCAT_WS('', ${SELECT_KEY}), ${SELECT_DATETIME}, ${SELECT_FIELDS} FROM ${TABLE} WHERE ${DATETIME_CONDITION} ORDER BY ${DATETIME_FIELD}"
    logDebug "SQL_QUERY = ${SQL_QUERY}"

    echo ${SQL_QUERY} > ${TMP_DIR}/query-${TABLE}.sql
    echo "INTO OUTFILE '"${OUTPUT_DIR}/dump-${TABLE}.csv"'" >> ${TMP_DIR}/query-${TABLE}.sql
    echo "FIELDS TERMINATED BY ','" >> ${TMP_DIR}/query-${TABLE}.sql
    echo "LINES TERMINATED BY '\n';" >> ${TMP_DIR}/query-${TABLE}.sql

    > ${TMP_DIR}/query-${TABLE}.out 2> ${TMP_DIR}/query-${TABLE}.err /usr/bin/mysql -sN -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} -e "source ${TMP_DIR}/query-${TABLE}.sql"

    if [ $(grep -i error ${TMP_DIR}/query-${TABLE}.out | wc -l) -gt 0 ] || [ -s ${TMP_DIR}/query-${TABLE}.err ]
    then
      logError "Command '> ${TMP_DIR}/query-${TABLE}.out 2> ${TMP_DIR}/query-${TABLE}.err /usr/bin/mysql -sN -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} -e \"source ${TMP_DIR}/query-${TABLE}.sql\"' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi

    if [ ! -s ${OUTPUT_DIR}/dump-${TABLE}.csv ]
    then
      touch ${TMP_DIR}/${TABLE}.skipped
      continue
    fi
  done < ${TMP_DIR}/tables

  let SLEEP_SECONDS=${TIMESTAMP_START_FETCHING_REMOTE_FILES}-$(date +"%s")

  if [ ${SLEEP_SECONDS} -gt 0 ]
  then
    logInfo "Sleeping for ${SLEEP_SECONDS} seconds"
    sleep ${SLEEP_SECONDS}
  fi

  logInfo "Fetching dump of remote tables"

  while read TABLE
  do
    logInfo "Fetching dump of remote table '${TABLE}'"

    > ${TMP_DIR}/scp-${TABLE}.out 2> ${TMP_DIR}/scp-${TABLE}.err scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ium@${REMOTE_PEER_IPADDRESS}:${OUTPUT_DIR}/dump-${TABLE}.csv ${OUTPUT_DIR}/remote
    if [ $? -ne 0 ]
    then
      logError "Command '> ${TMP_DIR}/scp-${TABLE}.out 2> ${TMP_DIR}/scp-${TABLE}.err scp ium@${REMOTE_PEER_IPADDRESS}:${OUTPUT_DIR}/dump-${TABLE}.csv ${OUTPUT_DIR}/remote' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
  done < ${TMP_DIR}/tables

  logInfo "Resolving conflicts"

  while read TABLE
  do
    CONFLICT_RESOLUTION_ENABLED="$(getConfigParam ${TABLE} CONFLICT_RESOLUTION_ENABLED)"
    if [ $? -lt 0 ] || [ -z "${CONFLICT_RESOLUTION_ENABLED}" ]
    then
      logWarning "Parameter 'CONFLICT_RESOLUTION_ENABLED' not defined in section '${TABLE}'. Set to default value 'TRUE"
      CONFLICT_RESOLUTION_ENABLED=TRUE
    else
      case "${CONFLICT_RESOLUTION_ENABLED}" in
        "TRUE" | "FALSE")
          ;;
        *)
          CONFLICT_RESOLUTION_ENABLED=TRUE
          logWarning "Invalid value '${CONFLICT_RESOLUTION_ENABLED}' for parameter  'CONFLICT_RESOLUTION_ENABLED' in section '${TABLE}'. Set to default value 'TRUE"
          ;;
      esac
    fi
    logDebug "CONFLICT_RESOLUTION_ENABLED = ${CONFLICT_RESOLUTION_ENABLED}"

    if [ "${CONFLICT_RESOLUTION_ENABLED}" = "FALSE" ]
    then
      logWarning "Conflict resolution is not enabled for table '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.conflict_resolution_disabled
      continue
    fi

    logInfo "Computing differences for table '${TABLE}'"

    logDebug "Sorting files"

    cat ${OUTPUT_DIR}/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted
    if [ $? -ne 0 ]
    then
      logError "Command 'cat ${OUTPUT_DIR}/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi

    cat ${OUTPUT_DIR}/remote/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted
    if [ $? -ne 0 ]
    then
      logError "Command 'cat ${OUTPUT_DIR}/remote/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi

    diff -W 23 -y ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted > ${TMP_DIR}/dump-${TABLE}.diffs
    if [ $? -ne 0 ]
    then
      logError "Command 'diff -W 23 -y ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted > ${TMP_DIR}/dump-${TABLE}.diffs' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi

    logDebug "Processing diff file"

    awk -F \% -v OUT=${TMP_DIR}/lines.${TABLE}.out -v ERR=${TMP_DIR}/lines.${TABLE}.err '
    function ltrim(s) {
      sub(/^[ \t\r\n]+/, "", s);
      return s;
    }
    function rtrim(s) {
      sub(/[ \t\r\n]+\$/, \"\", s);
      return s;
    }
    function trim(s) {
      return rtrim(ltrim(s));
    }
    BEGIN { line = 0; num_conflicts = 0 } {
      if ($0  ~ " | ") {
        split($0, v, "|");
        local_timestamp = 0 + trim(v[1]);
        remote_timestamp = 0 + trim(v[2]);

        if (length(local_timestamp) != 10) {
          print line":"$0 >> ERR;
          line++;
          next;
        }

        if (! match(local_timestamp, /^[0-9]+$/)) {
          print line":"$0 >> ERR;
          line++;
          next;
        }

        if (length(remote_timestamp) != 10) {
          print line":"$0 >> ERR;
          line++;
          next;
        }

        if (! match(remote_timestamp, /^[0-9]+$/)) {
          print line":"$0 >> ERR;
          line++;
          next;
        }

        if (local_timestamp >= remote_timestamp) {
          num_conflicts++;
          print line",UPDATE" >> OUT;
          line++;
          next;
        }
      } else if ($0  ~ " < ") {
        num_conflicts++;
        print line",INSERT" >> OUT;
      } else if ($0  ~ " > ") {
        num_conflicts++;
      }

      line++;
    }
    END { print num_conflicts } ' ${TMP_DIR}/dump-${TABLE}.diffs > ${TMP_DIR}/conflicts.${TABLE}

    if [ -s ${TMP_DIR}/lines.${TABLE}.err ]
    then
      logWarning "Some conflicts won't be resolved"
      touch ${TMP_DIR}/${TABLE}.warning
    fi

    let NUM_CONFLICTS=$(cat ${TMP_DIR}/conflicts.${TABLE} | head -n 1)
    logDebug "NUM_CONFLICTS = NUM_CONFLICTS"

    if [ ${NUM_CONFLICTS} -gt 0 ]
    then
      logWarning "Conflicts have been detected in table ${TABLE}"
    fi

    awk -F \, '
    BEGIN { index_file = 0; }
    {
      if (FNR == 1) {
        index_file++;
        line = 0;
      }

      if (index_file == 1) {
        lines[$1];
        operation[$1] = $2;
        next;
      }

      if (index_file == 2) {
        if (line in lines) {
          print operation[line]";"$0;
        }
        line++;
      }
    }' ${TMP_DIR}/lines.${TABLE}.out ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted > ${TMP_DIR}/changes.${TABLE}.out

    if [ ! -s ${TMP_DIR}/changes.${TABLE}.out ]
    then
      logInfo "No local operations needed"
      touch ${TMP_DIR}/${TABLE}.skipped
      continue
    fi

    awk -F \; -v datetime_field=${DATETIME_FIELD} -v datetime_format=${DATETIME_FORMAT} -v table=${TABLE} '{
      operation = $1:
      key_data = $2;

      where = "";
      split(key_data, v, ",");
      datetime = v[1];
      split(v[2], key_avps, ";");
      for (key_avp in key_avps) {
        split(key_avp, key, "=");
        key_field = key[1];
        key_value = key[2];
        where = where" "key_field" = \x24"key_value"\x24 AND";
      }
      where = substr(where, 1, length(where) - 4);

      if (operation == "UPDATE") {
        if (datetime_format == "DATETIME") {

        } else if (datetime_format == "TIMESTAMP") {
          print "UPDATE "table" set "datetime_field" = "datetime" WHERE "where";";
        }
      }
    }' ${TMP_DIR}/changes.${TABLE}.out > ${OUTPUT_DIR}/changes.${TABLE}.sql

  done < ${TMP_DIR}/tables

  logInfo "Updating control files"

  while read TABLE
  do
    if [ -f ${TMP_DIR}/${TABLE}.failed ]
    then
      logWarning "Processing of table '${TABLE}' failed. Control file is not updated "
      continue
    fi

    logInfo "Updating control file for table '${TABLE}'"

    echo ${TIMESTAMP_NOW} > ${CTRL_DIR}/${TABLE}.timestamp_last_execution
    if [ $? -ne 0 ]
    then
      logError "Command 'echo ${TIMESTAMP_NOW} > ${CTRL_DIR}/${TABLE}.timestamp_last_execution' failed"
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
