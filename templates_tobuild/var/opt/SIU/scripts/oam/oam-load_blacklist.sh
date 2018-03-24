#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

SCRIPT_NAME=oam-load_blacklist.sh
export SCRIPT_NAME

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

function showUsageAndExit
{
  echo -n "Usage: oam-load_blacklist.sh -f "
  setColorArgs
  echo -n "<load_filepath>"
  setColorNormal
  echo " [-o] [-b]"
  echo
  echo "Arguments:"
  setColorArgs
  echo -n "  <load_filepath>"
  setColorNormal
  echo " : path of file from which the black list of IMSI ranges will be loaded"
  echo "  -o              : overwrite content of black list in Database"
  echo "  -b              : dump current black list in Database to backup file"
  echo
  echo "Expected file format and error handling:"
  echo "  CSV with delimiter character ';'"
  echo "  Lines starting with character '#' are ignored"
  echo "  3 expected fields: Range Name, Range Start and Range End. Extra fields ignored"
  echo "  Range Name must not be blank"
  echo "  Range Start and Range End must be numbers of 15 digits"
  echo "  Range End must be greater or equals to Range Start"
  echo "  Invalid records are written to file '${TMP_DIR}/load_blacklist.err'"
  exitAndUnlock ${EXIT_CODE}
}


#
# Main
#

lockExec

EXIT_CODE=0
LOAD_FILEPATH=
DUMP_BACKUP=false
OVERWRITE=false
while getopts f:bo OPC
do
  case ${OPC} in
    b)
      DUMP_BACKUP=true
      ;;
    f)
      LOAD_FILEPATH=${OPTARG}
      ;;
    o)
      OVERWRITE=true
      ;;
    *)
      EXIT_CODE=1
      showUsageAndExit
      ;;
  esac
done

if [ -z ${LOAD_FILEPATH} ]
then
  EXIT_CODE=1
  showUsageAndExit
fi

if [ ! -f ${LOAD_FILEPATH} ]
then
  echo -n "  ["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] File '${LOAD_FILEPATH}' does not exists or is not accessible"
  exitAndUnlock 1
fi

if [ ! -s ${LOAD_FILEPATH} ]
then
  echo -n "  ["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] File '${LOAD_FILEPATH}' is empty"
  exitAndUnlock 1
fi

if [ "${DUMP_BACKUP}" = "true" ]
then
  /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-dump_blacklist.sh -f ${BACKUP_DIR}/dump_blacklist.$(date +"%Y%m%d%H%M%S")
  if [ $? -ne 0 ]
  then
    echo -n "["
    setColorError
    echo -n "ERROR"
    setColorNormal
    echo "] Unable to backup the current IMSI ranges black list"
    exitAndUnlock 1
  fi
fi


> ${TMP_DIR}/load_blacklist.sql
if [ "${OVERWRITE}" = "true" ]
then
  echo "TRUNCATE TABLE DEG_BLACKLIST_RANGES;" > ${TMP_DIR}/load_blacklist.sql
fi

cat ${LOAD_FILEPATH} | grep -v "^#" | awk -F \; -v OUT=${TMP_DIR}/load_blacklist.sql -v ERR=${OUTPUT_DIR}/load_blacklist.err '{
  if (NF < 3) {
    print $0 >> ERR;
    next;
  }

  range_name = $1;
  range_start = $2;
  range_end = $3;

  if (length(range_name) < 1) {
    print $0 >> ERR;
    next;
  }

  if (length(range_start) != 15) {
    print $0 >> ERR;
    next;
  }

  if (length(range_end) != 15) {
    print $0 >> ERR;
    next;
  }

  if (range_end < range_start) {
    print $0 >> ERR;
    next;
  }

  print "INSERT INTO DEG_BLACKLIST_RANGES (DEG_RANGENAME, DEG_RANGESTART, DEG_RANGEEND) VALUES (\x27"range_name"\x27, \x27"range_start"\x27, \x27"range_end"\x27);" >> OUT;
}'

> ${TMP_DIR}/load_blacklist.out_err 2>&1 /usr/bin/mysql -u root -S /var/Mariadb/DEG_APP_MD/mysql.sock -D deg_dsn_md -e "source ${TMP_DIR}/load_blacklist.sql"

if [ $(cat ${TMP_DIR}/load_blacklist.out_err | grep "ERROR" | wc -l) -gt 0 ]
then
  echo -n "["
  setColorError
  echo -n "ERROR"
  setColorNormal
  echo "] Unable to load IMSI ranges black list to DataBase"
  exitAndUnlock 1
fi

echo -n "["
setColorSuccess
echo -n "OK"
setColorNormal
echo "] IMSI ranges black list loaded into Database from file '${LOAD_FILEPATH}'"
