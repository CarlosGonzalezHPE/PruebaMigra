#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

function check_if_already_running
{
  PROCESS=$1
  NUMBER_OF_INSTANCES=$2
  CURRENT_INSTANCES=$(ps -e -o pid,ppid,cmd | grep -E "^ *[0-9]+ *[0-9]+ *$1*" | grep -Ev "^ *$$ " | grep -Ev "^ *[0-9]+ *$$ " | wc -l)
  if [ ${CURRENT_INSTANCES} -eq ${NUMBER_OF_INSTANCES} ]
  then
    echo 0
  else
    echo 1
  fi
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


function setColorEmphasized
{
  echo -en "\033[0;34m"
}

