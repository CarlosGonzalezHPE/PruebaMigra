#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT_NAME=oam-start_processes.sh
export SCRIPT_NAME

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
[#SECTION_BEGIN:MANAGER#]
  echo -n "Usage: oam-start_processes.sh ["
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
  echo -n "Usage: oam-start_processes.sh ["
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
  echo " : name of DEG process to be started"
  exitAndUnlock ${EXIT_CODE}
}


[#SECTION_BEGIN:MANAGER#]
function start_MariaDB
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /etc/opt/<%SIU_INSTANCE%>/init.d/<%SIU_INSTANCE%> start_db > ${TMP_DIR}/start_MariaDB.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1

    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to start MariaDB"
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] MariaDB successfully started"
    fi
  fi
  rm -f ${TMP_DIR}/start_MariaDB.$$
}


function start_NRBGUITool
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /app/DEG/NRBGUI/deploy.sh start  > ${TMP_DIR}/start_NRBGUITool.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to start process 'NRBGUITool'"
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] 'NRBGUITool' successfully started"
    fi
  fi

  rm -f ${TMP_DIR}/start_NRBGUITool.$$
}
[#SECTION_END#]


function start_SIU
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

[#SECTION_BEGIN:MANAGER#]
  /etc/opt/<%SIU_INSTANCE%>/init.d/<%SIU_INSTANCE%> start_siu > ${TMP_DIR}/start_SIU.$$ 2>&1
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  /etc/init.d/<%SIU_INSTANCE%> start_siu > ${TMP_DIR}/start_SIU.$$ 2>&1
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
      echo "] Unable to start SIU instance '<%SIU_INSTANCE%>'"
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] SIU instance '<%SIU_INSTANCE%>' successfully started"
    fi
  fi
  rm -f ${TMP_DIR}/start_SIU.$$
}


function start_collector
{
  PROCESS=${1}
  if [ $# -gt 1 ] && [ "${2}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > ${TMP_DIR}/start_collector.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat ${TMP_DIR}/start_collector.$$ | grep "has been started already" | wc -l) -gt 0 ]
    then
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorWarning
        echo -n "WARNING"
        setColorNormal
        echo "] Process '${PROCESS}' already started"
      fi
    else
      EXIT_CODE=1
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorError
        echo -n "ERROR"
        setColorNormal
        echo "] Unable to start Process '${PROCESS}'"
      fi
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] Process '${PROCESS}' successfully started"
    fi
  fi

  rm -f ${TMP_DIR}/start_collector.$$
}


function start_session_server
{
  PROCESS=${1}
  if [ $# -gt 1 ] && [ "${2}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > ${TMP_DIR}/start_session_server.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat ${TMP_DIR}/start_session_server.$$ | grep "has been started already" | wc -l) -gt 0 ]
    then
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorWarning
        echo -n "WARNING"
        setColorNormal
        echo "] Process '${PROCESS}' already started"
      fi
    else
      EXIT_CODE=1
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorError
        echo -n "ERROR"
        setColorNormal
        echo "] Unable to start Process '${PROCESS}'"
      fi
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] Process '${PROCESS}' successfully started"
    fi
  fi

  rm -f ${TMP_DIR}/start_session_server.$$
}


function start_fcs
{
  PROCESS=${1}
  if [ $# -gt 1 ] && [ "${2}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > ${TMP_DIR}/start_fcs.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat ${TMP_DIR}/start_fcs.$$ | grep "has been started already" | wc -l) -gt 0 ]
    then
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorWarning
        echo -n "WARNING"
        setColorNormal
        echo "] File Collection Service '${PROCESS}' already started"
      fi
    else
      EXIT_CODE=1
      if [ "${SILENT_MODE}" = "false" ]
      then
        echo -n "["
        setColorError
        echo -n "ERROR"
        setColorNormal
        echo "] Unable to start File Collection Service '${PROCESS}'"
      fi
    fi
  else
    if [ "${SILENT_MODE}" = "false" ]
    then
      echo -n "["
      setColorSuccess
      echo -n "OK"
      setColorNormal
      echo "] File Collection Service '${PROCESS}' successfully started"
    fi
  fi

  rm -f ${TMP_DIR}/start_fcs.$$
}


#
# Main
#

setColorTitle
[#SECTION_BEGIN:MANAGER#]
echo "OAM Tools on Manager '$(hostname)' - Start processes"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
echo "OAM Tools on Application Server '$(hostname)' - Start processes"
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
[#SECTION_BEGIN:MANAGER#]
      start_MariaDB
[#SECTION_END#]
      start_SIU
[#SECTION_BEGIN:MANAGER#]
      start_NRBGUITool
[#SECTION_END#]

      cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | sort | while read PROCESS TYPE
      do
        case "${TYPE}" in
          "Collector")
            start_collector ${PROCESS} SILENT
            ;;
          "SessionServer")
            start_session_server ${PROCESS} SILENT
            ;;
          "FileService")
            start_fcs ${PROCESS} SILENT
            ;;
          *)
            continue
            ;;
        esac
      done
[#SECTION_BEGIN:MANAGER#]
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-start_processes.sh ALL"
[#SECTION_END#]
    fi
  else
    if [ ${HOST} = "localhost" ]
    then
      start_SIU SILENT

      cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^${ARG}" | while read PROCESS TYPE
      do
        case "${TYPE}" in
          "Collector")
            start_collector ${PROCESS}
            ;;
          "SessionServer")
            start_session_server ${PROCESS}
            ;;
          "FileService")
            start_fcs ${PROCESS}
            ;;
[#SECTION_BEGIN:MANAGER#]
          "NRBGUITool")
            start_NRBGUITool
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
      ssh ium@${HOST} ". ./.bash_profile; oam-start_processes.sh ${ARG}"
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
