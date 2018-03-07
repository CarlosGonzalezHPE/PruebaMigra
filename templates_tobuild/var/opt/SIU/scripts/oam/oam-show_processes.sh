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

SCRIPT=oam-show_processes
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

echo
echo "$(hostname) - PROCESSES STATUS"
echo
echo "DEG"

#
# Checking collectors
#
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "Collector" | while read PROCESS TYPE
do
  echo ${PROCESS} | awk '{ printf "  %-25s [ ", $1 }'
  RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/collector -JVMargs /var/opt/${SIU_INSTANCE}/${PROCESS}" 1)
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
done

#
# Checking session servers
#
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "SessionServer" | while read PROCESS TYPE
do
  echo ${PROCESS} | awk '{ printf "  %-25s [ ", $1 }'
  RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/SIUJava -JVMargs /var/opt/${SIU_INSTANCE}/${PROCESS}/JVMargs.ini com.hp.siu.sessionserver.SessionServer" 1)
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
done

#
# Checking file services
#
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "FileService" | while read PROCESS TYPE
do
  echo ${PROCESS} | awk '{ printf "  %-25s [ ", $1 }'
  RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/filecollectionserver -JVMargs /var/opt/${SIU_INSTANCE}/${PROCESS}/JVMargs.ini" 1)
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
done

#
# Checking NRBGUITool
#
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "NRBGUITool" | while read PROCESS TYPE
do
  echo ${PROCESS} | awk '{ printf "  %-25s [ ", $1 }'
  RESULT=$(check_if_already_running "$JAVA_HOME/bin/java -Djava.util.logging.config.file=/app/DEG/tomcat7/conf/logging.properties" 1)
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
done

#
# Checking IUM
#
echo
echo "IUM"
echo "AdminAgent" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/adminagentserver -daemonize" 1)
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

#
# Checking Config Server
#
if [ ${SIU_INSTANCE} = "SIU_MANAGER" ]
then
  echo "ConfigServer" | awk '{ printf "  %-25s [ ", $1 }'
  RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/configserver -JVMargs /var/opt/${SIU_INSTANCE}/ConfigServer/JVMargs.ini" 1)
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
fi

#
# Checking MySQL
#
if [ "${SIU_INSTANCE}" = 'SIU_MANAGER' ]
then
echo
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "MySQL" | while read PROCESS TYPE
do
echo "MySQL"
echo "Daemon" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/mysql/bin/mysqld" 1)
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
/opt/${SIU_INSTANCE}/mysql/bin/mysql -S /var/opt/${SIU_INSTANCE}/mysql/data/mysql.sock -u root -e 'show slave status\G' | egrep "Slave_IO_Running|Slave_SQL_Running" | grep -v "Slave_SQL_Running_State" > replicationStatus.txt

if grep -q Yes "replicationStatus.txt"; then
  setColorSuccess
  echo -n "RUNNING"
else
  setColorError
  echo -n "NOT RUNNING"
fi
  setColorNormal
echo " ]"

done
fi

#
# Checking Application MySQL
#
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "MySQL" | while read PROCESS TYPE
do
if [ ${SIU_INSTANCE} = "SIU_DEG01" ]
then
  for REMOTE_SERVER in $(cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "^MS_REMOTE_SERVER")
  do
     SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
     ssh ium@${SERVER} ". ./.bash_profile; oam-show_ms.sh"
  done
elif [ ${SIU_INSTANCE} = "SIU_DEG02" ]
then
  for REMOTE_SERVER in $(cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "^MS_REMOTE_SERVER")
  do
     SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
     ssh ium@${SERVER} ". ./.bash_profile; oam-show_ms.sh"
  done
fi
done

#
# Checking TimesTen
#
if [ "${SIU_INSTANCE}" = 'SIU_MANAGER' ]
then
echo
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "TimesTen" | while read PROCESS TYPE
do
echo "TimesTen"
echo "Daemon" | awk '{ printf "  %-25s [ ", $1 }'
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/TimesTen/${SIU_INSTANCE}_TT/bin/timestend -initfd" 1)
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
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/TimesTen/${SIU_INSTANCE}_TT/bin/timestensubd -verbose" 4)
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
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/TimesTen/${SIU_INSTANCE}_TT/bin/ttcserver -verbose" 1)
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
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/TimesTen/${SIU_INSTANCE}_TT/bin/timestenrepd -verbose" 1)
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
done
fi

#
# Checking Application TimesTen
#
cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "TimesTen" | while read PROCESS TYPE
do
if [ ${SIU_INSTANCE} = "SIU_DEG01" ]
then
  for REMOTE_SERVER in $(cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "^TT_REMOTE_SERVER")
  do
     SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
     ssh ium@${SERVER} ". ./.bash_profile; oam-show_tt.sh"
  done
elif [ ${SIU_INSTANCE} = "SIU_DEG02" ]
then
  for REMOTE_SERVER in $(cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "^TT_REMOTE_SERVER")
  do
     SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
     ssh ium@${SERVER} ". ./.bash_profile; oam-show_tt.sh"
  done
fi
done

#
# Checking remote servers
#
for REMOTE_SERVER in $(cat ${OAM_DIR}/cfg/oam-processes.cfg | grep -v "^#" | grep "^REMOTE_SERVER")
do
  SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
  ssh ium@${SERVER} ". ./.bash_profile; oam-show_processes.sh"
done