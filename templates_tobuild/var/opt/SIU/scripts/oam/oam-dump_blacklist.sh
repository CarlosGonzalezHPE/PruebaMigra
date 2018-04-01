#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT_NAME=oam-dump_blacklist.sh
export SCRIPT_NAME

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
  echo -n "Usage: oam-dump_blacklist.sh -f "
  setColorArgs
  echo "<dump_filepath>"
  setColorNormal
  echo
  echo "Arguments:"
  setColorArgs
  echo -n "  <dump_filepath>"
  setColorNormal
  echo " : path of file where the black list of IMSI ranges will be dumped"
  exitAndUnlock ${EXIT_CODE}
}


#
# Main
#

setColorTitle
echo "OAM Tools on Manager '$(hostname)' - Dump IMSI Ranges black list"
setColorNormal
echo

lockExec

EXIT_CODE=0
DUMP_FILEPATH=

while 2>/dev/null getopts f: OPC
do
  case ${OPC} in
    f)
      DUMP_FILEPATH=${OPTARG}
      ;;
    *)
      EXIT_CODE=1
      showUsageAndExit
      ;;
  esac
done

if [ -z ${DUMP_FILEPATH} ]
then
  EXIT_CODE=1
  showUsageAndExit
fi

echo "#Name;Range Start;Range End" > ${DUMP_FILEPATH}
if [ $? -ne 0 ]
then
  echo -n "  ["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] Unable to create file '${DUMP_FILEPATH}'"
  exitAndUnlock 1
fi

rm -f ${TMP_DIR}/dump_blacklist.csv

echo "SELECT CONCAT_WS(';', DEG_RANGENAME, DEG_RANGESTART, DEG_RANGEEND) INTO OUTFILE '${TMP_DIR}/dump_blacklist.csv' FROM DEG_BLACKLIST_RANGES ORDER BY DEG_RANGESTART;" > ${TMP_DIR}/query_blacklist.sql

> ${TMP_DIR}/query_blacklist.out_err 2>&1 /usr/bin/mysql -u root -S /var/Mariadb/DEG_APP_MD/mysql.sock -D deg_dsn_md -e "source ${TMP_DIR}/query_blacklist.sql"

if [ $(cat ${TMP_DIR}/query_blacklist.out_err | grep "ERROR" | wc -l) -gt 0 ]
then
  echo -n "["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] Unable to dump IMSI ranges black list from DataBase"
  rm -f ${DUMP_FILEPATH}
  exitAndUnlock 1
fi

cat ${TMP_DIR}/dump_blacklist.csv >> ${DUMP_FILEPATH}

echo -n "["
if [ $(cat ${DUMP_FILEPATH} | wc -l) -lt 2 ]
then
setColorWarning
echo -n "WARNING"
setColorNormal
echo "] No IMSI ranges dumped in '${DUMP_FILEPATH}'"
else
setColorSuccess
echo -n "OK"
setColorNormal
echo "] IMSI ranges black list dumped into file '${DUMP_FILEPATH}'"
fi
