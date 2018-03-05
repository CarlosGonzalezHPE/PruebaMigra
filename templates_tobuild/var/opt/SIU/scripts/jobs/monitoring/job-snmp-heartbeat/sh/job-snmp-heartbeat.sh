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

  PMGR_PARAMETER="$(getConfigParam SNMP PMGR_PARAMETER)"
  if [ $? -lt 0 ] || [ -z "${PMGR_PARAMETER}" ]
  then
    logError "Unable to get mandatory parameter 'PMGR_PARAMETER' in section 'SNMP'"
    return 1
  fi

  logDebug "PMGR_PARAMETER = ${PMGR_PARAMETER}"

  SIU_INVK_COMMAND="$(getConfigParam SNMP SIU_INVK_COMMAND)"
  if [ $? -lt 0 ] || [ -z "${PMGR_PARAMETER}" ]
  then
    logError "Unable to get mandatory parameter 'SIU_INVK_COMMAND' in section 'SNMP'"
    return 1
  fi

  logDebug "SIU_INVK_COMMAND = ${SIU_INVK_COMMAND}"

  STATUS=$(/opt/${SIU_INSTANCE}/bin/processmanager jmx ${PMGR_PARAMETER} | grep ${PMGR_PARAMETER} | awk -F '=Server/Running =' '{ print $2 }' | awk '{ $1 = $1 ; print }')
  logDebug "STATUS = ${STATUS}"

  if [ "${STATUS}" = "true" ]
  then
    ${SIU_INVK_COMMAND} > ${TMP_DIR}/siuinvoke.out_err 2>&1

    if [ $? -ne 0 ]
    then
      logError "Command '${SIU_INVK_COMMAND}' failed"
      return 1
    else
      logInfo "SNMP heart beat successfully sent"
    fi
  fi
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/jobs/monitoring/job-snmp-heartbeat
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/jobs/monitoring/job-common/sh/job-common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
