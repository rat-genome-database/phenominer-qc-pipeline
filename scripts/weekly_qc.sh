#!/bin/sh

source /home/rgddata/pipelines/pipeUtils/bin/set_env.sh

cd $(dirname $0)

OUTPUT_FOLDER=sql_output/
CURATOR_EMAIL=`cat ../../pipeUtils/conf/curator_email.txt`
DEVELOPER_EMAIL=`cat ../../pipeUtils/conf/developer_email.txt`
RSO_DEVELOPER_EMAIL=`cat ../../pipeUtils/conf/rso_developer_email.txt`
CMO_DEVELOPER_EMAIL=`cat ../../pipeUtils/conf/cmo_developer_email.txt`

# echo "Checking for duplciated records."
# OUTPUT_FILE=$OUTPUT_FOLDER/duplicate_records.tsv
# $UTILS_HOME/bin/run_sql.sh get_duplicate_records.sql $OUTPUT_FILE

# mailx -s "[Morgan] Checking for duplicate records finished." $DEVELOPER_EMAIL < $OUTPUT_FILE
# WC_RESULT=`wc -l $OUTPUT_FILE | awk '{print $1}'`
# if [[ $WC_RESULT != '1' ]]
# then
  # echo "Emailing result to curator."
  # mailx -s "[Morgan] Checking for duplicate records finished." $CURATOR_EMAIL < $OUTPUT_FILE
  # echo "Update duplicated records' status to In Progress."
  # $UTILS_HOME/bin/run_sql.sh update_duplicate_records_status.sql Console

  # mailx -s "[Morgan] Updating status of duplicate records finished." $DEVELOPER_EMAIL < /dev/null
# fi

# mv $OUTPUT_FILE ../logs/duplicate_records_$($UTILS_HOME/bin/get_log_date.sh).log


echo "Check XC:22 duration: less than 1 minute."
OUTPUT_FILE=$OUTPUT_FOLDER/XCO22_duration_records.tsv
$UTILS_HOME/bin/run_sql.sh check_XCO22_duration.sql $OUTPUT_FILE

mailx -s "[Morgan] Checking XCO:22's durations finished." $DEVELOPER_EMAIL < $OUTPUT_FILE
WC_RESULT=`wc -l $OUTPUT_FILE | awk '{print $1}'`
if [[ $WC_RESULT != '1' ]]
then
  echo "Emailing result to curator."
  mailx -s "[Morgan] Checking XCO:22's durations finished." $CURATOR_EMAIL < $OUTPUT_FILE
  echo "Update XCO22 records' curation status."
  $UTILS_HOME/bin/run_sql.sh update_XCO22_duration_status.sql Console 

  mailx -s "[Morgan] Updating status of XCO:22 records." $DEVELOPER_EMAIL < /dev/null
fi

mv $OUTPUT_FILE ../logs/XCO22_duration_records_$($UTILS_HOME/bin/get_log_date.sh).log


echo "Check if there is any null unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/null_unit_conversions.tsv
$UTILS_HOME/bin/run_sql.sh check_unit_conversion_table.sql $OUTPUT_FILE
mailx -s "[Morgan] Checking null unit conversions finished." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

mv $OUTPUT_FILE ../logs/null_unit_conversions_$($UTILS_HOME/bin/get_log_date.sh).log

echo "Calculate SEM, SD or number of animals given the other two."
OUTPUT_FILE=$OUTPUT_FOLDER/SEM_SD_NOA_results.tsv
$UTILS_HOME/bin/run_sql.sh update_sem_sd_noa.sql $OUTPUT_FILE
mailx -s "[Morgan] Calculate SEM, SD or NOA." $DEVELOPER_EMAIL < $OUTPUT_FILE

mv $OUTPUT_FILE ../logs/null_unit_conversions_$($UTILS_HOME/bin/get_log_date.sh).log

echo "Check if any RSO term used in PM don't have RGD IDs."
OUTPUT_FILE=$OUTPUT_FOLDER/NO_RGDID_RSO_terms_results.tsv
$UTILS_HOME/bin/run_sql.sh check_invalid_RSO_usages.sql $OUTPUT_FILE
mailx -s "[Morgan] Check if any RSO term used in PM do not have RGD IDs." $RSO_DEVELOPER_EMAIL < $OUTPUT_FILE

mv $OUTPUT_FILE ../logs/invalid_RSO_usages_$($UTILS_HOME/bin/get_log_date.sh).log


echo "Add standard units based on existing records."
OUTPUT_FILE=$OUTPUT_FOLDER/new_standard_units.tsv
$UTILS_HOME/bin/run_sql.sh add_standard_units_based_on_existing_records.sql $OUTPUT_FILE
#mailx -s "[Morgan] Common unit conversions updated." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Update and insert records for common unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/common_unit_conversions.tsv
$UTILS_HOME/bin/run_sql.sh update_unit_conversion_table.sql $OUTPUT_FILE
#mailx -s "[Morgan] Common unit conversions updated." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Get CMO terms without standard units."
OUTPUT_FILE=$OUTPUT_FOLDER/CMO_terms_missing_standard_units.tsv
$UTILS_HOME/bin/run_sql.sh get_missing_standard_units.sql $OUTPUT_FILE
mailx -s "[Morgan] CMO terms without standard units." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

echo "Get undefined unit conversions."
OUTPUT_FILE=$OUTPUT_FOLDER/undefined_conversions.tsv
$UTILS_HOME/bin/run_sql.sh get_not_convertible_units.sql $OUTPUT_FILE
mailx -s "[Morgan] Undefined unit conversions." $CMO_DEVELOPER_EMAIL < $OUTPUT_FILE

