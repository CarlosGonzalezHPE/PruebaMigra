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

  RETURN_CODE=0

  logInfo "Locking/Unlocking user accounts"
  lockUnlockUserAccounts
  if [ $? -ne 0 ]
  then
    RETURN_CODE=1
  fi

  return ${RETURN_CODE}
}


#
# Main
#

SCRIPT_BASEDIR=/var/opt/<%SIU_INSTANCE%>/scripts/jobs/oam/job-nrb
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
