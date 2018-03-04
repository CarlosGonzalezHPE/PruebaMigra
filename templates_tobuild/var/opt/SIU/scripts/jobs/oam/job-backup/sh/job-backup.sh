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
function backupDatabaseTables
{
  logDebug "Executing function 'backupDatabaseTables'"

  if [ ! -d /var/opt/SIU_MANAGER ]
  then
    logInfo "Directory '/var/opt/SIU_MANAGER' is not accessible. Database tables backup does not apply"
    return 0
  fi

  getConfigSection DATABASE_TABLES > ${TMP_DIR}/database_tables
  if [ $? -lt 0 ]
  then
    logInfo "Database tables backup does not apply"
    return 0
  fi

  if [ ! -s ${TMP_DIR}/database_tables ]
  then
    logInfo "No Database tables to be backed up"
    return 0
  fi

  while read LINE
  do
    DB_INSTANCE=$(echo ${LINE} | cut -d ";" -f 1)
    DB_DSN=$(echo ${LINE} | cut -d ";" -f 2)
    DB_TABLENAME=$(echo ${LINE} | cut -d ";" -f 3)
    logDebug "DB_INSTANCE = ${DB_INSTANCE}"
    logDebug "DB_DSN = ${DB_DSN}"
    logDebug "DB_TABLENAME = ${DB_TABLENAME}"

    logDebug "Processing table '${DB_TABLENAME}'"

    /usr/bin/mysqldump -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root ${DB_DSN} ${DB_TABLENAME} > ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt 2> ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.err
    if [ $? -ne 0 ] || [ -s ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.err ]
    then
      logError "Command '/usr/bin/mysqldump -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root ${DB_DSN} ${DB_TABLENAME} >${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt' failed"
      echo "${DB_TABLENAME}" >> ${TMP_DIR}/mysqldump.failed
    else
      if [ -s ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt ]
      then
        gzip -f ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt
        if [ $? -ne 0 ]
        then
          logError "Command 'gzip -f ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt' failed"
          echo "${DB_TABLENAME}" >> ${TMP_DIR}/mysqldump.failed
        else
          mv ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt.gz /data/backup
          if [ $? -ne 0 ]
          then
            logError "Command 'mv ${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt.gz /data/backup' failed"
            echo "${DB_TABLENAME}" >> ${TMP_DIR}/mysqldump.failed
          else
            logInfo "Table '${DB_TABLENAME}' backed up"
          fi
        fi
      else
        logWarning "File '${TMP_DIR}/${CURRENT_DATE}-DATABASE-${DB_INSTANCE}_${DB_DSN}_${DB_TABLENAME}.txt' is empty. Table '${DB_TABLENAME}' is NOT backed up"
      fi
    fi
  done < ${TMP_DIR}/database_tables

  if [ -s ${TMP_DIR}/mysqldump.failed ]
  then
    return 1
  fi
}


function backupIUMConfig
{
  logDebug "Executing function 'backupIUMConfig'"

  if [ ! -d /var/opt/SIU_MANAGER ]
  then
    logInfo "Directory '/var/opt/SIU_MANAGER' is not accessible. IUM configuration backup does not apply"
    return 0
  fi

  > ${TMP_DIR}/saveconfig.out 2> ${TMP_DIR}/saveconfig.err /opt/SIU_MANAGER/bin/saveconfig -f ${TMP_DIR}/${CURRENT_DATE}-DEG.cfg
  if [ $? -ne 0 ]
  then
    logError "Command '/opt/SIU_MANAGER/bin/saveconfig -f ${TMP_DIR}/${CURRENT_DATE}-DEG.cfg' failed"
    return 1
  fi

  gzip -f ${TMP_DIR}/${CURRENT_DATE}-DEG.cfg
  if [ $? -ne 0 ]
  then
    logError "Command 'gzip -f ${TMP_DIR}/${CURRENT_DATE}-DEG.cfg' failed"
    return 1
  fi

  mv ${TMP_DIR}/${CURRENT_DATE}-DEG.cfg.gz /data/backup
  if [ $? -ne 0 ]
  then
    logError "Command 'mv ${TMP_DIR}/${CURRENT_DATE}-DEG.cfg.gz /data/backup' failed"
    return 1
  fi
}

