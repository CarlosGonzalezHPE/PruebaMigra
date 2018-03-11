#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT=oam-show_processes
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

echo
if [ ${SIU_INSTANCE} = "SIU_MANAGER" ]
then
  echo "PROCESSES STATUS - Manager on host '$(hostname)'"
else
  echo "PROCESSES STATUS - Application Server on host '$(hostname)'"
fi
echo
echo -n "  ["
RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/adminagentserver -daemonize" 1)
if [ ${RESULT} -eq 0 ]
then
  setColorSuccess
  echo -n "STARTED"
else
  setColorError
  echo -n "STOPPED"
fi
setColorNormal
echo "] AdminAgent"

if [ ${SIU_INSTANCE} = "SIU_MANAGER" ]
then
  echo -n "  ["
  RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/configserver -JVMargs /var/opt/${SIU_INSTANCE}/ConfigServer/JVMargs.ini" 1)
  if [ ${RESULT} -eq 0 ]
  then
    setColorSuccess
    echo -n "STARTED"
  else
    setColorError
    echo -n "STOPPED"
  fi
  setColorNormal
  echo "] ConfigServer"
fi
echo

cat /var/opt/${SIU_INSTANCE}/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | sort | while read PROCESS TYPE
do
  case "${TYPE}" in
    "Collector")
      RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/collector -JVMargs /var/opt/${SIU_INSTANCE}/${PROCESS}" 1)
      ;;
    "SessionServer")
      RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/SIUJava -JVMargs /var/opt/${SIU_INSTANCE}/${PROCESS}/JVMargs.ini com.hp.siu.sessionserver.SessionServer" 1)
      ;;
    "FileService")
      RESULT=$(check_if_already_running "/opt/${SIU_INSTANCE}/bin/filecollectionserver -JVMargs /var/opt/${SIU_INSTANCE}/${PROCESS}/JVMargs.ini" 1)
      ;;
    *)
      continue
      ;;
  esac

  echo -n "  ["
  if [ ${RESULT} -eq 0 ]
  then
    setColorSuccess
    echo -n "STARTED"
  else
    setColorError
    echo -n "STOPPED"
  fi
  setColorNormal
  echo "] ${PROCESS}"
done


if [ "${SIU_INSTANCE}" = 'SIU_MANAGER' ]
then
  echo
  echo -n "  ["
  RESULT=$(check_if_already_running "bin/java -Djava.util.logging.config.file=/app/DEG/tomcat7/conf/logging.properties" 1)
  if [ ${RESULT} -eq 0 ]
  then
    setColorSuccess
    echo -n "STARTED"
  else
    setColorError
    echo -n "STOPPED"
  fi
  setColorNormal
  echo "] NRBGUITool"

  echo
  echo -n "  ["
  RESULT=$(check_if_already_running "/usr/sbin/mysqld --basedir=/usr --datadir=/var/Mariadb/DEG_APP_MD/data" 1)
  if [ ${RESULT} -eq 0 ]
  then
    setColorSuccess
    echo -n "STARTED"
  else
    setColorError
    echo -n "STOPPED"
  fi
  setColorNormal
  echo "] MariaDb (App Servers Instance)"
  echo -n "  ["
  RESULT=$(check_if_already_running "/usr/sbin/mysqld --basedir=/usr --datadir=/var/Mariadb/DEG_MGR_MD/data" 1)
  if [ ${RESULT} -eq 0 ]
  then
    setColorSuccess
    echo -n "STARTED"
  else
    setColorError
    echo -n "STOPPED"
  fi
  setColorNormal
  echo "] MariaDb (Manager Instance)"

#  echo -n "  ["
#  /usr/bin/mysql -S /var/Mariadb/DEG_MGR_MD/mysql.sock -u root -e 'show slave status\G' | egrep "Slave_IO_Running|Slave_SQL_Running" | grep -v "Slave_SQL_Running_State" > /tmp/replicationStatus.$$
#
#  if [ $(cat /tmp/replicationStatus.$$ | grep "Yes" | wc -l) -gt 0 ]
#  then
#    setColorSuccess
#    echo -n "STARTED"
#  else
#    if [ $(cat /tmp/replicationStatus.$$ | grep "No" | wc -l) -gt 0 ]
#     then
#       setColorError
#       echo -n "STOPPED"
#     else
#       echo -n "???????"
#    fi
#  fi
#  echo "] MariaDb (Replication)"
fi

echo

#
# Checking remote servers
#

for REMOTE_SERVER in $(cat /var/opt/${SIU_INSTANCE}/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^REMOTE_SERVER")
do
  SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
  >/dev/null 2>&1 ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${SERVER} "oam-show_processes.sh"
done

