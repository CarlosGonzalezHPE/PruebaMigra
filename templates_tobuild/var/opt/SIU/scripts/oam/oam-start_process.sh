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
  echo "Usage: oam-start_process.sh ALL | PROCESS_NAME [... PROCESS_NAME]"
  echo "       oam-start_process.sh -h HOSTANME ALL | PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo "Usage: oam-start_process.sh ALL| PROCESS_NAME [... PROCESS_NAME]"
[#SECTION_END#]
  echo
  exit 1
}


[#SECTION_BEGIN:MANAGER#]
function start_MariaDB
{
  /etc/init.d/<%SIU_INSTANCE%> start_db > /tmp/start_MariaDB.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to start MariaDB"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] MariaDB successfully started"
  fi
  rm -f /tmp/start_MariaDB.$$
}


function start_NRBGUITool
{
  /app/DEG/NRBGUI/deploy.sh start  > /tmp/start_NRBGUITool.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to start process 'NRBGUITool'"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] 'NRBGUITool' successfully started"
  fi

  rm -f /tmp/start_NRBGUITool.$$
}
[#SECTION_END#]


function start_SIU
{
  /etc/init.d/<%SIU_INSTANCE%> start_siu > /tmp/start_SIU.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to start SIU instance '<%SIU_INSTANCE%>'"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] SIU instance '<%SIU_INSTANCE%>' successfully started"
  fi
  rm -f /tmp/start_SIU.$$
}


function start_collector
{
  PROCESS=${1}

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_collector.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/start_collector.$$ | grep "has been started already" | wc -l) -gt 0 ]
    then
      echo -n "["
      setColorWarning
      echo -n "WARNING"
      setColorNormal
      echo "] Collector '${PROCESS}' already started"
    else
      EXIT_CODE=1
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to start Collector '${PROCESS}'"
    fi
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] Collector '${PROCESS}' successfully started"
  fi

  rm -f /tmp/start_collector.$$
}


function start_session_server
{
  PROCESS=${1}

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_session_server.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/start_session_server.$$ | grep "has been started already" | wc -l) -gt 0 ]
    then
      echo -n "["
      setColorWarning
      echo -n "WARNING"
      setColorNormal
      echo "] Session Server '${PROCESS}' already started"
    else
      EXIT_CODE=1
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to start Session Server '${PROCESS}'"
    fi
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] Session Server '${PROCESS}' successfully started"
  fi

  rm -f /tmp/start_session_server.$$
}


function start_fcs
{
  PROCESS=${1}

  /opt/<%SIU_INSTANCE%>/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_fcs.$$ 2>&1
  if [ $? -ne 0 ]
  then
    if [ $(cat /tmp/start_fcs.$$ | grep "has been started already" | wc -l) -gt 0 ]
    then
      echo -n "["
      setColorWarning
      echo -n "WARNING"
      setColorNormal
      echo "] File Collection Service '${PROCESS}' already started"
    else
      EXIT_CODE=1
      echo -n "["
      setColorError
      echo -n "ERROR"
      setColorNormal
      echo "] Unable to start File Collection Service '${PROCESS}'"
    fi
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] File Collection Service '${PROCESS}' successfully started"
  fi

  rm -f /tmp/start_fcs.$$
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
      done
[#SECTION_BEGIN:MANAGER#]
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-start_process.sh ALL"
[#SECTION_END#]
    fi
  else
    if [ ${HOST} = "localhost" ]
    then
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
        ARG_OK=true
      done
[#SECTION_BEGIN:MANAGER#]
    else
      ARG_OK=true
      ssh ium@${HOST} ". ./.bash_profile; oam-start_process.sh ${ARG}"
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
