INSERT
INTO
    PHENOMINER_TERM_UNIT_SCALES
    (
        ont_id,
        unit_from,
        unit_to,
        term_specific_scale,
        zero_offset
    )
SELECT DISTINCT
    CLINICAL_MEASUREMENT_ONT_ID AS ont_id,
    er.MEASUREMENT_UNITS,er.MEASUREMENT_UNITS, 1, 0 
FROM
    CLINICAL_MEASUREMENT cm,
    EXPERIMENT_RECORD er
WHERE
    er.CLINICAL_MEASUREMENT_ID = cm.CLINICAL_MEASUREMENT_ID
AND cm.CLINICAL_MEASUREMENT_ONT_ID IN
    (
        SELECT
            ont_id
        FROM
            (
                SELECT DISTINCT
                    CLINICAL_MEASUREMENT_ONT_ID AS ont_id,
                    er.MEASUREMENT_UNITS
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
                ORDER BY
                    CLINICAL_MEASUREMENT_ONT_ID ) a
        GROUP BY
            a.ont_id
        HAVING
            COUNT(*) = 1 );
            INSERT

INTO
    PHENOMINER_STANDARD_UNITS
    (
        ont_id,
        standard_unit
    )
SELECT DISTINCT
    CLINICAL_MEASUREMENT_ONT_ID AS ont_id,
    er.MEASUREMENT_UNITS
FROM
    CLINICAL_MEASUREMENT cm,
    EXPERIMENT_RECORD er
WHERE
    er.CLINICAL_MEASUREMENT_ID = cm.CLINICAL_MEASUREMENT_ID
AND cm.CLINICAL_MEASUREMENT_ONT_ID IN
    (
        SELECT
            ont_id
        FROM
            (
                SELECT DISTINCT
                    CLINICAL_MEASUREMENT_ONT_ID AS ont_id,
                    er.MEASUREMENT_UNITS
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
                ORDER BY
                    CLINICAL_MEASUREMENT_ONT_ID ) a
        GROUP BY
            a.ont_id
        HAVING
            COUNT(*) = 1 );