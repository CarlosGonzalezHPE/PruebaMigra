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

  ALARMS_DIR="$(getConfigParam SERVER_ALARMS DIRECTORY)"
  if [ $? -lt 0 ] || [ -z ${ALARMS_DIR} ]
  then
    logError "Unable to get mandatory parameter 'DIRECTORY' in section 'SERVER_ALARMS'"
    return 1
  fi
  logDebug "ALARMS_DIR = ${ALARMS_DIR}"

  ALARMS_FILENAME="$(getConfigParam SERVER_ALARMS FILENAME)"
  if [ $? -lt 0 ] || [ -z "${ALARMS_FILENAME}" ]
  then
    logError "Unable to get mandatory parameter 'FILENAME' in section 'SERVER_ALARMS'"
    return 1
  fi
  logDebug "ALARMS_FILENAME = ${ALARMS_FILENAME}"

  KPIS_DIR="$(getConfigParam SERVER_KPIS DIRECTORY)"
  if [ $? -lt 0 ] || [ -z ${KPIS_DIR} ]
  then
    logError "Unable to get mandatory parameter 'DIRECTORY' in section 'SERVER_KPIS'"
    return 1
  fi
  logDebug "KPIS_DIR = ${KPIS_DIR}"

  KPIS_FILENAME="$(getConfigParam SERVER_KPIS FILENAME)"
  if [ $? -lt 0 ] || [ -z "${KPIS_FILENAME}" ]
  then
    logError "Unable to get mandatory parameter 'FILENAME' in section 'SERVER_KPIS'"
    return 1
  fi
  logDebug "KPIS_FILENAME = ${KPIS_FILENAME}"

  getConfigSection MONITORS > ${TMP_DIR}/monitors
  if [ $? -lt 0 ]
  then
    logError "Unable to get mandatory section 'MONITORS'"
    return 1
  fi

  while read MONITOR
  do
    DIRECTORY="$(getConfigParam ${MONITOR} DIRECTORY)"
    if [ $? -lt 0 ] || [ -z ${DIRECTORY} ]
    then
      logError "Unable to get mandatory parameter 'DIRECTORY' in section '${MONITOR}'"
      return 1
    fi
    logDebug "DIRECTORY = ${DIRECTORY}"

    if [ ! -d ${DIRECTORY} ]
    then
      logWarning "Directory '${DIRECTORY}' is not accessible"
      continue
    fi

    logInfo "Fetching alarm file for monitor '${MONITOR}'"
    logDebug "Looking for file '${DIRECTORY}/alarms'"

    if [ -f ${DIRECTORY}/alarms ]
    then
      mv ${DIRECTORY}/alarms ${WORK_DIR}/alarms.${MONITOR}
      if [ $? -ne 0 ]
      then
        logError "Command 'mv ${DIRECTORY}/alarms ${WORK_DIR}/alarms.${MONITOR}' failed"
      fi
      cat ${WORK_DIR}/alarms.${MONITOR} >> ${WORK_DIR}/alarms.tmp

      rm -f ${WORK_DIR}/alarms.${MONITOR}

      logWarning "Fetched alarm file for monitor '${MONITOR}'"
    else
      logInfo "No alarm file available for monitor '${MONITOR}'"
    fi
  done < ${TMP_DIR}/monitors

  if [ ! -s ${WORK_DIR}/alarms.tmp ]
  then
    logWarning "No alarms reported"
  else
    cat ${WORK_DIR}/alarms.tmp | sort >> ${WORK_DIR}/alarms

    ACTUAL_ALARMS_FILENAME=$(eval echo "${ALARMS_FILENAME}")
    logDebug "ACTUAL_ALARMS_FILENAME = ${ACTUAL_ALARMS_FILENAME}"

    mv ${WORK_DIR}/alarms ${ALARMS_DIR}/${ACTUAL_ALARMS_FILENAME}
    if [ $? -ne 0 ]
    then
      logError "Command 'mv ${WORK_DIR}/alarms ${ALARMS_DIR}/${ACTUAL_ALARMS_FILENAME}}' failed"
      return 1
    fi

    logInfo "Alarms file '${ACTUAL_ALARMS_FILENAME}' created and moved to directory '${ALARMS_DIR}'"
  fi

  rm -f ${WORK_DIR}/alarms.tmp

  while read MONITOR
  do
    DIRECTORY="$(getConfigParam ${MONITOR} DIRECTORY)"
    if [ $? -lt 0 ] || [ -z ${DIRECTORY} ]
    then
      logError "Unable to get mandatory parameter 'DIRECTORY' in section '${MONITOR}'"
      return 1
    fi
    logDebug "DIRECTORY = ${DIRECTORY}"

    if [ ! -d ${DIRECTORY} ]
    then
      logWarning "Directory '${DIRECTORY}' is not accessible"
      continue
    fi

    logInfo "Fetching kpi file for monitor '${MONITOR}'"

    logDebug "Looking for file '${DIRECTORY}/kpis'"

    if [ -f ${DIRECTORY}/kpis ]
    then
      mv ${DIRECTORY}/kpis ${WORK_DIR}/kpis.${MONITOR}
      if [ $? -ne 0 ]
      then
        logError "Command 'mv ${DIRECTORY}/kpis ${WORK_DIR}/kpis.${MONITOR}' failed"
      fi
      cat ${WORK_DIR}/kpis.${MONITOR} >> ${WORK_DIR}/kpis.tmp

      rm -f ${WORK_DIR}/kpis.${MONITOR}

      logWarning "Fetched kpi file for monitor '${MONITOR}'"
    else
      logInfo "No kpi file available for monitor '${MONITOR}'"
    fi
  done < ${TMP_DIR}/monitors

  if [ ! -s ${WORK_DIR}/kpis.tmp ]
  then
    logWarning "No kpis reported"
  else
    cat ${WORK_DIR}/kpis.tmp | sort >> ${WORK_DIR}/kpis

    ACTUAL_KPIS_FILENAME=$(eval echo "${KPIS_FILENAME}")
    logDebug "ACTUAL_KPIS_FILENAME = ${ACTUAL_KPIS_FILENAME}"

    mv ${WORK_DIR}/kpis ${KPIS_DIR}/${ACTUAL_KPIS_FILENAME}
    if [ $? -ne 0 ]
    then
      logError "Command 'mv ${WORK_DIR}/kpis ${KPIS_DIR}/${ACTUAL_KPIS_FILENAME}}' failed"
      return 1
    fi

    logInfo "KPIs file '${ACTUAL_KPIS_FILENAME}' created and moved to directory '${KPIS_DIR}'"
  fi

  rm -f ${WORK_DIR}/kpis.tmp
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/jobs/monitoring/monitor
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/jobs/monitoring/job-common/sh/job-common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
