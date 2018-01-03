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
}


#
# Main
#

SCRIPT_BASEDIR=/opt/<%SIU_INSTANCE%>/scripts/monitoring/monitor-memory
export SCRIPT_BASEDIR

. /opt/<%SIU_INSTANCE%>/scripts/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
