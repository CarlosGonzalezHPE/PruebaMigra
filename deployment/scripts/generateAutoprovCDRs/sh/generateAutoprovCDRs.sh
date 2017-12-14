#!/bin/bash
#-------------------------------------------------------------------------------
# Orange Spain DEG
#
# HPE CMS Iberia, 2017
#-------------------------------------------------------------------------------
# Descripcion: Script comun
#-------------------------------------------------------------------------------


function process
{
  logDebug "Executing function 'process'"

}


#
# Main
#

SCRIPT_BASEDIR=/opt/SIU_MANAGER/scripts/generateAutoprovCDRs
export SCRIPT_BASEDIR

. /opt/SIU_MANAGER/scripts/common/common.sh


process

endOfExecution
