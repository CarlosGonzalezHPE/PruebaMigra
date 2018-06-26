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

  RETURN_CODE=0

  ALARMING_ENABLED="$(getConfigParam GENERAL ALARMING_ENABLED)"
  if [ $? -ne 0 ]
  then
    logWarning "Unable to get parameter 'ALARMING_ENABLED' in section 'GENERAL'. Set to default TRUE"
    ALARMING_ENABLED=TRUE
  else
    if [ "${ALARMING_ENABLED}" != "FALSE" ]
    then
      ALARMING_ENABLED=TRUE
    fi
  fi
  logDebug "ALARMING_ENABLED = ${ALARMING_ENABLED}"

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

  REMOTE_PEER_IPADDRESS="$(getConfigParam GENERAL REMOTE_PEER_IPADDRESS)"
  if [ $? -lt 0 ] || [ -z ${REMOTE_PEER_IPADDRESS} ]
  then
    logError "Unable to get mandatory parameter 'REMOTE_PEER_IPADDRESS' in section 'GENERAL'"
    return 1
  fi
  logDebug "REMOTE_PEER_IPADDRESS = ${REMOTE_PEER_IPADDRESS}"

  REPLICATION_PORTS="$(getConfigParam GENERAL REPLICATION_PORTS)"
  if [ $? -lt 0 ] || [ -z ${REPLICATION_PORTS} ]
  then
    logError "Unable to get mandatory parameter 'REPLICATION_PORTS' in section 'GENERAL'"
    return 1
  fi

  logDebug "REPLICATION_PORTS = ${REPLICATION_PORTS}"
  IFS=','
  read -ra REPLICATION_PORTS_FIELDS <<< "${REPLICATION_PORTS}"
  for REPLICATION_PORTS_FIELD in "${REPLICATION_PORTS_FIELDS[@]}"
  do
    logDebug "REPLICATION_PORTS_FIELD = ${REPLICATION_PORTS_FIELD}"

    DB_INSTANCE=$(echo ${REPLICATION_PORTS_FIELD} | cut -d ":" -f 1)
    DB_DSN=$(echo ${REPLICATION_PORTS_FIELD} | cut -d ":" -f 2)
    DB_PORT=$(echo ${REPLICATION_PORTS_FIELD} | cut -d ":" -f 3)

    logDebug "DB_INSTANCE = ${DB_INSTANCE}"
    logDebug "DB_DSN = ${DB_DSN}"
    logDebug "DB_PORT = ${DB_PORT}"

    ncat ${REMOTE_PEER_IPADDRESS} ${DB_PORT} </dev/null >/dev/null 2> ${TMP_DIR}/ncat.${REMOTE_PEER_IPADDRESS}:${DB_PORT}.err
    if [ -s ${TMP_DIR}/ncat.${REMOTE_PEER_IPADDRESS}:${DB_PORT}.err ]
    then
      logError "Unable to connect to peer '${REMOTE_PEER_IPADDRESS}:${DB_PORT}' for replication with DSN '${DB_DSN}'"
      if [ "${ALARMING_ENABLED}" = "TRUE" ]
      then
        logAlarmError DegAlarm10.3 "Communication lost between sites"
      fi
      return 1
    fi

    logInfo "Connection to peer '${REMOTE_PEER_IPADDRESS}:${DB_PORT}' OK"

    > ${TMP_DIR}/show_slave_status.out 2>&1 /usr/bin/mysql -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} << EOF
    show slave status\G;
