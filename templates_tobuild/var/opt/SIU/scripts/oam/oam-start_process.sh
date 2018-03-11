#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT=oam-start_process
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

EXIT_CODE=0

function showUsage
{
  if [ "${SIU_INSTANCE}" = "SIU_MANAGER" ]
  then
    echo "Usage: oam-start_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | SIU | MariaDB | ALL]"
  else
    echo "Usage: oam-start_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | ALL]"
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
      start_MariaDB
      start_SIU
      start_NRBGUITool

      cat /var/opt/${SIU_INSTANCE}/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | sort | while read PROCESS TYPE
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
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-start_process.sh ALL"
    fi
  else
    if [ ${HOST} = "localhost" ]
    then
      case "${ARG}" in
        "SIU")
          start_SIU
          ;;
        "MariaDB")
          start_MariaDB
          ;;
        "NRBGUITool")
          start_NRBGUITool
          ;;
        *)
        cat /var/opt/${SIU_INSTANCE}/scripts/oam/cfg/oam-processes.cfg | grep -v "^#" | grep "^${ARG}" | while read PROCESS TYPE
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
      esac
    else
      ssh ium@${HOST} ". ./.bash_profile; oam-start_process.sh ${ARG}"
    fi
  fi
done

exit ${EXIT_CODE}
