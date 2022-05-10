#!/usr/bin/env bash
# shell script to run PhenominerQC Pipeline
. /etc/profile

APPNAME="phenominer-qc-pipeline"
APPDIR=/home/rgddata/pipelines/$APPNAME
SERVER=`hostname -s | tr '[a-z]' '[A-Z]'`
EMAIL_LIST=mtutaj@mcw.edu
if [ "$SERVER" = "REED" ]; then
  EMAIL_LIST=mtutaj@mcw.edu,slaulede@mcw.edu
fi

cd $APPDIR

java -Dspring.config=$APPDIR/../properties/default_db2.xml \
    -Dlog4j.configurationFile=file://$APPDIR/properties/log4j2.xml \
    -jar lib/$APPNAME.jar "$@" 2>&1 | tee run.log

#VT_MULTIS_FILE="logs/QTLs_with_multiple_VT_annotations_daily.log"
#if [ -s "$VT_MULTIS_FILE" ]; then
#    mailx -s "[$SERVER] QTL qc: QTLs with multiple VT annotations." $EMAIL_LIST < $VT_MULTIS_FILE
#fi

#CMO_MULTIS_FILE="logs/QTLs_with_multiple_CMO_annotations_daily.log"
#if [ -s "$CMO_MULTIS_FILE" ]; then
#    mailx -s "[$SERVER] QTL qc: QTLs with multiple CMO annotations." $EMAIL_LIST < $CMO_MULTIS_FILE
#fi

#mailx -s "[$SERVER] QtlQC pipeline OK" $EMAIL_LIST < run.log

exit 0
######
# TODO
######

SERVER=`hostname -s | tr '[a-z]' '[A-Z]'`
OUTPUT_FOLDER=sql_output/
CURATOR_EMAIL=`cat ../../pipeUtils/conf/curator_email.txt`
DEVELOPER_EMAIL=`cat ../../pipeUtils/conf/developer_email.txt`
RSO_DEVELOPER_EMAIL=`cat ../../pipeUtils/conf/rso_developer_email.txt`
CMO_DEVELOPER_EMAIL=`cat ../../pipeUtils/conf/cmo_developer_email.txt`

echo "Check XC:22 duration: less than 1 minute."
OUTPUT_FILE=$OUTPUT_FOLDER/XCO22_duration_records.tsv
$UTILS_HOME/bin/run_sql.sh check_XCO22_duration.sql $OUTPUT_FILE

mailx -s "[$SERVER] Checking XCO:22's durations finished." $DEVELOPER_EMAIL < $OUTPUT_FILE
WC_RESULT=`wc -l $OUTPUT_FILE | awk '{print $1}'`
if [[ $WC_RESULT != '1' ]]
then
  echo "Emailing result to curator."
  mailx -s "[$SERVER] Checking XCO:22's durations finished." $CURATOR_EMAIL < $OUTPUT_FILE
  echo "Update XCO22 records' curation status."
  $UTILS_HOME/bin/run_sql.sh update_XCO22_duration_status.sql Console

  mailx -s "[$SERVER] Updating status of XCO:22 records." $DEVELOPER_EMAIL < /dev/null
fi

mv $OUTPUT_FILE ../logs/XCO22_duration_records_$($UTILS_HOME/bin/get_log_date.sh).log


echo "Check if there is any null unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/null_unit_conversions.tsv
$UTILS_HOME/bin/run_sql.sh check_unit_conversion_table.sql $OUTPUT_FILE
mailx -s "[$SERVER] Checking null unit conversions finished." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

mv $OUTPUT_FILE ../logs/null_unit_conversions_$($UTILS_HOME/bin/get_log_date.sh).log

echo "Calculate SEM, SD or number of animals given the other two."
OUTPUT_FILE=$OUTPUT_FOLDER/SEM_SD_NOA_results.tsv
$UTILS_HOME/bin/run_sql.sh update_sem_sd_noa.sql $OUTPUT_FILE
mailx -s "[$SERVER] Calculate SEM, SD or NOA." $DEVELOPER_EMAIL < $OUTPUT_FILE

mv $OUTPUT_FILE ../logs/null_unit_conversions_$($UTILS_HOME/bin/get_log_date.sh).log

echo "Check if any RSO term used in PM don't have RGD IDs."
OUTPUT_FILE=$OUTPUT_FOLDER/NO_RGDID_RSO_terms_results.tsv
$UTILS_HOME/bin/run_sql.sh check_invalid_RSO_usages.sql $OUTPUT_FILE
mailx -s "[$SERVER] Check if any RSO term used in PM do not have RGD IDs." $RSO_DEVELOPER_EMAIL < $OUTPUT_FILE

mv $OUTPUT_FILE ../logs/invalid_RSO_usages_$($UTILS_HOME/bin/get_log_date.sh).log


echo "Add standard units based on existing records."
OUTPUT_FILE=$OUTPUT_FOLDER/new_standard_units.tsv
$UTILS_HOME/bin/run_sql.sh add_standard_units_based_on_existing_records.sql $OUTPUT_FILE
#mailx -s "[$SERVER] Common unit conversions updated." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Update and insert records for common unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/common_unit_conversions.tsv
$UTILS_HOME/bin/run_sql.sh update_unit_conversion_table.sql $OUTPUT_FILE
#mailx -s "[$SERVER] Common unit conversions updated." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Get CMO terms without standard units."
OUTPUT_FILE=$OUTPUT_FOLDER/CMO_terms_missing_standard_units.tsv
$UTILS_HOME/bin/run_sql.sh get_missing_standard_units.sql $OUTPUT_FILE
mailx -s "[$SERVER] CMO terms without standard units." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Get undefined unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/undefined_conversions.tsv
$UTILS_HOME/bin/run_sql.sh get_not_convertible_units.sql $OUTPUT_FILE
mailx -s "[$SERVER] Undefined unit conversions." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE
