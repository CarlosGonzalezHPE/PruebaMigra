#!/bin/sh

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
  echo "Usage: $(basename "$0") [start [module]] [stop [module]] [restart [module]] [status [module]]"
  echo "Modules: $(modules)"
}

set -- $(echo $* | tr -d '-' | tr '_' ' ')
[ "$1" ] && action="$1" && shift
[ "$action" ] || action='help'
modules="$@"

case $action in
  'start')
[#SECTION_BEGIN:MANAGER#]
    $INSTLROOT/sbin/mariadb.sh start
[#SECTION_END#]
    module_start $modules
    ;;
  'stop')
    module_stop $modules
[#SECTION_BEGIN:MANAGER#]
    $INSTLROOT/sbin/mariadb.sh stop
[#SECTION_END#]
  ;;
  'restart')
    module_stop $modules
[#SECTION_BEGIN:MANAGER#]
    $INSTLROOT/sbin/mariadb.sh stop
    $INSTLROOT/sbin/mariadb.sh start
[#SECTION_END#]
    module_start $modules
    ;;
  'status')
module_status $modules >/tmp/module_status.tmp
column -t -s ':' << EOF
Module:Name:Status
------:----:------
$(module_status $modules)
EOF
if [ $(cat /tmp/module_status.tmp | grep "Stopped" | wc -l) -gt 0 ]
then
  rm -f /tmp/module_status.tmp
  exit 3
fi
rm -f /tmp/module_status.tmp
  ;;
  'help')    usage
  ;;
  'h')       usage
  ;;
  *)         echo "Invalid option $action"; usage; exit 1
  ;;
esac
