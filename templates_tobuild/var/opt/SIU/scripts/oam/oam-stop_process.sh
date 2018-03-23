#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExitAndExit
{
  echo
[#SECTION_BEGIN:MANAGER#]
  echo "Usage: oam-stop_process.sh ALL | PROCESS_NAME [... PROCESS_NAME]"
  echo "       oam-stop_process.sh -h HOSTANME ALL | PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo "Usage: oam-stop_process.sh ALL| PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
  echo
  exit 1
}


[#SECTION_BEGIN:MANAGER#]
function stop_MariaDB
{
  /etc/init.d/<%SIU_INSTANCE%> stop_db > /tmp/stop_MariaDB.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to stop MariaDB"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] MariaDB successfully stopped"
  fi
  rm -f /tmp/stop_MariaDB.$$
}


function stop_NRBGUITool
{
  /app/DEG/NRBGUI/deploy.sh stop  > /tmp/stop_NRBGUITool.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to stop process 'NRBGUITool'"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] 'NRBGUITool' successfully stopped"
  fi

  rm -f /tmp/stop_NRBGUITool.$$
}
[#SECTION_END#]


function stop_SIU
{
  /etc/init.d/<%SIU_INSTANCE%> stop_siu > /tmp/stop_SIU.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to stop SIU instance '<%SIU_INSTANCE%>'"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] SIU instance '<%SIU_INSTANCE%>' successfully stopped"
  fi
  rm -f /tmp/stop_SIU.$$
}


function stop_collector
{
  PROCESS=${1}

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_collector.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/stop_collector.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
    then
      echo -n "["
      setColorWarning
      echo -n "WARNING"
      setColorNormal
      echo "] Collector '${PROCESS}' already stopped"
    else
      EXIT_CODE=1
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to stop Collector '${PROCESS}'"
    fi
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] Collector '${PROCESS}' successfully stopped"
  fi

  rm -f /tmp/stop_collector.$$
}


function stop_session_server
{
  PROCESS=${1}

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_session_server.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/stop_session_server.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
    then
      echo -n "["
      setColorWarning
      echo -n "WARNING"
      setColorNormal
      echo "] Session Server '${PROCESS}' already stopped"
    else
      EXIT_CODE=1
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to stop Session Server '${PROCESS}'"
    fi
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] Session Server '${PROCESS}' successfully stopped"
  fi

  rm -f /tmp/stop_session_server.$$
}


function stop_fcs
{
  PROCESS=${1}

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_fcs.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/stop_fcs.$$ | grep "has been stopped already" | wc -l) -gt 0 ]
    then
      echo -n "["
      setColorWarning
      echo -n "WARNING"
      setColorNormal
      echo "] File Collection Service '${PROCESS}' already stopped"
    else
      EXIT_CODE=1
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to stop File Collection Service '${PROCESS}'"
    fi
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] File Collection Service '${PROCESS}' successfully stopped"
  fi

  rm -f /tmp/stop_fcs.$$
}


EXIT_CODE=0
ARG_OK=false

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
  esac
done

shift $(expr ${OPTIND} - 1)

for ARG in $*
do
  if [ "${ARG}" = "ALL" ]
  then
    ARG_OK=true

    if [ "${HOST}" = "localhost" ]
    then
[#SECTION_BEGIN:MANAGER#]
      stop_NRBGUITool
[#SECTION_END#]
      stop_SIU
[#SECTION_BEGIN:MANAGER#]
      stop_MariaDB
[#SECTION_END#]

      cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | sort | while read PROCESS TYPE
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
      done
[#SECTION_BEGIN:MANAGER#]
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-stop_process.sh ALL"
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
        ARG_OK=true
      done
[#SECTION_BEGIN:MANAGER#]
    else
      ARG_OK=true
      ssh ium@${HOST} ". ./.bash_profile; oam-stop_process.sh ${ARG}"
[#SECTION_END#]
    fi
  fi
done

if [ "${ARG_OK}" = "false"]
then
  showUsageAndExitAndExit
fi

echo

exit ${EXIT_CODE}
