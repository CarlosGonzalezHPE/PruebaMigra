#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT_NAME=oam-show_subsinfo.sh
export SCRIPT_NAME

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
  echo -n "Usage: oam-show_subsinfo.sh -s "
  setColorArgs
  echo "<imsi>|<mdn>"
  setColorNormal
  echo
  echo "Arguments:"
  setColorArgs
  echo -n "  <imsi>"
  setColorNormal
  echo " : Subscription IMSI (15 digits)"
  setColorArgs
  echo -n "  <mdn>"
  setColorNormal
  echo " : Subscription MDN (9 digits, no country code)"
  exit ${EXIT_CODE}
}


#
# Main
#

setColorTitle
echo "OAM Tools on Manager '$(hostname)' - Show subscription information"
setColorNormal
echo


> /usr/bin/mysql -S /var/Mariadb/${DB_INSTANCE}/mysql.sock -u root -D ${DB_DSN} << EOF
  select \G;
EOF

EXIT_CODE=0
IMSI=
MDN=

while 2>/dev/null getopts f: OPC
do
  case ${OPC} in
    s)
      SUB=${OPTARG}
      ;;
    *)
      EXIT_CODE=1
      showUsageAndExit
      ;;
  esac
done

if [ $(echo ${SUB} | grep -P "^[0-9]{15}$" | wc -l) -gt 0 ]
then
  IMSI=${SUB}
else
  if [ $(echo ${SUB} | grep -P "^[0-9]{9}$" | wc -l) -gt 0 ]
  then
    MDN=${SUB}
  else
    EXIT_CODE=1
    showUsageAndExit
  fi
fi

if [ ! -z ${IMSI} ]
then

fi
