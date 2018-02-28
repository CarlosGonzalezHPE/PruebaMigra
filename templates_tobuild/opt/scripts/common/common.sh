#!/bin/bash
#-------------------------------------------------------------------------------
# Orange Spain DEG
#
# HPE CMS Iberia, 2017
#-------------------------------------------------------------------------------
# Descripcion: Script comun
#-------------------------------------------------------------------------------

#
# Variables
#

MYSQL_PATH=/usr/bin/mysql
export MYSQL_PATH

# Default log file path
LOG_FILEPATH=/tmp/scripts.log
export LOG_FILEPATH

SITE_INDEX=00
export SITE_INDEX

SIU_INSTANCE=<%SIU_INSTANCE%>
export SIU_INSTANCE


#
# Functions
#

function logInfo
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")
  echo "${DATE} INF [$(printf "%5.5d" $$)] --- ${1}" >> ${LOG_FILEPATH}
}


function logError
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")
  echo "${DATE} ERR [$(printf "%5.5d" $$)] --- ${1}" >> ${LOG_FILEPATH}
}


function logWarning
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")
  echo "${DATE} WRN [$(printf "%5.5d" $$)] --- ${1}" >> ${LOG_FILEPATH}
}


function logDebug
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")

  if [ "${LOG_LEVEL}" = "DEBUG" ]
  then
    echo "${DATE} DBG [$(printf "%5.5d" $$)]--- ${1}" >> ${LOG_FILEPATH}
  fi
}


function getConfigParam
{
  typeset local SECTION
  typeset local PARAM
  typeset local SCOPE

  case ${#} in
    2)
      SCOPE=SELF
      ;;
    3)
      SCOPE=${3}
      ;;
    *)
      logError "Usage: getConfigParam <SECTION> <PARAMETER> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  SECTION=$1
  PARAM=$2

  case "${SCOPE}" in
    "SELF")
      if [ -s ${OVERRIDE_CFG_FILEPATH} ]
      then
        FILEPATH=${OVERRIDE_CFG_FILEPATH}
      else
        FILEPATH=${CFG_FILEPATH}
      fi
      ;;
    *)
      logError "Unsupported value '${AMBITO}' for argument 'SCOPE'. Usage: getConfigParam <SECTION> <PARAMETER> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  logDebug "Get parameter '${PARAM}' in configuration section '${SECTION}' in file '${FILEPATH}'"

  awk -F= -v seccion="${SECTION}" -v param="${PARAM}" '
    BEGIN {
      searching = 0;
      sectionFound = 0;
      begin = "[" seccion "]";
      end = "[/" seccion "]";
    }
    {
      if ( substr( $0, 0, length( begin ) ) == begin ) {
        searching = 1;
      }
      else if (( substr( $0, 0, length( end ) ) == end ) && ( searching == 1 )) {
        searching = 0;
        print "";
        if ( sectionFound == 0 ) {
          exit 1;
        }
        else {
          exit 0;
        }
      }
      else if (( searching ) && ( substr( $0, 0, 1 ) != "#" ) && ( $1 == param )) {
        print $2;
        exit 0;
      }
    } ' ${FILEPATH}
}


function getConfigSection
{
  typeset local SECTION
  typeset local SCOPE
  typeset local FILEPATH

  case ${#} in
    1)
      SECTION=$1
      SCOPE=SELF
      ;;
    2)
      SECTION=$1
      SCOPE=${2}
      ;;
    *)
      logError "Usage: getConfigSeccion <SECTION> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  case "${SCOPE}" in
    "SELF")
      if [ -s ${OVERRIDE_CFG_FILEPATH} ]
      then
        FILEPATH=${OVERRIDE_CFG_FILEPATH}
      else
        FILEPATH=${CFG_FILEPATH}
      fi
      ;;
    *)
      logError "Unsupported value '${AMBITO}' for argument 'SCOPE'. Usage: getConfigSeccion <SECTION> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  logDebug "Getting configuration section '${SECTION}' in file '${FILEPATH}"

  awk -v seccion="${SECTION}" '
    BEGIN {
      searching = 0;
      sectionFound = 0
      begin = "[" seccion "]";
      end = "[/" seccion "]";
    }
    {
      if ( substr( $0, 0, length( begin ) ) == begin ) {
        searching = 1;
        sectionFound = 1;
      }
      else if (( substr( $0, 0, length( end ) ) == end ) && ( searching == 1 )) {
        searching = 0;
        if ( sectionFound == 0 ) {
          exit 1;
        }
        else {
          exit 0;
        }
      }
      else if (( searching ) && ( substr( $0, 0, 1 ) != "#" ) && ( length($0) > 0 )) {
        print $0;
      }
    }' ${FILEPATH}

    return $?
}


