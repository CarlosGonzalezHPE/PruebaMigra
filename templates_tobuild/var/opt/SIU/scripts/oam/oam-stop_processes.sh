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
  echo -n "Usage: oam-stop_processes.sh ["
  setColorArgs
  echo -n "-h "
  setColorArgs2
  echo -n "<host_name>"
  setColorNormal
  echo -n "] "
  setColorArgs
  echo -n "ALL"
  setColorNormal
  echo -n "|"
  setColorArgs2
  echo -n "<process_name>"
  setColorNormal
  echo -n " [... "
  setColorArgs2
  echo -n "<process_name>"
  setColorNormal
  echo "]"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo -n "Usage: oam-stop_processes.sh ["
  setColorArgs
  echo -n "ALL"
  setColorNormal
  echo -n "|"
  setColorArgs2
  echo -n "<process_name>"
  setColorNormal
  echo -n " [... "
  setColorArgs2
  echo -n "<process_name>"
  setColorNormal
  echo "]"
[#SECTION_END#]
  echo
  echo "Arguments:"
[#SECTION_BEGIN:MANAGER#]
  setColorArgs2
  echo -n "  <host_name>"
  setColorNormal
  ALLOWED_REMOTE_HOSTS=
  for REMOTE_SERVER in $(cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^REMOTE_SERVER" | cut -d "=" -f 2)
  do
    ALLOWED_REMOTE_HOSTS=${ALLOWED_REMOTE_HOSTS}" '"${REMOTE_SERVER}"'"
  done
  echo "    : name of host where the command is going to be executed"
  echo "                   allowed hosts are:${ALLOWED_REMOTE_HOSTS}"
[#SECTION_END#]
  setColorArgs2
  echo -n "  <process_name>"
  setColorNormal
  echo " : name of DEG process to be stopped"
  exitAndUnlock ${EXIT_CODE}
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

  /etc/opt/<%SIU_INSTANCE%>/init.d/<%SIU_INSTANCE%> stop_db > ${TMP_DIR}/stop_MariaDB.$$ 2>&1
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
  rm -f ${TMP_DIR}/stop_MariaDB.$$
}


function stop_NRBGUITool
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /app/DEG/NRBGUI/deploy.sh stop  > ${TMP_DIR}/stop_NRBGUITool.$$ 2>&1
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

  rm -f ${TMP_DIR}/stop_NRBGUITool.$$
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

[#SECTION_BEGIN:MANAGER#]
  /etc/opt/<%SIU_INSTANCE%>/init.d/<%SIU_INSTANCE%> stop_siu > ${TMP_DIR}/start_SIU.$$ 2>&1
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  /etc/init.d/<%SIU_INSTANCE%> stop_siu > ${TMP_DIR}/start_SIU.$$ 2>&1
[#SECTION_END#]
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
  rm -f ${TMP_DIR}/stop_SIU.$$
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

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > ${TMP_DIR}/stop_collector.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat ${TMP_DIR}/stop_collector.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
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

  rm -f ${TMP_DIR}/stop_collector.$$
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

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > ${TMP_DIR}/stop_session_server.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat ${TMP_DIR}/stop_session_server.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
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

  rm -f ${TMP_DIR}/stop_session_server.$$
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

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > ${TMP_DIR}/stop_fcs.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat ${TMP_DIR}/stop_fcs.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
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

  rm -f ${TMP_DIR}/stop_fcs.$$
}


#
# Main
#

setColorTitle
[#SECTION_BEGIN:MANAGER#]
echo "OAM Tools on Manager '$(hostname)' - stop processes"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
echo "OAM Tools on Application Server '$(hostname)' - stop processes"
[#SECTION_END#]
setColorNormal
echo

lockExec

EXIT_CODE=0
HOST="localhost"

while 2>/dev/null getopts h: OPC
do
  case ${OPC} in
[#SECTION_BEGIN:MANAGER#]
    h)
      HOST=${OPTARG}
      ;;
[#SECTION_END#]
    *)
      showUsageAndExit
      ;;
  esac
done

shift $(expr ${OPTIND} - 1)

for ARG in $*
do
  if [ "${ARG}" = "ALL" ]
  then
    > ${TMP_DIR}/args_ok.$$

    if [ "${HOST}" = "localhost" ]
    then
      stop_SIU
[#SECTION_BEGIN:MANAGER#]
      stop_MariaDB
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
[#SECTION_BEGIN:MANAGER#]
          "NRBGUITool")
            stop_NRBGUITool
            ;;
[#SECTION_END#]
          *)
            continue
            ;;
        esac
        > ${TMP_DIR}/args_ok.$$
      done
[#SECTION_BEGIN:MANAGER#]
    else
      if [ $(cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^REMOTE_SERVER" | cut -d "=" -f 2 | grep "^${HOST}$" | wc -l) -lt 1 ]
      then
        EXIT_CODE=1
        showUsageAndExit
      fi
      > ${TMP_DIR}/args_ok.$$
      ssh ium@${HOST} ". ./.bash_profile; oam-stop_processes.sh ${ARG}"
[#SECTION_END#]
    fi
  fi
done

if [ ! -f ${TMP_DIR}/args_ok.$$ ]
then
  showUsageAndExit
else
  rm -f ${TMP_DIR}/args_ok.$$
fi

exitAndUnlock ${EXIT_CODE}
