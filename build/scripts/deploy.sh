#/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

CFG_FILEPATH=cfg/deploy.cfg

function showUsage()
{
  echo "deploy.sh -h <HOSTNAME> -t <tree> [-c] [-p] [-g]"
}

function setColorSuccess
{
  echo -en "\033[0;32m"
}


function setColorError
{
  echo -en "\033[0;31m"
}


function setColorWarning
{
  echo -en "\033[0;33m"
}


function setColorNormal
{
  echo -en "\033[0;39m"
}

function setColorDebug
{
  echo -en "\033[0;34m"
}

function logInfo
{
  echo "[INF] $@"
}

function logDebug
{
  if [ "${DEBUG}" = "TRUE" ]
  then
    echo -n "["
    setColorDebug
    echo -n "DBG"
    setColorNormal
    echo "] $@"
  fi
}

function logError
{
  echo -n "["
  setColorError
  echo -n "ERR"
  setColorNormal
  echo "] $@"
}

function logWarning
{
  echo -n "["
  setColorWarning
  echo -n "WRN"
  setColorNormal
  echo "] $@"
}


function getConfigParam
{
  typeset local SECTION
  typeset local PARAM
  typeset local SCOPE

  case ${#} in
    2)
      SCOPE=SELF
      ;;
    3)
      SCOPE=${3}
      ;;
    *)
      echo "Usage: getConfigParam <SECTION> <PARAMETER> [<SCOPE>(SELF|COMMON)]"
    exit 1
      ;;
  esac

  SECTION=$1
  PARAM=$2

  FILEPATH=${CFG_FILEPATH}

  awk -F= -v seccion="${SECTION}" -v param="${PARAM}" '
    BEGIN {
      searching = 0;
      sectionFound = 0;
      begin = "[" seccion "]";
      end = "[/" seccion "]";
    }
    {
      if ( substr( $0, 0, length( begin ) ) == begin ) {
        searching = 1;
      }
      else if (( substr( $0, 0, length( end ) ) == end ) && ( searching == 1 )) {
        searching = 0;
        print "";
        if ( sectionFound == 0 ) {
          exit 1;
        }
        else {
          exit 0;
        }
      }
      else if (( searching ) && ( substr( $0, 0, 1 ) != "#" ) && ( $1 == param )) {
        print $2;
        exit 0;
      }
    }' ${FILEPATH}
}

CREATE_DIR=
CHANGE_PERMS=
DEBUG=
HOSTNAME=
TREE=
while getopts "cgh:pt:" OPT
do
  case ${OPT} in
    c)
      CREATE_DIR=TRUE
      ;;
    g)
      DEBUG=TRUE
      ;;
    h)
      HOSTNAME=${OPTARG}
      ;;
    p)
      CHANGE_PERMS=TRUE
      ;;
    t)
      TREE=${OPTARG}
      ;;
    *)
      showUsage
      exit 1
      ;;
  esac
done

logInfo "HOSTNAME = ${HOSTNAME}"
logInfo "TREE = ${TREE}"

if [ -z ${HOSTNAME} ] || [ -z ${TREE} ]
then
  showUsage
  exit 1
fi

if [ "$(echo ${TREE} | cut -c 1)" != "/" ]
then
  TREE="/${TREE}"
  logInfo "Normalized TREE = ${TREE}"
fi

IP_ADDRESS="$(getConfigParam ${HOSTNAME} IP_ADDRESS)"
if [ $? -lt 0 ] || [ -z "${IP_ADDRESS}" ]
then
  logError "Unable to get mandatory parameter 'IP_ADDRESS' in section '${HOSTNAME}'"
  exit 1
fi
logDebug "IP_ADDRESS = ${IP_ADDRESS}"

PORT="$(getConfigParam ${HOSTNAME} PORT)"
if [ $? -lt 0 ] || [ -z "${PORT}" ]
then
  logError "Unable to get mandatory parameter 'PORT' in section '${HOSTNAME}'"
  exit 1
fi
logDebug "PORT = ${PORT}"

SIU_INSTANCE="$(getConfigParam ${HOSTNAME} SIU_INSTANCE)"
if [ $? -lt 0 ] || [ -z "${SIU_INSTANCE}" ]
then
  logError "Unable to get mandatory parameter 'SIU_INSTANCE' in section '${HOSTNAME}'"
  exit 1
