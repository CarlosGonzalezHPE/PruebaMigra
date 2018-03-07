#!/bin/bash
#-------------------------------------------------------------------------------
#
# Project : HP-DEG
#
# Version : 1.0                                                                 
# Author : HP CMS
#
# Component: oam-start_process.sh
# Description: Script to start DEG processes.
#
#-------------------------------------------------------------------------------

SCRIPT=oam-stop_process
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

function stop_collector
{
  PROCESS=${1}

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c stopproc > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -eq 0 ]
  then
    echo "OK: Process ${PROCESS} stopped"
  else
    if [ $(cat ${TMPLOGFILE_PATH}.$$ | grep "has been stopped already" | wc -l) -eq 1 ]
    then
      echo "WARNING: Process ${PROCESS} has been stopped already"
    else
      echo "ERROR: Process ${PROCESS} not stopped"
    fi
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}

function stop_session_server
{
  stop_collector "$*"
}


function stop_jcs
{
  stop_collector "$*"
}


function stop_SIU
{
  if [ ${SIU_INSTANCE} = "SIU_MANAGER" ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE} ]
  then
    touch /etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE}.status.ok > /dev/null 2>&1
    PATH_SIU=/etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE}
  else
    PATH_SIU=/etc/init.d/${SIU_INSTANCE}
  fi
  ${PATH_SIU} stop > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR: ${SIU_INSTANCE} instance not stopped"
  else
    echo "OK: ${SIU_INSTANCE} instance stopped"
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}


function stop_NRBGUITool
{
  /app/DEG/NRBGUI/deploy.sh stop > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR: NRBGUITool not stopped"
  else
    echo "OK: NRBGUITool stopped"
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}

function stop_MySQL
{
	if [ "${SIU_INSTANCE}" = 'SIU_MANAGER' ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE} ]
	then
		PATH_SIU=/etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE}
	else
		PATH_SIU=/etc/init.d/${SIU_INSTANCE}
		PATH_SIU_APP1=/etc/init.d/SIU_DEG01
		PATH_SIU_APP2=/etc/init.d/SIU_DEG02
	fi

	if [ -f "$PATH_SIU" ]
	then
		${PATH_SIU} stop_dbs > ${TMPLOGFILE_PATH}.$$ 2>&1
		if [ $? -ne 0 ]
		then
		echo "ERROR: MySQL instance not stopped"
		else
		echo "OK: MySQL instance stopped"
		fi
	fi

	if [ -f "$PATH_SIU_APP1" ]
	then
		${PATH_SIU_APP1} stop_dbs > ${TMPLOGFILE_PATH}.$$ 2>&1
		if [ $? -ne 0 ]
		then
		echo "ERROR: Application MySQL instance not stopped"
		else
		echo "OK: Application MySQL instance stopped"
		fi
	fi
	
	if [ -f "$PATH_SIU_APP2" ]
	then
		${PATH_SIU_APP2} stop_dbs > ${TMPLOGFILE_PATH}.$$ 2>&1
		if [ $? -ne 0 ]
		then
		echo "ERROR: Application MySQL instance not stopped"
		else
		echo "OK: Application MySQL instance stopped"
		fi
	fi
}

function stop_TimesTen
{
  if [ ${SIU_INSTANCE} = "SIU_MANAGER" ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT ]
  then
    touch /etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT.status.ok > /dev/null 2>&1
    PATH_SIU=/etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT
    PATH_TT_APP1_INIT=/etc/init.d/tt_SIU_DEG01_TT
    PATH_TT_APP2_INIT=/etc/init.d/tt_SIU_DEG02_TT
  else
    PATH_SIU=/etc/init.d/tt_${SIU_INSTANCE}_TT
  fi

  if [ -f "$PATH_SIU" ]
  then
    sudo ${PATH_SIU} stop > ${TMPLOGFILE_PATH}.$$ 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR: TimesTen instance not stopped"
    else
      echo "OK: TimesTen instance stopped"
    fi
  fi

  if [ -f "$PATH_TT_APP1_INIT" ]
  then
    sudo ${PATH_TT_APP1_INIT} stop > ${TMPLOGFILE_PATH}.$$ 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR: Application TimesTen instance not stopped"
    else
      echo "OK: Application TimesTen instance stopped"
    fi
  fi

  if [ -f "$PATH_TT_APP2_INIT" ]
  then
    sudo ${PATH_TT_APP2_INIT} stop > ${TMPLOGFILE_PATH}.$$ 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR: Application TimesTen instance not stopped"
    else
      echo "OK: Application TimesTen instance stopped"
    fi
  fi

  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}

if [ $# -lt 1 ]
then
  echo
  echo "Usage: oam-stop_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | IUM | TimesTen | ALL]"
  echo
else
  HOST="localhost"
  while getopts h: OPC
  do
    case $OPC in
    h ) HOST=${OPTARG}
        ;;
    [?] )   echo
            echo "Usage: oam-stop_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | IUM | TimesTen | ALL]"
            echo
    esac
  done
  shift $(expr ${OPTIND} - 1)

  for ARG in $*
  do
    if [ ${ARG} = "ALL" ]
    then
      if [ ${HOST} = "localhost" ]
      then
        if [ ${SIU_INSTANCE} = "SIU_MANAGER" ]
        then
          stop_NRBGUITool
        fi
		collectorArray=($(grep "Collector" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}' | grep -v "^#"))
                for i in "${collectorArray[@]}"
                do
                        :
                        stop_collector $i
                done

                fileServiceArray=($(grep "FileService" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}' | grep -v "^#"))
                for i in "${fileServiceArray[@]}"
                do
                        :
                        stop_jcs $i
                done

                sessionServerArray=($(grep "SessionServer" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}' | grep -v "^#"))
                for i in "${sessionServerArray[@]}"
                do
                        :
                        stop_session_server $i
                done
        stop_SIU
        stop_MySQL
	stop_TimesTen

      else
        ssh ium@${HOST} ". ./.bash_profile; oam-stop_process.sh ALL"
      fi
    else
      if [ ${HOST} = "localhost" ]
      then
        NUM_PROCESS=$(grep "^${ARG}" ${OAM_DIR}/cfg/oam-processes.cfg | wc -l)
        if [ ${NUM_PROCESS} -eq 1 ]
        then
          PROCESS=$(grep "^${ARG}" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}')
          if [ ${PROCESS} = ${ARG} ]
          then
            PROCESS_TYPE=$(grep "^${ARG}" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $2}')
            case ${PROCESS_TYPE} in
              Collector )
                stop_collector ${ARG}
                ;;
              SessionServer )
                stop_session_server ${ARG}
                ;;
              FileService )
                stop_jcs ${ARG}
                ;;
              IUM )
                stop_SIU
                ;;
              NRB )
                stop_NRBGUITool
                ;;
              DDBB )
                stop_MySQL
		;;
	      DDBB )
		stop_TimesTen
                ;;
              * )
                echo "WARNING: Process ${ARG} of type ${PROCESS_TYPE} does not exist in server $(hostname)"
                ;;
            esac
          else
            echo "WARNING: Process ${ARG} does not exist in server $(hostname)"
          fi
        else
          echo "WARNING: Process ${ARG} does not exist in server $(hostname)"
        fi
      else
        ssh ium@${HOST} ". ./.bash_profile; oam-stop_process.sh ${ARG}"
      fi
    fi
  done
fi
