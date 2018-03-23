#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT=oam-restart_process
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

EXIT_CODE=0

function showUsage
{
  if [ "${SIU_INSTANCE}" = "SIU_MANAGER" ]
  then
    echo "Usage: oam-restart_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | SIU | MariaDB | ALL]"
  else
    echo "Usage: oam-restart_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | ALL]"
  fi
  echo
}


function start_SIU
{
  /etc/init.d/${SIU_INSTANCE} start_siu > /tmp/start_SIU.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to start SIU instance '${SIU_INSTANCE}'"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] SIU instance '${SIU_INSTANCE}' successfully started"
  fi
  rm -f /tmp/start_SIU.$$
}


function start_MariaDB
{
  if [ "${SIU_INSTANCE}" = "SIU_MANAGER" ]
  then
    /etc/init.d/${SIU_INSTANCE} start_db > /tmp/start_MariaDB.$$ 2>&1
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
  fi
}


function start_collector
{
  PROCESS=${1}

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_collector.$$ 2>&1
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

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_session_server.$$ 2>&1
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

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c startproc > /tmp/start_fcs.$$ 2>&1
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


function start_NRBGUITool
{
  if [ "${SIU_INSTANCE}" = "SIU_MANAGER" ]
  then
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
  fi
}


function stop_SIU
{
  /etc/init.d/${SIU_INSTANCE} stop_siu > /tmp/stop_SIU.$$ 2>&1
  if [ $? -ne 0 ]
  then
    EXIT_CODE=1
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to stop SIU instance '${SIU_INSTANCE}'"
  else
    echo -n "["
    setColorSuccess
    echo -n "OK"
    setColorNormal
    echo "] SIU instance '${SIU_INSTANCE}' successfully stopped"
  fi
  rm -f /tmp/stop_SIU.$$
}


function stop_MariaDB
{
  if [ "${SIU_INSTANCE}" = "SIU_MANAGER" ]
  then
    /etc/init.d/${SIU_INSTANCE} stop_db > /tmp/stop_MariaDB.$$ 2>&1
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
  fi
}


function stop_collector
{
  PROCESS=${1}

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_collector.$$ 2>&1
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

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_session_server.$$ 2>&1
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

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c stopproc > /tmp/stop_fcs.$$ 2>&1
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


function stop_NRBGUITool
{
  if [ "${SIU_INSTANCE}" = "SIU_MANAGER" ]
  then
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
  fi
}


if [ $# -lt 1 ]
then
  showUsage
  exit 1
fi

HOST="localhost"
while getopts h: OPC
do
  case ${OPC} in
    h)
      HOST=${OPTARG}
      ;;
  [?])
    showUsage
    exit 1
  esac
done

shift $(expr ${OPTIND} - 1)

for ARG in $*
do
  if [ "${ARG}" = "ALL" ]
  then
    if [ "${HOST}" = "localhost" ]
    then
      stop_NRBGUITool
      stop_SIU
      stop_MariaDB
      start_MariaDB
      start_SIU
      start_NRBGUITool

      cat /var/opt/${SIU_INSTANCE}/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | sort | while read PROCESS TYPE
      do
        case "${TYPE}" in
          "Collector")
            stop_collector ${PROCESS}
            start_collector ${PROCESS}
            ;;
          "SessionServer")
            stop_session_server ${PROCESS}
            start_session_server ${PROCESS}
            ;;
          "FileService")
            stop_fcs ${PROCESS}
            start_fcs ${PROCESS}
            ;;
          *)
            continue
            ;;
        esac
      done
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-restart_process.sh ALL"
    fi
  else
    if [ ${HOST} = "localhost" ]
    then
      case "${ARG}" in
        "SIU")
          stop_SIU
          start_SIU
          ;;
        "MariaDB")
          stop_MariaDb
          start_MariaDB
          ;;
        "NRBGUITool")
          stop_NRBGUITool
          start_NRBGUITool
          ;;
        *)
        cat /var/opt/${SIU_INSTANCE}/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^${ARG}" | while read PROCESS TYPE
        do
          case "${TYPE}" in
            "Collector")
              stop_collector ${PROCESS}
              start_collector ${PROCESS}
              ;;
            "SessionServer")
              stop_session_server ${PROCESS}
              start_session_server ${PROCESS}
              ;;
            "FileService")
              stop_fcs ${PROCESS}
              start_fcs ${PROCESS}
              ;;
            *)
              continue
              ;;
          esac
        done
      esac
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-restart_process.sh ${ARG}"
    fi
  fi
done

exit ${EXIT_CODE}