function exitIfNotEnabled
{
  typeset local ENABLED=$(getConfigParam GENERAL ENABLED)
  if [ ${?} -ne 0 ] || [ "${ENABLED}" = "" ]
  then
    logError "Unable to get configuration parameter 'ENABLED' in section 'GENERAL'"
    endOfExecution 1
  fi

  if [ "${ENABLED}" != "TRUE" ]
  then
    logWarning "Script '${SCRIPT_NAME}' is disabled"
    endOfExecution
  fi

  logDebug "Script '${SCRIPT_NAME}' is enabled"
}


function exitIfExecutionConflict
{
  typeset local CONCURRENT_EXECUTIONS_ALLOWED=$(getConfigParam GENERAL CONCURRENT_EXECUTIONS_ALLOWED)
  if [ ${?} -eq 0 ] && [ "${CONCURRENT_EXECUTIONS_ALLOWED}" = "TRUE" ]
  then
    logInfo "Concurent execution allowed"
    return
  fi

  if [ -f ${CONTROL_FILEPATH} ]
  then
    # ID = PID + PPID + COMANDO
    AUX_PID=$(cat ${CONTROL_FILEPATH} | cut -d " " -f 1)
    AUX_PPID=$(cat ${CONTROL_FILEPATH} | cut -d " " -f 2)
    AUX_COMMAND=$(cat ${CONTROL_FILEPATH} | cut -d " " -f 3-)

    ID_EN_EJECUCION=$(ps -ef | awk '{ $1=$4=$5=$6=$7=""; print $0; }' | sed 's/^ *//g' | sed 's/  */ /g' | grep "^${AUX_PID} ${AUX_PPID} ${AUX_COMMAND}")
    if [ "${ID_EN_EJECUCION}" != "" ]
    then
      logWarning "Last execution of script '${SCRIPT_NAME}' has not finished and concurrent executiosn are not allowed"
      endOfExecution -2
    fi
  fi

  logDebug "Control file '${CONTROL_FILEPATH}' has been checked. No current execution detectewd."

  # ID = PID + PPID + COMANDO
  ID=$(ps -p ${$} -f | tail -n 1 | awk '{ $1=$4=$5=$6=$7=""; print $0; }' | sed 's/^ *//g' | sed 's/  */ /g')
  echo "${ID}" > ${CONTROL_FILEPATH}
  if [ $? -ne 0 ]
  then
    logError "Unable to create control file '${CONTROL_FILEPATH}'"
    endOfExecution 1
  fi

  logDebug "Control file '${CONTROL_FILEPATH}' has been created"
}


function deleteControlFile
{
  rm -f ${CONTROL_FILEPATH}
}


