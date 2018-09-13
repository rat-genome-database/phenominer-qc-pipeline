/* get non-convertibles */
SELECT
    CM.CLINICAL_MEASUREMENT_ONT_ID,
    ER.MEASUREMENT_UNITS,
    SU.STANDARD_UNIT,
    COUNT(*) AS number_of_records_affected
FROM
    EXPERIMENT_RECORD ER,
    CLINICAL_MEASUREMENT CM,
    PHENOMINER_STANDARD_UNITS SU
WHERE
    ER.CLINICAL_MEASUREMENT_ID = CM.CLINICAL_MEASUREMENT_ID
AND CM.CLINICAL_MEASUREMENT_ONT_ID = SU.ONT_ID
AND er.CURATION_STATUS IN (35,
                           40)
AND (
        ER.MEASUREMENT_UNITS,SU.STANDARD_UNIT ) NOT IN
    (
        SELECT
            unit_from,
            unit_to
        FROM
            phenominer_term_unit_scales tus1
        WHERE
            tus1.ont_id=su.ont_id)
GROUP BY
    CM.CLINICAL_MEASUREMENT_ONT_ID,
    ER.MEASUREMENT_UNITS,
    SU.STANDARD_UNIT
ORDER BY
    number_of_records_affected DESC;
