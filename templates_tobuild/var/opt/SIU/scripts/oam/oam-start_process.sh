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

SCRIPT=oam-start_process
. /home/ium/.bash_profile
. /var/opt/${SIU_INSTANCE}/scripts/oam/oam-common.sh

function start_session_server
{
  PROCESS=${1}

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c startproc > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -eq 0 ]
  then
    echo "OK: Process ${PROCESS} started"
  else
    if [ $(cat ${TMPLOGFILE_PATH}.$$ | grep "has been started already" | wc -l) -eq 1 ]
    then
      echo "WARNING: Process ${PROCESS} has been started already"
    else
      echo "ERROR: Process ${PROCESS} not started"
    fi
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}

function start_collector
{
  PROCESS=${1}

  /opt/${SIU_INSTANCE}/bin/siucontrol -n ${PROCESS} -c startproc > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -eq 0 ]
  then
    echo "OK: Process ${PROCESS} started"
  else
    if [ $(cat ${TMPLOGFILE_PATH}.$$ | grep "has been started already" | wc -l) -eq 1 ]
    then
      echo "WARNING: Process ${PROCESS} has been started already"
    else
      echo "ERROR: Process ${PROCESS} not started"
    fi
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}

function start_jcs
{
  start_collector "$*"
}

function start_SIU
{
  if [ ${SIU_INSTANCE} = "SIU_MANAGER" ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE} ]
  then
    PATH_SIU=/etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE}
  else
    PATH_SIU=/etc/init.d/${SIU_INSTANCE}
  fi
  ${PATH_SIU} start > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR: ${SIU_INSTANCE} instance not started"
  else
    echo "OK: ${SIU_INSTANCE} instance started"
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
  if [ ${SIU_INSTANCE} = "SIU_MANAGER" ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE} ]
  then
    rm -f /etc/opt/${SIU_INSTANCE}/init.d/${SIU_INSTANCE}.status.ok > /dev/null 2>&1
  fi
}

function start_NRBGUITool
{
  /app/DEG/NRBGUI/deploy.sh start > ${TMPLOGFILE_PATH}.$$ 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR: NRBGUITool not started"
  else
    echo "OK: NRBGUITool started"
  fi
  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
}

function start_MySQL
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
		${PATH_SIU} start_dbs > ${TMPLOGFILE_PATH}.$$ 2>&1
		if [ $? -ne 0 ]
		then
		echo "ERROR: MySQL instance not started"
		else
		echo "OK: MySQL instance started"
		fi
	fi

	if [ -f "$PATH_SIU_APP1" ]
	then
		${PATH_SIU_APP1} start_dbs > ${TMPLOGFILE_PATH}.$$ 2>&1
		if [ $? -ne 0 ]
		then
		echo "ERROR: Application MySQL instance not started"
		else
		echo "OK: Application MySQL instance started"
		fi
	fi
	
	if [ -f "$PATH_SIU_APP2" ]
	then
		${PATH_SIU_APP2} start_dbs > ${TMPLOGFILE_PATH}.$$ 2>&1
		if [ $? -ne 0 ]
		then
		echo "ERROR: Application MySQL instance not started"
		else
		echo "OK: Application MySQL instance started"
		fi
	fi
}

function start_TimesTen
{
  if [ ${SIU_INSTANCE} = "SIU_MANAGER" ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT ]
  then
    PATH_SIU=/etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT
    PATH_TT_APP1_INIT=/etc/init.d/tt_SIU_DEG01_TT
    PATH_TT_APP2_INIT=/etc/init.d/tt_SIU_DEG02_TT
  else
    PATH_SIU=/etc/init.d/tt_${SIU_INSTANCE}_TT
  fi

  if [ -f "$PATH_SIU" ]
   then
     sudo ${PATH_SIU} start > ${TMPLOGFILE_PATH}.$$ 2>&1
   if [ $? -ne 0 ]
   then
    echo "ERROR: TimesTen instance not started"
   else
    echo "OK: TimesTen instance started"
   fi
  fi

  if [ -f "$PATH_TT_APP1_INIT" ]
  then
    sudo ${PATH_TT_APP1_INIT} start > ${TMPLOGFILE_PATH}.$$ 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR: Application TimesTen instance not started"
    else
      echo "OK: Application TimesTen instance started"
    fi
  fi

  if [ -f "$PATH_TT_APP2_INIT" ]
  then
    sudo ${PATH_TT_APP2_INIT} start > ${TMPLOGFILE_PATH}.$$ 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR: Application TimesTen instance not started"
    else
      echo "OK: Application TimesTen instance started"
    fi
  fi

  rm -f ${TMPLOGFILE_PATH}.$$ > /dev/null 2>&1
  if [ ${SIU_INSTANCE} = "SIU_MANAGER" ] && [ -f /etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT ]
  then
    rm -f /etc/opt/${SIU_INSTANCE}/init.d/tt_${SIU_INSTANCE}_TT.status.ok > /dev/null 2>&1
  fi
}

if [ $# -lt 1 ]
then
  echo
  echo "Usage: oam-start_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | IUM | TimesTen | ALL]"
  echo
else
  HOST="localhost"
  while getopts h: OPC
  do
    case $OPC in
    h ) HOST=${OPTARG}
        ;;
    [?] )   echo
            echo "Usage: oam-start_process.sh [-h HOSTNAME] [PROCESS_NAME ... PROCESS_NAME | IUM | TimesTen | ALL]"
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
        start_TimesTen
	start_MySQL
        start_SIU
        if [ ${SIU_INSTANCE} = "SIU_MANAGER" ]
        then
          start_NRBGUITool
        fi
	
		collectorArray=($(grep "Collector" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}' | grep -v "^#"))
		for i in "${collectorArray[@]}"
		do
			:
			start_collector $i
		done

		fileServiceArray=($(grep "FileService" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}' | grep -v "^#"))
		for i in "${fileServiceArray[@]}"
		do
        		:
			start_jcs $i
		done
		
		sessionServerArray=($(grep "SessionServer" ${OAM_DIR}/cfg/oam-processes.cfg | awk '{print $1}' | grep -v "^#"))
                for i in "${sessionServerArray[@]}"
                do
                        :
                        start_session_server $i
                done

      else
        ssh ium@${HOST} ". ./.bash_profile; oam-start_process.sh ALL"
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
                start_collector ${ARG}
                ;;
              SessionServer )
                start_session_server ${ARG}
                ;;
              FileService )
                start_jcs ${ARG}
                ;;
              IUM )
                start_SIU
                ;;
              NRB )
                start_NRBGUITool
                ;;
              DDBB )
                start_MySQL
		;;
	      DDBB )
		start_TimesTen
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
        ssh ium@${HOST} ". ./.bash_profile; oam-start_process.sh ${ARG}"
      fi
    fi
  done
fi
