#!/bin/bash
#-------------------------------------------------------------------------------
#
# Project : HP-DEG
#
# Version : 1.0                                                                 
# Author : HP CMS
#
# Component: oam-show_processes.sh
# Description: Script to show the status of DEG processes.
#
#-------------------------------------------------------------------------------

SCRIPT=oam-show_tt
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

echo
echo "$(hostname) - Application Timesten PROCESSES STATUS"

#
# Checking Application TimesTen
#
echo
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "TimesTen" | while read PROCESS TYPE
do
echo "DEG Application TimesTen"
if [ -f "/etc/init.d/tt_SIU_DEG01_TT" ]
then
echo "Daemon" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG01/TimesTen/SIU_DEG01_TT/bin/timestend -initfd" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"

echo "SubDaemons" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG01/TimesTen/SIU_DEG01_TT/bin/timestensubd -verbose" 4)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"

echo "Server" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG01/TimesTen/SIU_DEG01_TT/bin/ttcserver -verbose" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"

echo "RepAgents" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG01/TimesTen/SIU_DEG01_TT/bin/timestenrepd -verbose" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"
echo

elif [ -f "/etc/init.d/tt_SIU_DEG02_TT" ]
then	
echo "Daemon" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG02/TimesTen/SIU_DEG02_TT/bin/timestend -initfd" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"

echo "SubDaemons" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG02/TimesTen/SIU_DEG02_TT/bin/timestensubd -verbose" 4)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"

echo "Server" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG02/TimesTen/SIU_DEG02_TT/bin/ttcserver -verbose" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"

echo "RepAgents" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG02/TimesTen/SIU_DEG02_TT/bin/timestenrepd -verbose" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
setColorNormal
echo " ]"
echo
fi
done