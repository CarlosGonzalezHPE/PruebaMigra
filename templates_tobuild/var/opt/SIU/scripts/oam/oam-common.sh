#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

function check_if_already_running
{
  PROCESS=$1
  NUMBER_OF_INSTANCES=$2
  CURRENT_INSTANCES=$(ps -e -o pid,ppid,cmd | grep -E "^ *[0-9]+ *[0-9]+ *$1*" | grep -Ev "^ *$$ " | grep -Ev "^ *[0-9]+ *$$ " | wc -l)
  if [ ${CURRENT_INSTANCES} -eq ${NUMBER_OF_INSTANCES} ]
  then
    echo 0
  else
    echo 1
  fi
}


function lockExec
{
  if [ ! -z ${SCRIPT_NAME} ]
  then
    exec 200>${TMP_DIR}/.lock.${SCRIPT_NAME}
    flock 200
  fi
}


function unlockExec
{
  if [ ! -z ${SCRIPT_NAME} ]
  then
    flock -u 200
  fi
}


function exitAndUnlock
{
  if [ $# -gt 0 ]
  then
    EXIT_CODE=$1
  else
    EXIT_CODE=0
  fi

  unlockExec

  exit ${EXIT_CODE}
}


function setColorSuccess
{
  echo -en "\033[0;32m"
}


function setColorError
{
  echo -en "\033[0;31m"
}


function setColorWarning
{
  echo -en "\033[0;33m"
}


function setColorNormal
{
  echo -en "\033[0;39m"
}


function setColorTitle
{
  echo -en "\033[0;34m"
}


function setColorArgs
{
  echo -en "\033[0;35m"
}


function setColorArgs2
{
  echo -en "\033[0;36m"
}


TMP_DIR=/var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp
export TMP_DIR

mkdir -p ${TMP_DIR}

OUTPUT_DIR=/var/opt/<%SIU_INSTANCE%>/scripts/oam/output
export OUTPUT_DIR

mkdir -p ${OUTPUT_DIR}

BACKUP_DIR=/var/opt/<%SIU_INSTANCE%>/scripts/oam/backup
export BACKUP_DIR

mkdir -p ${BACKUP_DIR}
