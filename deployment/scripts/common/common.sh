#!/bin/ksh
#-------------------------------------------------------------------------------
# Orange Spain DEG
#
# HPE CMS Iberia, 2017
#-------------------------------------------------------------------------------
# Descripcion: Script comun
#-------------------------------------------------------------------------------

#
# Variables
#

MYSQL_PATH=/usr/bin/mysql
export MYSQL_PATH

# Default log file path
LOG_FILEPATH=/tmp/scripts.log
export LOG_FILEPATH

SITE_INDEX=00
export SITE_INDEX

#
# Functions
#

function logInfo
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")
  echo "${DATE} INF --- ${1}" >> ${LOG_FILEPATH}
}


function logError
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")
  echo "${DATE} ERR --- ${1}" >> ${LOG_FILEPATH}
}


function logWarning
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")
  echo "${DATE} WRN --- ${1}" >> ${LOG_FILEPATH}
}


function logDebug
{
  typeset local DATE=$(date +"%Y/%m/%d %H:%M:%S")

  if [ "${LOG_LEVEL}" = "DEBUG" ]
  then
    echo "${DATE} DBG --- ${1}" >> ${LOG_FILEPATH}
  fi
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
      logError "Numero de argumentos incorrecto. Uso: getConfigParam <SECTION> <PARAMETER> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  SECTION=$1
  PARAM=$2

  case "${SCOPE}" in
    "SELF")
      if [ -s ${OVERRIDE_CFG_FILEPATH} ]
      then
        FILEPATH=${OVERRIDE_CFG_FILEPATH}
      else
        FILEPATH=${CFG_FILEPATH}
      fi
      ;;
    *)
      logError "Valor '${AMBITO}' incorrecto para el campo 'SCOPE'. Uso: getConfigParam <SECTION> <PARAMETER> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  logDebug "Obteniendo parametro '${PARAM}' de la seccion de configuracion '${SECTION}' en el fichero '${FILEPATH}'"

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
        print ""; # No se ha encontrado la cadena
        if ( sectionFound == 0 ) {
          exit 1;
        }
        else {
          exit 0;
        }
      }
      else if (( searching ) && ( substr( $0, 0, 1 ) != "#" ) && ( $1 == param )) {
        print $2; # Valor asociado a la variable de configuracion
        exit 0;  # Nos paramos en el primer valor encontrado
      }
    } ' ${FILEPATH}
}


function getConfigSection
{
  typeset local SECTION
  typeset local SCOPE
  typeset local FILEPATH

  case ${#} in
    1)
      SECTION=$1
      SCOPE=SELF
      ;;
    2)
      SECTION=$1
      SCOPE=${2}
      ;;
    *)
      logError "Numero de argumentos incorrecto. Uso: getConfigSeccion <SECTION> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  case "${SCOPE}" in
    "SELF")
      if [ -s ${OVERRIDE_CFG_FILEPATH} ]
      then
        FILEPATH=${OVERRIDE_CFG_FILEPATH}
      else
        FILEPATH=${CFG_FILEPATH}
      fi
      ;;
    *)
      logError "Valor '${AMBITO}' incorrecto para el campo 'SCOPE'. Uso: getConfigSeccion <SECTION> [<SCOPE>(SELF|COMMON)]"
      return 1
      ;;
  esac

  logDebug "Obteniendo seccion de configuracion '${SECTION}' del fichero '${FILEPATH}"

  awk -v seccion="${SECTION}" '
    BEGIN {
      searching = 0;
      sectionFound = 0
      begin = "[" seccion "]";
      end = "[/" seccion "]";
    }
    {
      if ( substr( $0, 0, length( begin ) ) == begin ) {
        searching = 1;
        sectionFound = 1;
      }
      else if (( substr( $0, 0, length( end ) ) == end ) && ( searching == 1 )) {
        searching = 0;
        if ( sectionFound == 0 ) {
          exit 1;
        }
        else {
          exit 0;
        }
      }
      else if (( searching ) && ( substr( $0, 0, 1 ) != "#" ) && ( length($0) > 0 )) {
        print $0;
      }
    }' ${FILEPATH}

    return $?
}


function exitIfNotEnabled
{
  typeset local ENABLED=$(getConfigParam GENERAL ENABLED)
  if [ ${?} -ne 0 ] || [ "${ENABLED}" = "" ]
  then
    logWarning "No se ha podido obtener el parametro 'ENABLED' de la seccion de configuracion 'GENERAL'"
    endOfExecution 1
  fi

  if [ "${ENABLED}" != "TRUE" ]
  then
    logWarning "El script '${SCRIPT_NAME}' no esta activado"
    endOfExecution
  fi

  logDebug "El script '${SCRIPT_NAME}' esta activado"
}


