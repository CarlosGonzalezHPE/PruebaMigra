#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT_NAME=oam-show_processes.sh
export SCRIPT_NAME

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
[#SECTION_BEGIN:MANAGER#]
  echo "Usage: oam-show_processes [-f]"
  echo "       -f: show status of all processes in site, including Manager and Application Servers"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo "Usage: oam-show_processes"
[#SECTION_END#]
  exit 1
}

setColorEmphasized
[#SECTION_BEGIN:MANAGER#]
echo "OAM Tools on Manager '$(hostname)' - Show processes status"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
echo "OAM Tools on Application Server '$(hostname)' - Show processes status"
[#SECTION_END#]
setColorNormal
echo

[#SECTION_BEGIN:MANAGER#]
FULL_MODE=
while getopts f OPC
do
  case ${OPC} in
    f)
      FULL_MODE=true
      ;;
  [?])
    showUsageAndExit
  esac
done
[#SECTION_END#]

[#SECTION_BEGIN:APP_SERVER#]
if [ $# -gt 0 ]
then
  showUsageAndExit
fi
[#SECTION_END#]

[#SECTION_BEGIN:MANAGER#]
setColorEmphasized
echo -n "DB"
setColorNormal
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
echo "] MariaDb (APP Instance)"
echo -n "    ["
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
echo "] MariaDb (MNGR Instance)"
echo
[#SECTION_END#]

setColorEmphasized
echo -n "SIU"
setColorNormal
echo -n " ["
RESULT=$(check_if_already_running "/opt/<%SIU_INSTANCE%>/bin/adminagentserver -daemonize" 1)
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

[#SECTION_BEGIN:MANAGER#]
echo -n "    ["
RESULT=$(check_if_already_running "/opt/<%SIU_INSTANCE%>/bin/configserver -JVMargs /var/opt/<%SIU_INSTANCE%>/ConfigServer/JVMargs.ini" 1)
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
[#SECTION_END#]
echo
setColorEmphasized
echo -n "DEG"
setColorNormal
FIRST=true
cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | sort | while read PROCESS TYPE
do
  case "${TYPE}" in
    "Collector")
      RESULT=$(check_if_already_running "/opt/<%SIU_INSTANCE%>/bin/collector -JVMargs /var/opt/<%SIU_INSTANCE%>/${PROCESS}" 1)
      ;;
    "SessionServer")
      RESULT=$(check_if_already_running "/opt/<%SIU_INSTANCE%>/bin/SIUJava -JVMargs /var/opt/<%SIU_INSTANCE%>/${PROCESS}/JVMargs.ini com.hp.siu.sessionserver.SessionServer" 1)
      ;;
    "FileService")
      RESULT=$(check_if_already_running "/opt/<%SIU_INSTANCE%>/bin/filecollectionserver -JVMargs /var/opt/<%SIU_INSTANCE%>/${PROCESS}/JVMargs.ini" 1)
      ;;
    *)
      continue
      ;;
  esac

  if [ "${FIRST}" = "true" ]
  then
    echo -n " ["
  else
    echo -n "    ["
  fi

  FIRST=false

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

[#SECTION_BEGIN:MANAGER#]
echo -n "    ["
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
[#SECTION_END#]

[#SECTION_BEGIN:MANAGER#]
if [ ! -z ${FULL_MODE} ]
then
  for REMOTE_SERVER in $(cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^REMOTE_SERVER")
  do
    echo

    SERVER=$(echo ${REMOTE_SERVER} | cut -d "=" -f 2)
    2> /dev/null ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${SERVER} ". .bash_profile; oam-show_processes.sh"
  done
fi
[#SECTION_END#]
