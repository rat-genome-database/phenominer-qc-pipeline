SELECT
    a.ont_id,
    ot.TERM,
    a.record_count
FROM
    (
        SELECT
            CLINICAL_MEASUREMENT_ONT_ID AS ont_id,
            COUNT(*)                    AS record_count
        FROM
            CLINICAL_MEASUREMENT cm,
            EXPERIMENT_RECORD er
        WHERE
            er.CLINICAL_MEASUREMENT_ID = cm.CLINICAL_MEASUREMENT_ID
        AND er.CURATION_STATUS=40
        AND cm.CLINICAL_MEASUREMENT_ONT_ID NOT IN
            (
                SELECT
                    psu.ont_id
                FROM
                    PHENOMINER_STANDARD_UNITS psu)
        GROUP BY
            CLINICAL_MEASUREMENT_ONT_ID) a
LEFT JOIN
    ONT_TERMS ot
ON
    a.ont_id = ot.TERM_ACC
ORDER BY
    a.record_count DESC;
    
