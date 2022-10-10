#!/usr/bin/env bash
# shell script to run 'phenominer-qc-pipeline'
. /etc/profile

APPNAME="phenominer-qc-pipeline"
APPDIR=/home/rgddata/pipelines/$APPNAME
SERVER=`hostname -s | tr '[a-z]' '[A-Z]'`

if [ "$SERVER" = "REED" ]; then
  CURATOR_EMAIL="slaulede@mcw.edu,mtutaj@mcw.edu"
  DEVELOPER_EMAIL="mtutaj@mcw.edu"
  RSO_DEVELOPER_EMAIL="sjwang@mcw.edu,mtutaj@mcw.edu"
  CMO_DEVELOPER_EMAIL="jrsmith@mcw.edu,mtutaj@mcw.edu"
else
  CURATOR_EMAIL="mtutaj@mcw.edu"
  DEVELOPER_EMAIL="mtutaj@mcw.edu"
  RSO_DEVELOPER_EMAIL="mtutaj@mcw.edu"
  CMO_DEVELOPER_EMAIL="mtutaj@mcw.edu"
fi

cd $APPDIR

java -Dspring.config=$APPDIR/../properties/default_db2.xml \
    -Dlog4j.configurationFile=file://$APPDIR/properties/log4j2.xml \
    -jar lib/$APPNAME.jar "$@" 2>&1 | tee run.log

XCO22_ISSUES_FILE="$APPDIR/logs/xco22_duration_daily.log"
if [ -s "$XCO22_ISSUES_FILE" ]; then
    mailx -s "[$SERVER] phenominer qc: XCO:0000022 records with duration less than 1 minute" $CURATOR_EMAIL < $XCO22_ISSUES_FILE
fi

NULL_UNIT_CONVERSIONS_FILE="$APPDIR/logs/null_unit_conversion_daily.log"
if [ -s "$NULL_UNIT_CONVERSIONS_FILE" ]; then
    mailx -s "[$SERVER] phenominer qc: unit conversions with nulls" $CMO_DEVELOPER_EMAIL < $NULL_UNIT_CONVERSIONS_FILE
fi

INVALID_RSO_USAGE_FILE="$APPDIR/logs/invalid_rso_usage_daily.log"
if [ -s "$INVALID_RSO_USAGE_FILE" ]; then
    mailx -s "[$SERVER] phenominer qc: RSO term(s) used without valid RGD ID" $RSO_DEVELOPER_EMAIL < $INVALID_RSO_USAGE_FILE
fi

NEW_STD_UNITS_FILE="$APPDIR/logs/new_standard_units_daily.log"
if [ -s "$NEW_STD_UNITS_FILE" ]; then
    mailx -s "[$SERVER] phenominer qc: new standard units inserted" $CMO_DEVELOPER_EMAIL < $NEW_STD_UNITS_FILE
fi

CMO_MISSING_STD_UNITS_FILE="$APPDIR/logs/cmo_missing_standard_units_daily.log"
if [ -s "$CMO_MISSING_STD_UNITS_FILE" ]; then
    mailx -s "[$SERVER] phenominer qc: CMO terms missing standard units" $CMO_DEVELOPER_EMAIL < $CMO_MISSING_STD_UNITS_FILE
fi

mailx -s "[$SERVER] phenominer qc pipeline OK" $DEVELOPER_EMAIL < "$APPDIR/logs/summary.log"

exit 0
######
# TODO
######


echo "Get undefined unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/undefined_conversions.tsv
$UTILS_HOME/bin/run_sql.sh get_not_convertible_units.sql $OUTPUT_FILE
mailx -s "[$SERVER] Undefined unit conversions." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Calculate SEM, SD or number of animals given the other two."
OUTPUT_FILE=$OUTPUT_FOLDER/SEM_SD_NOA_results.tsv
$UTILS_HOME/bin/run_sql.sh update_sem_sd_noa.sql $OUTPUT_FILE
mailx -s "[$SERVER] Calculate SEM, SD or NOA." $DEVELOPER_EMAIL < $OUTPUT_FILE

