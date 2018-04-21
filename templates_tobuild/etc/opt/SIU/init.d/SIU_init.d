#!/bin/sh
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

umask 0022

# IUM instance name
INSTNAME='<%SIU_INSTANCE%>'
# Install root path
INSTLROOT='/opt/<%SIU_INSTANCE%>'
BINROOT="$INSTLROOT"

# source the siu_install.ini file
. ${INSTLROOT}/siu_install.ini

# set script variables from values sourced from siu_install.ini
CFGROOT=${ConfigRoot}
VARROOT=${VarRoot}
ETCROOT='/etc/opt/<%SIU_INSTANCE%>'
INSTANCEOWNER=${InstanceOwner}

if [ "$INSTANCEOWNER" != 'root' -a "$(id -u)" = '0' ]; then
  # Proceed as the instance owner
  exec su - "$INSTANCEOWNER" -c "$0 $*"
fi

# sbin directory
SIUSBIN="$INSTLROOT/sbin"
# Host name
[ -f "$CFGROOT/SIU.ini" ] && HOSTID="$(. "$CFGROOT/SIU.ini" && echo $HOSTID)"
# Path to siucontrol executable
SIUCONTROL="$BINROOT/bin/siucontrol"
# Path to SIUJava executable
SIUJAVA="$BINROOT/bin/SIUJava"
# Path to the service log file
LOG_FILE="$VARROOT/log/$INSTNAME-service.log"

# Null file
DEV_NULL='/dev/null'
# File separator
FS='/'
# Exe file extension
EXE=''

# Add IUM executables to PATH
export PATH="$PATH:$INSTLROOT/bin"

# Source utils
. "$INSTLROOT/sbin/SIU-utils"

# Source main config
src "$ETCROOT/rc.config.d/$INSTNAME"

# Source module configs
src "$INSTLROOT/sbin/ium.rc.config.d"

# Source modules
src "$INSTLROOT/sbin/ium.init.d"

usage() {
[#SECTION_BEGIN:MANAGER#]
  echo "Usage: $(basename "$0") start | start_siu | start_db | stop | stop_siu | stop_db | restart | status | help"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
  echo "Usage: $(basename "$0") start | stop | restart | status | help"
[#SECTION_END#]
}

if [ $# -ne 1 ]
then
  usage
  exit 0
fi

action="$1"

case $action in
  'start')
[#SECTION_BEGIN:MANAGER#]
    $INSTLROOT/sbin/mariadb.sh start
[#SECTION_END#]
    agent_start
    ;;
  'start_siu')
    agent_start
    ;;
[#SECTION_BEGIN:MANAGER#]
  'start_db')
    $INSTLROOT/sbin/mariadb.sh start
    ;;
[#SECTION_END#]
  'stop')
    agent_stop
[#SECTION_BEGIN:MANAGER#]
    $INSTLROOT/sbin/mariadb.sh stop
[#SECTION_END#]
  ;;
  'stop_siu')
    agent_stop
    ;;
[#SECTION_BEGIN:MANAGER#]
  'stop_db')
    $INSTLROOT/sbin/mariadb.sh stop
    ;;
[#SECTION_END#]
  'restart')
    agent_stop
[#SECTION_BEGIN:MANAGER#]
    $INSTLROOT/sbin/mariadb.sh stop
    $INSTLROOT/sbin/mariadb.sh start
[#SECTION_END#]
    agent_start
    ;;
  'status')
    agent_status >/tmp/module_status.tmp
    if [ $(cat /tmp/module_status.tmp | grep "Stopped" | wc -l) -gt 0 ]
    then
      rm -f /tmp/module_status.tmp
      exit 3
    fi
    rm -f /tmp/module_status.tmp
  ;;
  'help')
    usage
    ;;
  *)
    echo "Invalid option $action"; usage; exit 1
    ;;
esac