[#SECTION_BEGIN:CLUSTER#]
function backupCluster
{
  logDebug "Executing function 'backupCluster'"

  if [ ! -d /var/opt/SIU_MANAGER ]
  then
    logInfo "Directory '/var/opt/SIU_MANAGER' is not accessible. Cluster configuration backup does not apply"
    return 0
  fi

  sudo -A pcs config backup > ${TMP_DIR}/${CURRENT_DATE}-pcs.bck
  if [ $? -ne 0 ]
  then
    logError "Command 'sudo -A pcs config backup > ${TMP_DIR}/${CURRENT_DATE}-pcs.bck' failed"
    return 1
  fi

  sudo -A chown ium:ium ${TMP_DIR}/${CURRENT_DATE}-pcs.bck
  if [ $? -ne 0 ]
  then
    logError "Command 'sudo -A chown ium:ium ${TMP_DIR}/${CURRENT_DATE}-pcs.bck' failed"
    return 1
  fi

  gzip -f ${TMP_DIR}/${CURRENT_DATE}-pcs.bck
  if [ $? -ne 0 ]
  then
    logError "Command 'gzip -f ${TMP_DIR}/${CURRENT_DATE}-pcs.bck' failed"
    return 1
  fi

  mv ${TMP_DIR}/${CURRENT_DATE}-pcs.bck.gz /data/backup
  if [ $? -ne 0 ]
  then
    logError "Command 'mv ${TMP_DIR}/${CURRENT_DATE}-pcs.bck.gz /data/backup' failed"
    return 1
  fi
}
[#SECTION_END#]
[#SECTION_END#]

function backupFiles
{
  logDebug "Executing function 'backupFiles'"

  getConfigSection FILES_${BACKUP_MODE} > ${TMP_DIR}/files
  if [ $? -lt 0 ]
  then
    logError "Unable to get section 'FILES'"
    return 1
  fi

  if [ ! -s ${TMP_DIR}/files ]
  then
    logInfo "No files to be backed up"
    return 0
  fi

  rm -f /data/backup/${CURRENT_DATE}-FILES.tar
  > /data/backup/.tmp_${CURRENT_DATE}-FILES.tar

  while read LINE
  do
    FILES_DIR=$(echo ${LINE} | cut -d ";" -f 1)
    FILES_FILENAMEREGEX=$(echo ${LINE} | cut -d ";" -f 2)
    logDebug "FILES_DIR = ${FILES_DIR}"
    logDebug "FILES_FILENAMEREGEX = ${FILES_FILENAMEREGEX}"

    if [ -z ${FILES_DIR} ] || [ -z ${FILES_FILENAMEREGEX} ]
    then
      logWarning "Invalid line: ${LINE}. Line is skipped"
      continue
    fi

    sudo -A cd ${FILES_DIR} >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
      logWarning "Directory '${FILES_DIR}' is not accessible"
      sudo -A cd - >/dev/null 2>&1
      continue
    fi
    sudo -A cd - >/dev/null 2>&1

    logDebug "Processing directory '${FILES_DIR}'"

    > ${TMP_DIR}/current_dir.failed

    if [ "${FILES_FILENAMEREGEX}" = ".*" ]
    then
      logDebug "TAR applies to full directory"
      >> ${TMP_DIR}/tar.out_err 2>&1 sudo -A tar -rf /data/backup/.tmp_${CURRENT_DATE}-FILES.tar "${FILES_DIR}"
      if [ $? -ne 0 ]
      then
        logError "Command '>> ${TMP_DIR}/tar.out_err 2>&1 sudo -A tar -rf /data/backup/.tmp_${CURRENT_DATE}-FILES.tar \"${FILES_DIR}\"' failed"
        echo ${FILES_DIR} >> ${TMP_DIR}/files.failed
        echo ${FILES_DIR} >> ${TMP_DIR}/current_dir.failed
      else
        logDebug "File '${FILEPATH}' appended to TAR file '${TMP_DIR}/${CURRENT_DATE}-FILES.tar'"
        sync
      fi
    else
      sudo -A find ${FILES_DIR} -type f | grep -P "${FILES_FILENAMEREGEX}" | while read FILEPATH
      do
        >> ${TMP_DIR}/tar.out_err 2>&1 sudo -A tar -rf /data/backup/.tmp_${CURRENT_DATE}-FILES.tar "${FILEPATH}"
        if [ $? -ne 0 ]
        then
          logError "Command 'sudo -A tar -rf ${TMP_DIR}/${CURRENT_DATE}-FILES.tar \"${FILEPATH}\"' failed"
          echo ${FILEPATH} >> ${TMP_DIR}/files.failed
          echo ${FILEPATH} >> ${TMP_DIR}/current_dir.failed
        else
          logDebug "File '${FILEPATH}' appended to TAR file '${TMP_DIR}/${CURRENT_DATE}-FILES.tar'"
          sync
        fi
      done
    fi

    sudo -A chown ium:ium /data/backup/.tmp_${CURRENT_DATE}-FILES.tar

    if [ -s ${TMP_DIR}/current_dir.failed ]
    then
      logWarning "Files in directory '${FILES_DIR}' backed up with errors"
    else
      logInfo "Files in directory '${FILES_DIR}' backed up"
    fi
  done < ${TMP_DIR}/files

  mv /data/backup/.tmp_${CURRENT_DATE}-FILES.tar /data/backup/${CURRENT_DATE}-FILES.tar
  if [ $? -ne 0 ]
  then
    logError "Command 'mv /data/backup/.tmp_${CURRENT_DATE}-FILES.tar /data/backup/${CURRENT_DATE}-FILES.tar' failed"
    echo "mv /data/backup/.tmp_${CURRENT_DATE}-FILES.tar /data/backup/${CURRENT_DATE}-FILES.tar" >> ${TMP_DIR}/files.failed
  else
    gzip -f /data/backup/${CURRENT_DATE}-FILES.tar
    if [ $? -ne 0 ]
    then
      logError "Command 'gzip -f /data/backup/${CURRENT_DATE}-FILES.tar' failed"
      echo "gzip -f /data/backup/${CURRENT_DATE}-FILES.tar" >> ${TMP_DIR}/files.failed
    else
      logInfo "File '/data/backup/${CURRENT_DATE}-FILES.tar.gz' successfully created"
    fi
  fi

  if [ -s ${TMP_DIR}/files.failed ]
  then
    return 1
  fi
}


function process
{
  logDebug "Executing function 'process'"

  RETURN_CODE=0

  if [ ! -d /data/backup ]
  then
    logInfo "Directory '/data/backup' is not accessible. Backup does not apply"
    return 0
  fi

  logInfo "Backing up IUM configuration"
  backupIUMConfig
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  logInfo "Backing up Cluster"
  backupCluster
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  logInfo "Backing up Database Tables"
  backupDatabaseTables
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  logInfo "Backing up Files"
  backupFiles
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  return ${RETURN_CODE}
}


#
# Main
#

while getopts "m:" OPT
do
  case ${OPT} in
    m)
      BACKUP_MODE=${OPTARG}
      export BACKUP_MODE
      ;;
    *)
      echo "Error: Bad option '${OPT}'"
      exit 1
      ;;
  esac
done

if [ -z ${BACKUP_MODE} ]
then
  echo "Usage: oam-backup.sh -m FULL|LITE"
  exit 1
fi

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/jobs/oam/job-backup
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/common/common.sh

EXIT_CODE=0
CURRENT_DATE=$(date +%Y%m%d)

case "${BACKUP_MODE}" in
  "FULL" | "LITE")
    logInfo "Processing backup in mode '${BACKUP_MODE}'"
    process
    if [ $? -ne 0 ]
    then
      EXIT_CODE=$?
      logWarning "Function 'backup' executed with errors"
    fi
    ;;
  *)
    logError "Unsupported mode '${BACKUP_MODE}'"
    EXIT_CODE=1
    ;;
esac

endOfExecution ${EXIT_CODE}
