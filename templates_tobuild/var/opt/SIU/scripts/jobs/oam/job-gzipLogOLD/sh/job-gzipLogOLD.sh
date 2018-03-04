#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

function process
{
  logDebug "Executing function 'process'"

  for FILEPATH in $(2>/dev/null ls /var/opt/<%SIU_INSTANCE%>/log/*.logOLD)
  do

    SUFFIX=$(date +"%Y%m%d%H%M%S")
    mv ${FILEPATH} ${FILEPATH}.${SUFFIX}
    if [ $? -ne 0 ]
    then
      logError "Command 'mv ${FILEPATH} ${FILEPATH}.${SUFFIX}' failed"
      continue
    fi

    gzip -f ${FILEPATH}.${SUFFIX}
    if [ $? -ne 0 ]
    then
      logError "Command 'gzip -f ${FILEPATH}.${SUFFIX}' failed"
      continue
    fi

    logInfo "File '${FILEPATH}' renamed and compressed"
  done
}


#
# Main
#

SCRIPT_BASEDIR=<%SCRIPTS_DIR%>/jobs/oam/job-gzipLogOLD
export SCRIPT_BASEDIR

. <%SCRIPTS_DIR%>/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
