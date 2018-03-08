#!/bin/bash
#-------------------------------------------------------------------------------
#
# Project : HP-DEG
#
# Version : 1.0                                                                 
# Author : HP CMS
#
# Component: oam-show_ms.sh
# Description: Script to show the status of MySQL processes.
#
#-------------------------------------------------------------------------------

SCRIPT=oam-show_ms
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

echo
echo "$(hostname) - Application MySQL PROCESSES STATUS"

#
# Checking Application MySQL
#

echo
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "MySQL" | while read PROCESS TYPE
do
echo "DEG Application MySQL"
if [ -f "/etc/init.d/SIU_DEG01" ]
then
echo "Daemon" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/SIU_DEG01/mysql/bin/mysqld" 1)
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

echo "Replication" | awk '{ printf "  %-25s [ ", $1 }'
/opt/SIU_DEG01/mysql/bin/mysql -S /var/opt/SIU_DEG01/mysql/data/mysql.sock -u root -e 'show slave status\G' | egrep "Slave_IO_Running|Slave_SQL_Running" | grep -v "Slave_SQL_Running_State" > replicationStatus.txt

if grep -q Yes "replicationStatus.txt"; then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
  setColorNormal
echo " ]"
echo

elif [ -f "/etc/init.d/SIU_DEG02" ]
then	
echo "Daemon" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/$SIU_DEG01/mysql/bin/mysqld" 1)
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

echo "Replication" | awk '{ printf "  %-25s [ ", $1 }'
/opt/SIU_DEG02/mysql/bin/mysql -S /var/opt/SIU_DEG02/mysql/data/mysql.sock -u root -e 'show slave status\G' | egrep "Slave_IO_Running|Slave_SQL_Running" | grep -v "Slave_SQL_Running_State" > replicationStatus.txt

if grep -q Yes "replicationStatus.txt"; then
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