function beginingOfExecution
{
  SCRIPT_NAME=$(basename ${SCRIPT_BASEDIR})
  export SCRIPT_NAME

  if [ -z ${RUN_LABEL} ]
  then
    RUN_DIR=${SCRIPT_BASEDIR}
    export RUN_DIR
  else
    RUN_DIR=${SCRIPT_BASEDIR}/run/${RUN_LABEL}
    export RUN_DIR
  fi

  LOG_DIR=${RUN_DIR}/log
  export LOG_DIR

  TMP_DIR=${RUN_DIR}/tmp
  export TMP_DIR

  CTRL_DIR=${RUN_DIR}/ctrl
  export CTRL_DIR

  WORK_DIR=${RUN_DIR}/work
  export WORK_DIR

  for DIR in ${LOG_DIR} ${TMP_DIR} ${CTRL_DIR} ${WORK_DIR}
  do
    mkdir -p ${DIR}

    >/dev/null 2>&1 cd ${DIR}
    if [ $? -ne 0 ]
    then
      logError "Unable to access to directory '${DIR}'"
      >/dev/null 2>&1 cd -
      endOfExecution 1
    fi
  done

  CONTROL_FILEPATH=${CTRL_DIR}/current_exec
  export CONTROL_FILEPATH

  LOG_FILEPATH=${LOG_DIR}/${SCRIPT_NAME}-$(date "+%Y%m%d").log
  export LOG_FILEPATH

  logInfo "Begining of execution"

  CFG_FILEPATH=${SCRIPT_BASEDIR}/cfg/${SCRIPT_NAME}.cfg
  if [ ! -f ${CFG_FILEPATH} ]
  then
    logError "File '${CFG_FILEPATH}' does not exists"
    endOfExecution 1
  fi
  export CFG_FILEPATH

  OVERRIDE_CFG_FILEPATH=${SCRIPT_BASEDIR}/ctrl/${SCRIPT_NAME}.cfg
  export OVERRIDE_CFG_FILEPATH

  LOG_LEVEL=$(getConfigParam GENERAL LOG_LEVEL)
  if [ ${?} -ne 0 ] || [ "${LOG_LEVEL}" = "" ]
  then
    logWarning "Unable to get configuration parameter 'LOG_LEVEL' in section 'GENERAL'"
    LOG_LEVEL=INFO
  fi
  export LOG_LEVEL

  logInfo "Log level set to '${LOG_LEVEL}'"

  exitIfNotEnabled

  exitIfExecutionConflict

  if [ "${LOGLEVEL}" == "DEBUG" ]
  then
    COPY_NAME=tmp.debug.$(date +"%Y%m%d%H%M%S")
    mkdir -p ${RUN_DIR}/${COPY_NAME}
    mv ${TMP_DIR}/* ${RUN_DIR}/${COPY_NAME}
    if [ $? -ne 0 ]
    then
      logError "Command 'mv ${TMP_DIR}/* ${RUN_DIR}/${COPY_NAME}' failed"
    else
      cd ${RUN_DIR}
      if [ $? -ne 0 ]
      then
        logError "Unable to access directory '${RUN_DIR}'"
      else
        tar cvf ${COPY_NAME}.tar ${COPY_NAME}
        if [ $? -ne 0 ]
        then
          logError "Command 'tar cvf ${COPY_NAME}.tar ${COPY_NAME}' failed"
        else
          rm -fr ${COPY_NAME}

          gzip ${COPY_NAME}.tar
          if [ $? -ne 0 ]
          then
            logError "Command 'gzip ${COPY_NAME}.tar' failed"
          fi
        fi
        cd -
      fi
    fi
  fi

  rm -fr ${TMP_DIR}/*
}


function endOfExecution
{
  if [ $# -eq 0 ]
  then
    CODE=0
  else
    CODE=$1

    COPY_NAME=tmp.error.$(date +"%Y%m%d%H%M%S")
    cp -r ${TMP_DIR} ${SCRIPT_BASEDIR}/${COPY_NAME}
    if [ $? -ne 0 ]
    then
      logError "Command 'cp -r ${TMP_DIR} ${RUN_DIR}/${COPY_NAME}' failed"
    else
      cd ${SCRIPT_BASEDIR}
      if [ $? -ne 0 ]
      then
        logError "Unable to access directory '${RUN_DIR}'"
      else
        >/dev/null tar cvf ${COPY_NAME}.tar ${COPY_NAME}
        if [ $? -ne 0 ]
        then
          logError "Command 'tar cvf ${COPY_NAME}.tar ${COPY_NAME}' failed"
        else
          rm -fr ${COPY_NAME}

          gzip ${COPY_NAME}.tar
          if [ $? -ne 0 ]
          then
            logError "Command 'gzip ${COPY_NAME}.tar' failed"
          fi
        fi
        cd - >/dev/null 2>&1
      fi
    fi
  fi

  purgeLogFiles

  deleteControlFile

  logInfo "End of execution -- RETURN CODE = ${CODE}"

  exit ${CODE}
}


function purgeLogFiles
{
  LOG_PURGE_DELETE_DAYS=$(getConfigParam GENERAL LOG_PURGE_DELETE_DAYS)
  if [ ${?} -ne 0 ] || [ "${LOG_PURGE_DELETE_DAYS}" = "" ]
  then
    logWarning "Unable to get configuration parameter 'LOG_PURGE_DELETE_DAYS' in section 'GENERAL'. Set to default value '32'"
    LOG_PURGE_DELETE_DAYS=32
  fi
  logDebug "LOG_PURGE_DELETE_DAYS = '${LOG_PURGE_DELETE_DAYS}'"

  logDebug "Deleting files older than ${LOG_PURGE_DELETE_DAYS} days"
  find $(dirname ${LOG_FILEPATH}) -type f -mtime +${LOG_PURGE_DELETE_DAYS} | while read FILEPATH
  do
    rm -f ${FILEPATH}
    logInfo "File '${FILEPATH}' has been purged"
  done

  LOG_PURGE_COMPRESS_DAYS=$(getConfigParam GENERAL LOG_PURGE_COMPRESS_DAYS)
  if [ ${?} -ne 0 ] || [ "${LOG_PURGE_COMPRESS_DAYS}" = "" ]
  then
    logWarning "Unable to get configuration parameter 'LOG_PURGE_COMPRESS_DAYS' in section 'GENERAL'. Set to default value '8'"
    LOG_PURGE_COMPRESS_DAYS=8
  fi

  logDebug "LOG_PURGE_COMPRESS_DAYS = '${LOG_PURGE_COMPRESS_DAYS}'"

  logDebug "Compressing files older than ${LOG_PURGE_COMPRESS_DAYS} days"
  find $(dirname ${LOG_FILEPATH}) -type f -mtime +${LOG_PURGE_COMPRESS_DAYS} | grep -v ".gz$" | while read FILEPATH
  do
    gzip -f ${FILEPATH}
    logInfo "File '${FILEPATH}' has been compressed"
  done
}


#
# Main
#

COMMAND=$(basename $0)

if [ -z ${SCRIPT_BASEDIR} ]
then
  logInfo "${COMMAND} - Begining of execution"
  logError "${COMMAND} - Mandatory environment variable 'SCRIPT_BASEDIR' is not defined"
  logInfo "${COMMAND} - End of execution"
  exit -1
fi

beginingOfExecution
