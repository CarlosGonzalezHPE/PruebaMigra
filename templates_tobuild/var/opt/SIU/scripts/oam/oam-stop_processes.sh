#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT_NAME=oam-stop_processes.sh
export SCRIPT_NAME

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
[#SECTION_BEGIN:MANAGER#]
  echo "Usage: oam-stop_processes.sh ALL | PROCESS_NAME [... PROCESS_NAME]"
  echo "       oam-stop_processes.sh -h HOSTANME ALL | PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo "Usage: oam-stop_processes.sh ALL| PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
  exit 1
}


[#SECTION_BEGIN:MANAGER#]
function stop_MariaDB
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /etc/init.d/<%SIU_INSTANCE%> stop_db > /var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/stop_MariaDB.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1

    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to stop MariaDB"
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] MariaDB successfully stopped"
    fi
  fi
  rm -f /tmp/stop_MariaDB.$$
}


function stop_NRBGUITool
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /app/DEG/NRBGUI/deploy.sh stop  > /tmp/stop_NRBGUITool.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to stop process 'NRBGUITool'"
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] 'NRBGUITool' successfully stopped"
    fi
  fi

  rm -f /tmp/stop_NRBGUITool.$$
}
[#SECTION_END#]


function stop_SIU
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /etc/init.d/<%SIU_INSTANCE%> stop_siu > /tmp/stop_SIU.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to stop SIU instance '<%SIU_INSTANCE%>'"
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] SIU instance '<%SIU_INSTANCE%>' successfully stopped"
    fi
  fi
  rm -f /tmp/stop_SIU.$$
}


function stop_collector
{
  PROCESS=${1}
  if [ $# -gt 1 ] && [ "${2}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_collector.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/stop_collector.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
    then
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorWarning
        echo -n "WARNING"
        setColorNormal
        echo "] Process '${PROCESS}' already stopped"
      fi
    else
      EXIT_CODE=1
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorError
        echo -n "ERROR"
        setColorNormal
        echo "] Unable to stop Process '${PROCESS}'"
      fi
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] Process '${PROCESS}' successfully stopped"
    fi
  fi

  rm -f /tmp/stop_collector.$$
}


function stop_session_server
{
  PROCESS=${1}
  if [ $# -gt 1 ] && [ "${2}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_session_server.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/stop_session_server.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
    then
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorWarning
        echo -n "WARNING"
        setColorNormal
        echo "] Process '${PROCESS}' already stopped"
      fi
    else
      EXIT_CODE=1
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorError
        echo -n "ERROR"
        setColorNormal
        echo "] Unable to stop Process '${PROCESS}'"
      fi
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] Process '${PROCESS}' successfully stopped"
    fi
  fi

  rm -f /tmp/stop_session_server.$$
}


function stop_fcs
{
  PROCESS=${1}
  if [ $# -gt 1 ] && [ "${2}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_fcs.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/stop_fcs.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
    then
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorWarning
        echo -n "WARNING"
        setColorNormal
        echo "] File Collection Service '${PROCESS}' already stopped"
      fi
    else
      EXIT_CODE=1
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorError
        echo -n "ERROR"
        setColorNormal
        echo "] Unable to stop File Collection Service '${PROCESS}'"
      fi
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] File Collection Service '${PROCESS}' successfully stopped"
    fi
  fi

  rm -f /tmp/stop_fcs.$$
}


EXIT_CODE=0

setColorEmphasized
[#SECTION_BEGIN:MANAGER#]
echo "OAM Tools on Manager '$(hostname)' - stop processes"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
echo "OAM Tools on Application Server '$(hostname)' - stop processes"
[#SECTION_END#]
setColorNormal
echo

if [ $# -lt 1 ]
then
  showUsageAndExit
  exit 1
fi

HOST="localhost"
while getopts h: OPC
do
  case ${OPC} in
    h)
[#SECTION_BEGIN:MANAGER#]
      HOST=${OPTARG}
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
      showUsageAndExit
[#SECTION_END#]
      ;;
    [?])
      showUsageAndExit
      ;;
  esac
done

shift $(expr ${OPTIND} - 1)

for ARG in $*
do
  if [ "${ARG}" = "ALL" ]
  then
    > /tmp/args_ok.$$

    if [ "${HOST}" = "localhost" ]
    then
      stop_SIU
[#SECTION_BEGIN:MANAGER#]
      stop_MariaDB
[#SECTION_END#]
[#SECTION_BEGIN:MANAGER#]
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-stop_processes.sh ALL"
[#SECTION_END#]
    fi
  else
    if [ ${HOST} = "localhost" ]
    then
      cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^${ARG}" | while read PROCESS TYPE
      do
        case "${TYPE}" in
          "Collector")
            stop_collector ${PROCESS}
            ;;
          "SessionServer")
            stop_session_server ${PROCESS}
            ;;
          "FileService")
            stop_fcs ${PROCESS}
            ;;
          *)
            continue
            ;;
        esac
        > /tmp/args_ok.$$
      done
[#SECTION_BEGIN:MANAGER#]
    else
      > /tmp/args_ok.$$
      ssh ium@${HOST} ". ./.bash_profile; oam-stop_processes.sh ${ARG}"
[#SECTION_END#]
    fi
  fi
done

if [ ! -f /tmp/args_ok.$$ ]
then
  showUsageAndExit
else
  rm -f /tmp/args_ok.$$
fi

exit ${EXIT_CODE}
