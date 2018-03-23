#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
[#SECTION_BEGIN:MANAGER#]
  echo "Usage: oam-start_processes.sh ALL | PROCESS_NAME [... PROCESS_NAME]"
  echo "       oam-start_processes.sh -h HOSTANME ALL | PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo "Usage: oam-start_processes.sh ALL| PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
  echo
  exit 1
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

  /etc/init.d/<%SIU_INSTANCE%> start_db > /tmp/start_MariaDB.$$ 2>&1
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
  rm -f /tmp/start_MariaDB.$$
}


function start_NRBGUITool
{
  if [ $# -gt 0 ] && [ "${1}" = "SILENT" ]
  then
    SILENT_MODE=true
  else
    SILENT_MODE=false
  fi

  /app/DEG/NRBGUI/deploy.sh start  > /tmp/start_NRBGUITool.$$ 2>&1
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

  rm -f /tmp/start_NRBGUITool.$$
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

  /etc/init.d/<%SIU_INSTANCE%> start_siu > /tmp/start_SIU.$$ 2>&1
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
  rm -f /tmp/start_SIU.$$
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

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_collector.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/start_collector.$$ | grep "has been started already" | wc -l) -gt 0 ]
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

  rm -f /tmp/start_collector.$$
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

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_session_server.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/start_session_server.$$ | grep "has been started already" | wc -l) -gt 0 ]
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

  rm -f /tmp/start_session_server.$$
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

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_fcs.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/start_fcs.$$ | grep "has been started already" | wc -l) -gt 0 ]
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

  rm -f /tmp/start_fcs.$$
}


EXIT_CODE=0

setColorEmphasized
[#SECTION_BEGIN:MANAGER#]
echo "OAM Tools on Manager '$(hostname)' - Start processes"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
echo "OAM Tools on Application Server '$(hostname)' - Start processes"
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
          *)
            continue
            ;;
        esac
        > /tmp/args_ok.$$
      done
[#SECTION_BEGIN:MANAGER#]
    else
      > /tmp/args_ok.$$
      ssh ium@${HOST} ". ./.bash_profile; oam-start_processes.sh ${ARG}"
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
