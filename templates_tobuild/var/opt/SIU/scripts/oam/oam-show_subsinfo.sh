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
  echo "  : Subscription MDN (9 digits, no country code)"
  exit ${EXIT_CODE}
}


#
# Main
#

setColorTitle
echo "OAM Tools on Manager '$(hostname)' - Show subscription information"
setColorNormal
echo

EXIT_CODE=0
IMSI=
MDN=

while 2>/dev/null getopts s: OPC
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
  setColorArgs
  echo "Information from table DEG_DEVICE_DATA"
  setColorNormal
  echo "select * from deg_device_data where deg_imsi=${IMSI}\G;" > ${TMP_DIR}/oam-show_subsinfo.$$.sql
  setColorNormal
  /usr/bin/mysql -S /var/Mariadb/DEG_APP_MD/mysql.sock -u root -D DEG_DSN_MD -e "source ${TMP_DIR}/oam-show_subsinfo.$$.sql"
  echo
  setColorArgs
  echo "Information from table DEG_TOKENS"
  setColorNormal
  echo "select * from deg_tokens where deg_imsi=${IMSI}\G;" > ${TMP_DIR}/oam-show_subsinfo.$$.sql
  /usr/bin/mysql -S /var/Mariadb/DEG_APP_MD/mysql.sock -u root -D DEG_DSN_MD -e "source ${TMP_DIR}/oam-show_subsinfo.$$.sql"
  setColorArgs
  echo
  echo "Information from table DEG_DEVICE_ICCIDS (TOKYO)"
  setColorNormal
  echo "select * from deg_device_iccids where deg_imsi=${IMSI}\G;" > ${TMP_DIR}/oam-show_subsinfo.$$.sql
  /usr/bin/mysql -S /var/Mariadb/DEG_APP_MD/mysql.sock -u root -D DEG_DSN_MD -e "source ${TMP_DIR}/oam-show_subsinfo.$$.sql"
else
  setColorArgs
  echo "Information from table DEG_DEVICE_DATA"
  setColorNormal
  echo "select d.* from deg_device_data d, deg_tokens t where t.deg_mdn = 34${MDN} and d.deg_imsi = t.deg_imsi\G;" > ${TMP_DIR}/oam-show_subsinfo.$$.sql
  /usr/bin/mysql -S /var/Mariadb/DEG_APP_MD/mysql.sock -u root -D DEG_DSN_MD -e "source ${TMP_DIR}/oam-show_subsinfo.$$.sql"
  echo
  setColorArgs
  echo "Information from table DEG_TOKENS"
  setColorNormal
  echo "select * from deg_tokens where deg_mdn = 34${MDN}\G;" > ${TMP_DIR}/oam-show_subsinfo.$$.sql
  /usr/bin/mysql -S /var/Mariadb/DEG_APP_MD/mysql.sock -u root -D DEG_DSN_MD -e "source ${TMP_DIR}/oam-show_subsinfo.$$.sql"
  setColorArgs
  echo
  echo "Information from table DEG_DEVICE_ICCIDS (TOKYO)"
  setColorNormal
  echo "select d.* from deg_device_iccids d, deg_tokens t where t.deg_mdn = 34${MDN} and d.deg_imsi = t.deg_imsi\G;" > ${TMP_DIR}/oam-show_subsinfo.$$.sql
  /usr/bin/mysql -S /var/Mariadb/DEG_APP_MD/mysql.sock -u root -D DEG_DSN_MD -e "source ${TMP_DIR}/oam-show_subsinfo.$$.sql"
fi

rm -f ${TMP_DIR}/oam-show_subsinfo.$$.sql
