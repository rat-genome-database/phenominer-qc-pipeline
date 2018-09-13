select concat('http://kyle.rgd.mcw.edu/rgdweb/curation/phenominer/records.html?act=edit', LISTAGG(id_url, '') within group (order by id_url)) as record_urls 
from (
SELECT
    dups.row_number,
    st0.*,
    ex0.*,
    er0.EXPERIMENT_RECORD_ID,
    mm0.MEASUREMENT_METHOD_ONT_ID,
    cm0.CLINICAL_MEASUREMENT_ONT_ID,
    sm0.STRAIN_ONT_ID,
    sm0.NUMBER_OF_ANIMALS,
    sm0.SEX,
    sm0.AGE_DAYS_FROM_DOB_LOW_BOUND,
    sm0.AGE_DAYS_FROM_DOB_HIGH_BOUND,
    er0.MEASUREMENT_SD,
    er0.MEASUREMENT_SEM,
    er0.MEASUREMENT_UNITS,
    er0.MEASUREMENT_VALUE,
    er0.MEASUREMENT_ERROR,
    ec0.EXP_COND_ONT_ID,
    ec0.EXP_COND_ASSOC_VALUE_MIN,
    ec0.EXP_COND_ASSOC_VALUE_MAX,
    concat('&id=', er0.EXPERIMENT_RECORD_ID) as id_url
FROM
    experiment_record er0,
    MEASUREMENT_METHOD mm0,
    CLINICAL_MEASUREMENT cm0,
    COND_GROUP_EXPERIMENT_COND cg0,
    EXPERIMENT_CONDITION ec0,
    EXPERIMENT ex0,
    STUDY st0,
    SAMPLE sm0,
    (
        SELECT ROW_NUMBER() OVER (ORDER BY (er1.MEASUREMENT_VALUE*sm1.NUMBER_OF_ANIMALS )DESC) as row_number,
            er1.MEASUREMENT_SD,
            er1.MEASUREMENT_SEM,
            er1.MEASUREMENT_UNITS,
            er1.MEASUREMENT_VALUE,
            er1.MEASUREMENT_ERROR,
            mm1.MEASUREMENT_METHOD_ONT_ID,
            cm1.CLINICAL_MEASUREMENT_ONT_ID,
            ec1.EXP_COND_ONT_ID,
            ec1.EXP_COND_ASSOC_VALUE_MIN,
            ec1.EXP_COND_ASSOC_VALUE_MAX,
            sm1.STRAIN_ONT_ID,
            sm1.NUMBER_OF_ANIMALS,
            sm1.SEX,
            sm1.AGE_DAYS_FROM_DOB_HIGH_BOUND,
            sm1.AGE_DAYS_FROM_DOB_LOW_BOUND
        FROM
            experiment_record er1 left join 
            (select cg2.CONDITION_GROUP_ID, ec3.EXP_COND_ONT_ID ,
            ec3.EXP_COND_ASSOC_VALUE_MIN,
            ec3.EXP_COND_ASSOC_VALUE_MAX
            from COND_GROUP_EXPERIMENT_COND cg2, EXPERIMENT_CONDITION ec3
            where cg2.EXPERIMENT_CONDITION_ID = ec3.EXPERIMENT_CONDITION_ID AND ec3.EXP_COND_ORDINALITY=2
            ) ec2 on er1.CONDITION_GROUP_ID = ec2.CONDITION_GROUP_ID,
            MEASUREMENT_METHOD mm1,
            CLINICAL_MEASUREMENT cm1,
            COND_GROUP_EXPERIMENT_COND cg1, 
            EXPERIMENT_CONDITION ec1,
            SAMPLE sm1
        WHERE
            er1.CURATION_STATUS in(40,35)
        AND er1.CLINICAL_MEASUREMENT_ID = cm1.CLINICAL_MEASUREMENT_ID
        AND er1.MEASUREMENT_METHOD_ID = mm1.MEASUREMENT_METHOD_ID
        AND er1.CONDITION_GROUP_ID = cg1.CONDITION_GROUP_ID
        AND cg1.EXPERIMENT_CONDITION_ID = ec1.EXPERIMENT_CONDITION_ID
        AND ec1.EXP_COND_ORDINALITY = 1
        AND er1.SAMPLE_ID = sm1.SAMPLE_ID
        GROUP BY
            er1.MEASUREMENT_SD,
            er1.MEASUREMENT_SEM,
            er1.MEASUREMENT_UNITS,
            er1.MEASUREMENT_VALUE,
            er1.MEASUREMENT_ERROR,
            mm1.MEASUREMENT_METHOD_ONT_ID,
            cm1.CLINICAL_MEASUREMENT_ONT_ID,
            ec1.EXP_COND_ONT_ID,
            ec1.EXP_COND_ASSOC_VALUE_MIN,
            ec1.EXP_COND_ASSOC_VALUE_MAX,
            ec2.EXP_COND_ONT_ID,
            ec2.EXP_COND_ASSOC_VALUE_MIN,
            ec2.EXP_COND_ASSOC_VALUE_MAX,
            sm1.STRAIN_ONT_ID,
            sm1.NUMBER_OF_ANIMALS,
            sm1.SEX,
            sm1.AGE_DAYS_FROM_DOB_HIGH_BOUND,
            sm1.AGE_DAYS_FROM_DOB_LOW_BOUND
        HAVING
            COUNT(*) > 1
    )
    dups
WHERE
    st0.STUDY_ID not in (14,21,22,41,401,527,461,529,717,441,421,526,481,482,381,528,522)
AND st0.STUDY_ID = ex0.STUDY_ID
AND ex0.EXPERIMENT_ID = er0.EXPERIMENT_ID
AND er0.CURATION_STATUS in (35,40)
AND er0.CLINICAL_MEASUREMENT_ID = cm0.CLINICAL_MEASUREMENT_ID
AND er0.MEASUREMENT_METHOD_ID = mm0.MEASUREMENT_METHOD_ID
AND er0.CONDITION_GROUP_ID = cg0.CONDITION_GROUP_ID
AND cg0.EXPERIMENT_CONDITION_ID = ec0.EXPERIMENT_CONDITION_ID
AND ec0.EXP_COND_ORDINALITY = 1
and er0.SAMPLE_ID = sm0.SAMPLE_ID
AND
    (
        er0.MEASUREMENT_SD = dups.MEASUREMENT_SD
     OR
        (
            er0.MEASUREMENT_SD IS NULL
        AND dups.MEASUREMENT_SD IS NULL
        )
    )
AND
    (
        er0.MEASUREMENT_SEM = dups.MEASUREMENT_SEM
     OR
        (
            er0.MEASUREMENT_SEM IS NULL
        AND dups.MEASUREMENT_SEM IS NULL
        )
    )
AND
    (
        er0.MEASUREMENT_UNITS = dups.MEASUREMENT_UNITS
     OR
        (
            er0.MEASUREMENT_UNITS IS NULL
        AND dups.MEASUREMENT_UNITS IS NULL
        )
    )
AND
    (
        er0.MEASUREMENT_VALUE=dups.MEASUREMENT_VALUE
     OR
        (
            er0.MEASUREMENT_VALUE IS NULL
        AND dups.MEASUREMENT_VALUE IS NULL
        )
    )
AND
    (
        er0.MEASUREMENT_ERROR=dups.MEASUREMENT_ERROR
     OR
        (
            er0.MEASUREMENT_ERROR IS NULL
        AND dups.MEASUREMENT_ERROR IS NULL
        )
    )
AND
    (
        mm0.MEASUREMENT_METHOD_ONT_ID=dups.MEASUREMENT_METHOD_ONT_ID
    )
AND
    (
        cm0.CLINICAL_MEASUREMENT_ONT_ID=dups.CLINICAL_MEASUREMENT_ONT_ID
    )
AND
    (
        ec0.EXP_COND_ONT_ID=dups.EXP_COND_ONT_ID
    )
AND
    (
        ec0.EXP_COND_ASSOC_VALUE_MIN=dups.EXP_COND_ASSOC_VALUE_MIN
     OR
        (
            ec0.EXP_COND_ASSOC_VALUE_MIN IS NULL
        AND dups.EXP_COND_ASSOC_VALUE_MIN IS NULL
        )
    )
AND
    (
        ec0.EXP_COND_ASSOC_VALUE_MAX=dups.EXP_COND_ASSOC_VALUE_MAX
     OR
        (
            ec0.EXP_COND_ASSOC_VALUE_MAX IS NULL
        AND dups.EXP_COND_ASSOC_VALUE_MAX IS NULL
        )
    )
AND
    (
        sm0.STRAIN_ONT_ID=dups.STRAIN_ONT_ID
    )
AND
    (
        sm0.NUMBER_OF_ANIMALS=dups.NUMBER_OF_ANIMALS
     OR
        (
            sm0.NUMBER_OF_ANIMALS IS NULL
        AND dups.NUMBER_OF_ANIMALS IS NULL
        )
    )
AND
    (
        sm0.SEX=dups.SEX
     OR
        (
            sm0.SEX IS NULL
        AND dups.SEX IS NULL
        )
    )
AND
    (
        sm0.AGE_DAYS_FROM_DOB_LOW_BOUND=dups.AGE_DAYS_FROM_DOB_LOW_BOUND
     OR
        (
            sm0.AGE_DAYS_FROM_DOB_LOW_BOUND IS NULL
        AND dups.AGE_DAYS_FROM_DOB_LOW_BOUND IS NULL
        )
    )
AND
    (
        sm0.AGE_DAYS_FROM_DOB_HIGH_BOUND=dups.AGE_DAYS_FROM_DOB_HIGH_BOUND
     OR
        (
            sm0.AGE_DAYS_FROM_DOB_HIGH_BOUND IS NULL
        AND dups.AGE_DAYS_FROM_DOB_HIGH_BOUND IS NULL
        )
    )
ORDER BY
    er0.MEASUREMENT_SD,
    er0.MEASUREMENT_SEM,
    er0.MEASUREMENT_UNITS,
    er0.MEASUREMENT_VALUE,
    er0.MEASUREMENT_ERROR,
    mm0.MEASUREMENT_METHOD_ONT_ID,
    cm0.CLINICAL_MEASUREMENT_ONT_ID,
    sm0.STRAIN_ONT_ID,
    ec0.EXP_COND_ONT_ID,
    ec0.EXP_COND_ASSOC_VALUE_MIN,
    ec0.EXP_COND_ASSOC_VALUE_MAX,
    er0.EXPERIMENT_ID,
    er0.EXPERIMENT_RECORD_ID 
    ) a 
    group by a.row_number