fi
logDebug "SIU_INSTANCE = ${SIU_INSTANCE}"

if [ ! -d .work/${HOSTNAME}/built${TREE} ]
then
  logError "Directory '.work/${HOSTNAME}/built${TREE}' does not exist"
  exit 1
fi

echo ".work/${HOSTNAME}/built${TREE}" > /tmp/deploy.${HOSTNAME}.dir_list
find .work/${HOSTNAME}/built${TREE} -type d >> /tmp/deploy.${HOSTNAME}.dir_list

if [ "${CREATE_DIR}" = "TRUE" ]
then
  logDebug "ssh -p ${PORT} -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ium@${IP_ADDRESS} \"echo '#!/bin/bash' > /tmp/sudoaskium$$.sh; echo 'echo hpinvent' >> /tmp/sudoaskium$$.sh; chmod 700 /tmp/sudoaskium$$.sh\""
  ssh -p ${PORT} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${IP_ADDRESS} "echo '#!/bin/bash' > /tmp/sudoaskium$$.sh; echo 'echo hpinvent' >> /tmp/sudoaskium$$.sh; chmod 700 /tmp/sudoaskium$$.sh"

  for DIR_PATH in $(cat /tmp/deploy.${HOSTNAME}.dir_list)
  do
    DEST_DIR="/"$(echo ${DIR_PATH} | cut -d "/" -f 4- | sed -e "s|SIU|${SIU_INSTANCE}|g")
    logInfo "Creating (if needed) directory '${DEST_DIR}'"
    logDebug "ssh -p ${PORT} -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ium@${IP_ADDRESS} \"export SUDO_ASKPASS=/tmp/sudoaskium$$.sh; if [ ! -d ${DEST_DIR} ]; then sudo -A mkdir -p ${DEST_DIR}; sudo -A chown ium:ium ${DEST_DIR}; chmod 755 ${DEST_DIR}; fi\""
    ssh -p ${PORT} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${IP_ADDRESS} "export SUDO_ASKPASS=/tmp/sudoaskium$$.sh; if [ ! -d ${DEST_DIR} ]; then sudo -A mkdir -p ${DEST_DIR}; sudo -A chown ium:ium ${DEST_DIR}; chmod 755 ${DEST_DIR}; fi"
  done
  logDebug "ssh -p ${PORT} -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ium@${IP_ADDRESS} \"rm -f /tmp/sudoaskium$$.sh\""
  ssh -p ${PORT} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${IP_ADDRESS} "rm -f /tmp/sudoaskium$$.sh"
fi

for DIR_PATH in $(cat /tmp/deploy.${HOSTNAME}.dir_list)
do
  DEST_DIR="/"$(echo ${DIR_PATH} | cut -d "/" -f 4- | sed -e "s|SIU|${SIU_INSTANCE}|g")
  logInfo "Deploying files in directory '${DEST_DIR}'"
  logDebug "scp -P ${PORT} ${DIR_PATH}/* ium@${IP_ADDRESS}:${DEST_DIR}"
  2>/dev/null scp -P ${PORT} ${DIR_PATH}/* ium@${IP_ADDRESS}:${DEST_DIR}
  logDebug "scp -P ${PORT} ${DIR_PATH}/.* ium@${IP_ADDRESS}:${DEST_DIR}"
  2>/dev/null scp -P ${PORT} ${DIR_PATH}/.* ium@${IP_ADDRESS}:${DEST_DIR}
done

if [ "${CHANGE_PERMS}" = "TRUE" ]
then
  ACTUAL_TREE=$(echo ${TREE} | sed -e "s|SIU|${SIU_INSTANCE}|g")
  logInfo "Changing file permissions"
  logDebug "ssh -p ${PORT} -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ium@${IP_ADDRESS} \"find /${ACTUAL_TREE} -type f | xargs chmod 644 2>/dev/null\""
  ssh -p ${PORT} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${IP_ADDRESS} "find /${ACTUAL_TREE} -type f | xargs chmod 644 2>/dev/null"
  logDebug "ssh -p ${PORT} -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ium@${IP_ADDRESS} \"find /${ACTUAL_TREE} -type f -name *.sh | xargs chmod 744 2>/dev/null\""
  ssh -p ${PORT} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ium@${IP_ADDRESS} "find /${ACTUAL_TREE} -type f -name *.sh | xargs chmod 744 2>/dev/null"
fi

exit 0