function exitIfExecutionConflict
{
  typeset local CONCURRENT_EXECUTIONS_ALLOWED=$(getConfigParam GENERAL CONCURRENT_EXECUTIONS_ALLOWED)
  if [ ${?} -eq 0 ] && [ "${CONCURRENT_EXECUTIONS_ALLOWED}" = "TRUE" ]
  then
    logInfo "Ejecuciones concurrentes permitidas"
    return
  fi

  if [ -f ${CONTROL_FILEPATH} ]
  then
    # ID = PID + PPID + COMANDO
    AUX_PID=$(cat ${CONTROL_FILEPATH} | cut -d " " -f 1)
    AUX_PPID=$(cat ${CONTROL_FILEPATH} | cut -d " " -f 2)
    AUX_COMMAND=$(cat ${CONTROL_FILEPATH} | cut -d " " -f 3-)

    ID_EN_EJECUCION=$(ps -ef | awk '{ $1=$4=$5=$6=$7=""; print $0; }' | sed 's/^ *//g' | sed 's/  */ /g' | grep "^${AUX_PID} ${AUX_PPID} ${AUX_COMMAND}")
    if [ "${ID_EN_EJECUCION}" != "" ]
    then
      logWarning "La ultima ejecucion del script '${SCRIPT_NAME}' no ha finalizado y no se permiten ejecuciones concurrentes"
      endOfExecution -2
    fi
  fi

  logDebug "El fichero de control '${CONTROL_FILEPATH}' ha sido comprobado. No hay ejecucion en curso"

  # ID = PID + PPID + COMANDO
  ID=$(ps -p ${$} -f | tail -n 1 | awk '{ $1=$4=$5=$6=$7=""; print $0; }' | sed 's/^ *//g' | sed 's/  */ /g')
  echo "${ID}" > ${CONTROL_FILEPATH}
  if [ $? -ne 0 ]
  then
    logError "No se ha podido crear el fichero '${CONTROL_FILEPATH}'"
    endOfExecution 1
  fi

  logDebug "El fichero de control '${CONTROL_FILEPATH}' ha sido creado"
}


function deleteControlFile
{
  rm -f ${CONTROL_FILEPATH}
}


