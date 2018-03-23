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
  echo "Usage: oam-dump_blacklist.sh -f <dump_filepath>"
  exit 1
}

DUMP_FILEPATH=
while getopts f: OPC
do
  case ${OPC} in
    f)
      DUMP_FILEPATH=${OPTARG}
      ;;
  [?])
    showUsageAndExit
  esac
done

if [ -z ${DUMP_FILEPATH} ]
then
  showUsageAndExit
fi

echo "Name;Range Start;Range End" > ${DUMP_FILEPATH}
if [ $? -ne 0 ]
then
  echo -n "  ["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] Unable to create file '${DUMP_FILEPATH}'"
  exit 1
fi

echo "SELECT CONCAT_WS(';', DEG_RANGENAME, DEG_RANGESTART, DEG_RANGEEND) INTO OUTFILE '/var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/dump.csv' FROM DEG_BLACKLIST_RANGES ORDER BY DEG_RANGESTART;" > /var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/query_blacklist.sql

> /var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/query_blacklist.out_err 2>&1 /usr/bin/mysql -u root -S /var/Mariadb/DEG_APP_MD/mysql.sock -D deg_dsn_md -e "source /var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/query_blacklist.sql"

if [ $(cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/query_blacklist.out_err | grep "ERROR" | wc -l) -gt 0 ]
then
  echo -n "  ["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] Unable to dump IMSI ranges black list from DataBase"
  rm -f ${DUMP_FILEPATH}
  exit 1
fi

cat /var/opt/<%SIU_INSTANCE%>/scripts/oam/tmp/dump.csv >> ${DUMP_FILEPATH}

echo -n "  ["
setColorSuccess
echo -n "OK"
setColorNormal
echo "] IMSI ranges black list dumped into file '${DUMP_FILEPATH}'"
