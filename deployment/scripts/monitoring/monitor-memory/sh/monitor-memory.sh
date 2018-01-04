#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

#
# Functions
#

function process
{
  logDebug "Executing function 'process'"

  MEMORY_HIGH_DATA="$(getConfigParam MEMORY HIGH_LIMIT)"
  if [ $? -lt 0 ] || [ -z ${MEMORY_HIGH_DATA} ]
  then
    logError "Unable to get mandatory parameter 'HIGH_LIMIT' in section 'MEMORY'"
    return 1
  fi
  logDebug "MEMORY_HIGH_DATA = ${MEMORY_HIGH_DATA}"

  let MEMORY_HIGH_LIMIT=$(echo ${MEMORY_HIGH_DATA} | cut -d "-" -f 1)
  MEMORY_HIGH_SEVERITY=$(echo ${MEMORY_HIGH_DATA} | cut -d "-" -f 2)
  logDebug "MEMORY_HIGH_LIMIT = ${MEMORY_HIGH_LIMIT}"
  logDebug "MEMORY_HIGH_SEVERITY = ${MEMORY_HIGH_SEVERITY}"

  MEMORY_LOW_DATA="$(getConfigParam MEMORY LOW_LIMIT)"
  if [ $? -lt 0 ] || [ -z ${MEMORY_LOW_DATA} ]
  then
    logError "Unable to get mandatory parameter 'LOW_LIMIT' in section 'MEMORY'"
    return 1
  fi
  logDebug "MEMORY_LOW_DATA = ${MEMORY_LOW_DATA}"

  let MEMORY_LOW_LIMIT=$(echo ${MEMORY_LOW_DATA} | cut -d "-" -f 1)
  MEMORY_LOW_SEVERITY=$(echo ${MEMORY_LOW_DATA} | cut -d "-" -f 2)
  logDebug "MEMORY_LOW_LIMIT = ${MEMORY_LOW_LIMIT}"
  logDebug "MEMORY_LOW_SEVERITY = ${MEMORY_LOW_SEVERITY}"

  ALARM_DESCRIPTION="$(getConfigParam ALARM ALARM_DESCRIPTION)"
  if [ $? -lt 0 ] || [ -z ${ALARM_DESCRIPTION} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_DESCRIPTION' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_DESCRIPTION = ${ALARM_DESCRIPTION}"

  ALARM_ADDITIONAL_INFO="$(getConfigParam ALARM ALARM_ADDITIONAL_INFO)"
  if [ $? -lt 0 ] || [ -z ${ALARM_ADDITIONAL_INFO} ]
  then
    logError "Unable to get mandatory parameter 'ALARM_ADDITIONAL_INFO' in section 'ALARM'"
    return 1
  fi
  logDebug "ALARM_ADDITIONAL_INFO = ${ALARM_ADDITIONAL_INFO}"

  free -m | egrep "Mem:|-/+" | awk '
  {
    ratio = (100 * $3) / 100;
    if (ratio > 0) {
      print "OK|" ratio
    }
  }' > ${TMP_DIR}/ratio

  if [ -s ${TMP_DIR}/ratio ]
  then

  else
    logError "Unable to compute memory usage ratio"
    return 1
  fi

  let RATIO=$(cat ${TMP_DIR}/ratio | head -n 1)

  if [ ${RATIO} -ge ${MEMORY_HIGH_LIMIT} ]
  then
    LIMIT=${MEMORY_HIGH_LIMIT}
    SEVERITY=${MEMORY_HIGH_SEVERITY}
  else
    if [ ${RATIO} -ge ${MEMORY_LOW_LIMIT} ]
    then
      LIMIT=${MEMORY_LOW_LIMIT}
      SEVERITY=${MEMORY_LOW_SEVERITY}
    else
      logInfo "No alarm condition detected"
      return 0
    fi
  fi

  ACTUAL_ALARM_DESCRIPTION=$(eval echo "${ALARM_DESCRIPTION}")
  ACTUAL_ALARM_ADDITIONAL_INFO=$(eval echo "${ALARM_ADDITIONAL_INFO}")

  addAlarm "$(hostname | cut -d "." -f 1) memory" "${SEVERITY}" "${ALARM_DESCRIPTION}" "${ALARM_ADDITIONAL_INFO}"
  if [ $? -ne 0 ]
  then
    logError "Unable to add alarm"
    return 1
  fi
}


#
# Main
#

SCRIPT_BASEDIR=/opt/<%SIU_INSTANCE%>/scripts/monitoring/monitor-memory
export SCRIPT_BASEDIR

. /opt/<%SIU_INSTANCE%>/scripts/monitoring/common/common.sh


process
if [ $? -ne 0 ]
then
  logWarning "Function 'process' executed with errors"
  endOfExecution 1
fi

endOfExecution