function beginingOfExecution
{
  SCRIPT_NAME=$(basename ${SCRIPT_BASEDIR})
  export SCRIPT_NAME

  if [ -z ${RUN_LABEL} ]
  then
    RUN_DIR=${SCRIPT_BASEDIR}
    export RUN_DIR
  else
    RUN_DIR=${SCRIPT_BASEDIR}/run/${RUN_LABEL}
    export RUN_DIR
  fi

  LOG_DIR=${RUN_DIR}/log
  export LOG_DIR

  TMP_DIR=${RUN_DIR}/tmp
  export TMP_DIR

  CTRL_DIR=${RUN_DIR}/ctrl
  export CTRL_DIR

  for DIR in ${LOG_DIR} ${TMP_DIR} ${CTRL_DIR}
  do
    mkdir -p ${DIR}

    >/dev/null 2>&1 cd ${DIR}
    if [ $? -ne 0 ]
    then
      logError "Unable to access to directory '${DIR}'"
      >/dev/null 2>&1 cd -
      endOfExecution 1
    fi
  done

  CONTROL_FILEPATH=${CTRL_DIR}/current_exec
  export CONTROL_FILEPATH

  LOG_FILEPATH=${LOG_DIR}/${SCRIPT_NAME}-$(date "+%Y%m%d").log
  export LOG_FILEPATH

  logInfo "Inicio de ejecucion"

  CFG_FILEPATH=${SCRIPT_BASEDIR}/cfg/${SCRIPT_NAME}.cfg
  if [ ! -f ${CFG_FILEPATH} ]
  then
    logError "El fichero '${CFG_FILEPATH}' no existe"
    endOfExecution 1
  fi
  export CFG_FILEPATH

  OVERRIDE_CFG_FILEPATH=${SCRIPT_BASEDIR}/ctrl/${SCRIPT_NAME}.cfg
  export OVERRIDE_CFG_FILEPATH

  LOG_LEVEL=$(getConfigParam GENERAL LOG_LEVEL)
  if [ ${?} -ne 0 ] || [ "${LOG_LEVEL}" = "" ]
  then
    logWarning "No se ha podido obtener el parametro 'LOG_LEVEL' de la seccion de configuracion 'GENERAL'"
    LOG_LEVEL=INFO
  fi
  export LOG_LEVEL

  logInfo "El nivel de log se establece a '${LOG_LEVEL}'"

  exitIfNotEnabled

  exitIfExecutionConflict

  if [ "${LOGLEVEL}" == "DEBUG" ]
  then
   COPY_NAME=tmp.debug.$(date +"%Y%m%d%H%M%S")
   mkdir -p ${SCRIPT_BASEDIR}/${COPY_NAME}
   mv ${TMP_DIR}/* ${SCRIPT_BASEDIR}/${COPY_NAME}
   if [ $? -ne 0 ]
   then
     logError "Ha fallado el comando 'mv ${TMP_DIR}/* ${SCRIPT_BASEDIR}/${COPY_NAME}'"
   else
     cd ${SCRIPT_BASEDIR}
     if [ $? -ne 0 ]
     then
       logError "No se ha podido acceder al directorio '${RUN_DIR}'"
     else

       if [ $? -ne 0 ]
       then
         logError "Ha fallado el comando 'tar cvf ${COPY_NAME}.tar ${COPY_NAME}'"
       else
         rm -fr ${COPY_NAME}

         gzip ${COPY_NAME}.tar
         if [ $? -ne 0 ]
         then
           logError "Ha fallado el comando 'gzip ${COPY_NAME}.tar'"
         fi
       fi
       cd -
     fi
   fi
  fi

  rm -fr ${TMP_DIR}/*
}


function endOfExecution
{
  if [ $# -eq 0 ]
  then
    CODE=0
  else
    CODE=$1

    COPY_NAME=tmp.error.$(date +"%Y%m%d%H%M%S")
    cp -r ${TMP_DIR} ${SCRIPT_BASEDIR}/${COPY_NAME}
    if [ $? -ne 0 ]
    then
      logError "Ha fallado el comando 'cp -r ${TMP_DIR} ${RUN_DIR}/${COPY_NAME}'"
    else
      cd ${SCRIPT_BASEDIR}
      if [ $? -ne 0 ]
      then
        logError "No se ha podido acceder al directorio '${RUN_DIR}'"
      else
        >/dev/null tar cvf ${COPY_NAME}.tar ${COPY_NAME}
        if [ $? -ne 0 ]
        then
          logError "Ha fallado el comando 'tar cvf ${COPY_NAME}.tar ${COPY_NAME}'"
        else
          rm -fr ${COPY_NAME}

          gzip ${COPY_NAME}.tar
          if [ $? -ne 0 ]
          then
            logError "Ha fallado el comando 'gzip ${COPY_NAME}.tar'"
          fi
        fi
        cd - >/dev/null 2>&1
      fi
    fi
  fi

  purgeLogFiles

  deleteControlFile

  logInfo "Fin de ejecucion -- CODIGO DE RETORNO = ${CODE}"

  exit ${CODE}
}


function purgeLogFiles
{
  LOG_PURGE_DELETE_DAYS=$(getConfigParam GENERAL LOG_PURGE_DELETE_DAYS)
  if [ ${?} -ne 0 ] || [ "${LOG_PURGE_DELETE_DAYS}" = "" ]
  then
    logWarning "No se ha podido obtener el parametro 'LOG_PURGE_DELETE_DAYS' de la seccion de configuracion 'GENERAL'. Se establece al valor por defecto '32'"
    LOG_PURGE_DELETE_DAYS=32
  fi
  logDebug "LOG_PURGE_DELETE_DAYS = '${LOG_PURGE_DELETE_DAYS}'"

  logInfo "Borrando los ficheros de log con antiguedad superior a ${LOG_PURGE_DELETE_DAYS} dias"
  find $(dirname ${LOG_FILEPATH}) -type f -mtime +${LOG_PURGE_DELETE_DAYS} | while read FILEPATH
  do
    rm -f ${FILEPATH}
    logInfo "El fichero '${FILEPATH}' ha sido borrado"
  done

  LOG_PURGE_COMPRESS_DAYS=$(getConfigParam GENERAL LOG_PURGE_COMPRESS_DAYS)
  if [ ${?} -ne 0 ] || [ "${LOG_PURGE_COMPRESS_DAYS}" = "" ]
  then
    logWarning "No se ha podido obtener el parametro 'LOG_PURGE_COMPRESS_DAYS' de la seccion de configuracion 'GENERAL'. Se establece al valor por defecto '8'"
    LOG_PURGE_COMPRESS_DAYS=8
  fi

  logDebug "LOG_PURGE_COMPRESS_DAYS = '${LOG_PURGE_COMPRESS_DAYS}'"

  logInfo "Comprimiendo los ficheros de log con antiguedad superior a ${LOG_PURGE_COMPRESS_DAYS} dias"
  find $(dirname ${LOG_FILEPATH}) -type f -mtime +${LOG_PURGE_COMPRESS_DAYS} | grep -v ".gz$" | while read FILEPATH
  do
    gzip -f ${FILEPATH}
    logInfo "El fichero '${FILEPATH}' ha sido comprimido"
  done
}


#
# Main
#

COMMAND=$(basename $0)

if [ -z ${SCRIPT_BASEDIR} ]
then
  logInfo "${COMMAND} - Inicio de ejecucion"
  logError "${COMMAND} - La variable obligatoria 'SCRIPT_BASEDIR' no esta definida"
  logInfo "${COMMAND} - Fin de ejecucion"
  exit -1
fi

beginingOfExecution