EOF
    if [ $? -ne 0 ]
    then
      logError "Command '> ${TMP_DIR}/show_slave_status.out 2>&1 /usr/bin/mysql -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} << EOF; show slave status\G; EOF' failed"
      return 1
    fi

    if [ $(cat ${TMP_DIR}/show_slave_status.out | grep -e "Slave_IO_Running: Yes" -e "Slave_SQL_Running: Yes" | wc -l) -ne 2 ]
    then
      logError "Replication is NOT running for DB Instance '${DB_INSTANCE}', DSN '${DB_DSN}'"
      logError "----"
      cat ${TMP_DIR}/show_slave_status.out | grep -e "Slave_IO_Running:" -e "Slave_SQL_Running:" >> ${LOG_FILEPATH}
      logError "----"
      if [ "${ALARMING_ENABLED}" = "TRUE" ]
      then
        logAlarmError DegAlarm10.4 "Replication is not active"
      fi
      return 1
    fi

    logInfo "Replication is running for DB Instance '${DB_INSTANCE}', DSN '${DB_DSN}'"
  done

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
        TIMESTAMP_LAST_EXECUTION=$(date +"%s" -d "-${DEFAULT_INTERVAL_MINUTES} minutes")
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
        SELECT_DATETIME="UNIX_TIMESTAMP(${DATETIME_FIELD})"
        DATETIME_CONDITION="UNIX_TIMESTAMP(${DATETIME_FIELD}) >= ${TIMESTAMP_LAST_EXECUTION} AND UNIX_TIMESTAMP(${DATETIME_FIELD}) < ${TIMESTAMP_BEFORE_IGNORED_LAST_MINUTES}"
        ;;
      "TIMESTAMP")
        SELECT_DATETIME="${DATETIME_FIELD} DIV 1000"
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
    AUX_SELECT_FIELDS2=
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
        AUX_SELECT_FIELDS2=${AUX_SELECT_FIELDS2}"'"${FIELD_NAME}"=',"${FIELD_NAME}",';',"
      fi
    done < ${TMP_DIR}/${TABLE}.fields

    logDebug "AUX_SELECT_KEY = ${AUX_SELECT_KEY}"
    logDebug "AUX_SELECT_FIELDS = ${AUX_SELECT_FIELDS}"
    logDebug "AUX_SELECT_FIELDS2 = ${AUX_SELECT_FIELDS2}"

    SELECT_KEY=${AUX_SELECT_KEY/%?????/}
    if [ -z "${SELECT_KEY}" ]
    then
      logError "No key defined to select data from table '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "SELECT_KEY = ${SELECT_KEY}"

    SELECT_FIELDS=${AUX_SELECT_FIELDS/%?/}
    if [ -z "${SELECT_FIELDS}" ]
    then
      logError "No fields defined to select data from table '${TABLE}'"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "SELECT_FIELDS = ${SELECT_FIELDS}"

    SQL_QUERY="SELECT CONCAT_WS('', ${SELECT_KEY}), ${SELECT_DATETIME}, CONCAT_WS('|', ${SELECT_FIELDS}) FROM ${TABLE} WHERE ${DATETIME_CONDITION} ORDER BY ${DATETIME_FIELD}"
    logDebug "SQL_QUERY = ${SQL_QUERY}"

    echo "${SQL_QUERY}" > ${TMP_DIR}/query-${TABLE}.sql
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

    if [ ! -f ${OUTPUT_DIR}/dump-${TABLE}.csv ]
    then
      touch ${OUTPUT_DIR}/dump-${TABLE}.csv
    fi

    if [ ! -s ${OUTPUT_DIR}/dump-${TABLE}.csv ]
    then
      touch ${TMP_DIR}/${TABLE}.skipped
      logWarning "No changes found in table '${TABLE}' for the selected time window"
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
    if [ $? -ne 0 ] || [ $(grep "No such file or directory" ${TMP_DIR}/scp-${TABLE}.err | wc -l) -gt 0 ] || [ ! -f ${OUTPUT_DIR}/remote/dump-${TABLE}.csv ]
    then
      logError "Command '> ${TMP_DIR}/scp-${TABLE}.out 2> ${TMP_DIR}/scp-${TABLE}.err scp ium@${REMOTE_PEER_IPADDRESS}:${OUTPUT_DIR}/dump-${TABLE}.csv ${OUTPUT_DIR}/remote' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
  done < ${TMP_DIR}/tables

  logInfo "Resolving conflicts"

  while read TABLE
  do
    logDebug "Resolving conflicts for table '${TABLE}'"

    if [ -f ${TMP_DIR}/${TABLE}.failed ]
    then
      logWarning "As previous operations failed, conflict resolution is aborted for table '${TABLE}'"
      continue
    fi

    if [ -f ${TMP_DIR}/${TABLE}.skipped ]
    then
      logWarning "Conflict resolution is skipped for table '${TABLE}'"
      continue
    fi

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
      touch ${TMP_DIR}/${TABLE}.conflict_resolution_disabled
    fi

    cat ${OUTPUT_DIR}/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted
    if [ $? -ne 0 ]
    then
      logError "Command 'cat ${OUTPUT_DIR}/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "Dump of local table has been sorted"

    cat ${OUTPUT_DIR}/remote/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted
    if [ $? -ne 0 ]
    then
      logError "Command 'cat ${OUTPUT_DIR}/remote/dump-${TABLE}.csv | sort > ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      continue
    fi
    logDebug "Dump of remote table has been sorted"

    logInfo "Computing differences for table '${TABLE}'"

    awk -F \, -v table=${TABLE} -v datetime_field=${DATETIME_FIELD} -v datetime_format=${DATETIME_FORMAT} -v out=${OUTPUT_DIR}/changes.${TABLE}.sql -v debug=${TMP_DIR}/changes.${TABLE}.debug -v now=$(date +"%s") '
    function ltrim(s) {
      sub(/^[ \t\r\n]+/, "", s);
      return s;
    }
    function rtrim(s) {
      sub(/[ \t\r\n]+\$/, "", s);
      return s;
    }
    function trim(s) {
      return rtrim(ltrim(s));
    }
    BEGIN {
      file_index    = 0;
      num_conflicts = 0;
    }
    {
      if (FNR == 1) {
        file_index++;
      }

      if (file_index == 1) {
        key_data = $1;
        local_timestamp[key_data] = $2;
        local_data[key_data] = $3;
        print "file_index="file_index", key_data="key_data", local_timestamp[key_data]="local_timestamp[key_data]", local_data[key_data]="local_data[key_data] >> debug;
        next;
      }

      if (file_index == 2) {
        key_data = $1;
        remote_timestamp = $2;
        remote_data = $3;

        print "file_index="file_index", key_data="key_data", remote_timestamp="remote_timestamp", remote_data="remote_data >> debug;
        if (key_data in local_data) {
          print "key_data is in local_data" >> debug;
          if (remote_data != local_data[key_data]) {
            print "remote_data != local_data[key_data]" >> debug;
            if (local_timestamp[key_data] >= remote_timestamp) {
              print "local_timestamp[key_data] >= remote_timestamp" >> debug;
              where = "";
              split(key_data, key_avps, ";");
              for (key_avp_index in key_avps) {
                key_avp = key_avps[key_avp_index];
                print "key_avp="key_avp >> debug;
                split(key_avp, key, "=");
                key_field = key[1];
                key_value = key[2];
                print "key_field="key_field", key_value="key_value >> debug;
                where = where" "key_field" = \x27"key_value"\x27 AND";
              }
              where = substr(where, 1, length(where) - 4);

              if (datetime_format == "TIMESTAMP") {
                print "UPDATE "table" SET "datetime_field" = "now" WHERE "where";" >> out;
              } else if (datetime_format == "DATETIME") {
                print "UPDATE "table" SET "datetime_field" = sysdate() WHERE "where";" >> out;
              }
            }
          }
        }
        else {
          remote_only_data[key_data] = $0;
        }
      }
    }' ${OUTPUT_DIR}/dump-${TABLE}.csv.sorted ${OUTPUT_DIR}/remote/dump-${TABLE}.csv.sorted

    if [ ! -f ${OUTPUT_DIR}/changes.${TABLE}.sql ]
    then
      logInfo "No conflicts detected for table '${TABLE}'"
      continue
    fi

    let NUM_CONFLICTS=$(cat ${OUTPUT_DIR}/changes.${TABLE}.sql | grep "^UPDATE " | wc -l)
    logDebug "NUM_CONFLICTS = ${NUM_CONFLICTS}"

    if [ ${NUM_CONFLICTS} -lt 1  ]
    then
      logInfo "No conflicts detected for table '${TABLE}'"
      continue
    fi

    touch ${TMP_DIR}/conflicts.flag

    if [ -f ${TMP_DIR}/${TABLE}.conflict_resolution_disabled ]
    then
      logWarning "Conflict resolution is not enabled for table '${TABLE}'. No changes will be done"
      continue
    fi

    logInfo "Executing changes in local table '${TABLE}'"

    > ${TMP_DIR}/changes-${TABLE}.out 2> ${TMP_DIR}/changes-${TABLE}.err /usr/bin/mysql -sN -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} -e "source ${OUTPUT_DIR}/changes.${TABLE}.sql"

    if [ $(grep -i error ${TMP_DIR}/changes-${TABLE}.out | wc -l) -gt 0 ] || [ -s ${TMP_DIR}/changes-${TABLE}.err ]
    then
      logError "Command '> ${TMP_DIR}/changes-${TABLE}.out 2> ${TMP_DIR}/changes-${TABLE}.err /usr/bin/mysql -sN -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} -e \"source ${OUTPUT_DIR}/changes.${TABLE}.sql\"' failed"
      touch ${TMP_DIR}/${TABLE}.failed
      touch ${TMP_DIR}/uncorrected_conflicts.flag
    fi
  done < ${TMP_DIR}/tables

  if [ -f ${TMP_DIR}/uncorrected_conflicts.flag ]
  then
    if [ "${ALARMING_ENABLED}" = "TRUE" ]
    then
      logWarning "Replication conflicts detected and not corrected"
      logAlarmError DegAlarm10.6 "Replication conflicts detected and not corrected"
    fi
  else
    if [ -f ${TMP_DIR}/conflicts.flag ]
    then
      if [ "${ALARMING_ENABLED}" = "TRUE" ]
      then
        logWarning "Replication conflicts detected and corrected"
        logAlarmWarning DegAlarm10.5 "Replication conflicts detected and corrected"
      fi
    fi
  fi

  while read TABLE
  do
    if [ -f ${TMP_DIR}/${TABLE}.failed ]
    then
      logWarning "Processing of table '${TABLE}' failed. Control file is not updated "
      RETURN_CODE=1
      continue
    fi

    #logInfo "Updating control file for table '${TABLE}'"

    #echo ${TIMESTAMP_NOW} > ${CTRL_DIR}/${TABLE}.timestamp_last_execution
    #if [ $? -ne 0 ]
    #then
    #  logError "Command 'echo ${TIMESTAMP_NOW} > ${CTRL_DIR}/${TABLE}.timestamp_last_execution' failed"
    #fi
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
  if [ "${ALARMING_ENABLED}" = "TRUE" ]
  then
    logAlarmError DegAlarm10.9 "Job execution failed (job-dbrep)"
  fi

  tar cvf ${OUTPUT_DIR}.tar ${OUTPUT_DIR}
  gzip -f ${OUTPUT_DIR}.tar
fi

rm -fr ${OUTPUT_DIR}

endOfExecution ${EXIT_CODE}
