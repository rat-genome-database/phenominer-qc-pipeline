select concat('http://kyle.rgd.mcw.edu/rgdweb/curation/phenominer/records.html?act=edit', LISTAGG(id_url, '') within group (order by id_url)) as record_urls 
from (
SELECT s.STUDY_ID,
  e.EXPERIMENT_ID,
  e.EXPERIMENT_NAME,
  concat('&id=', a.ERID) as id_url,
  a.*
FROM study s,
  experiment e ,
  (SELECT er.EXPERIMENT_RECORD_ID                AS erid,
    er.EXPERIMENT_ID                             AS exid,
    ec.EXP_COND_ONT_ID                           AS ecoid,
    ec.EXP_COND_DUR_SEC_LOW_BOUND                AS dur
  FROM EXPERIMENT_RECORD er,
    COND_GROUP_EXPERIMENT_COND cg,
    EXPERIMENT_CONDITION ec,
    MEASUREMENT_METHOD mm
  WHERE er.CURATION_STATUS in (35, 40)
  AND er.CONDITION_GROUP_ID       = cg.CONDITION_GROUP_ID
  AND cg.EXPERIMENT_CONDITION_ID    = ec.EXPERIMENT_CONDITION_ID
  AND ec.EXP_COND_DUR_SEC_LOW_BOUND > 0
  AND mm.MEASUREMENT_METHOD_ID      = er.MEASUREMENT_METHOD_ID
  UNION ALL
  SELECT er.EXPERIMENT_RECORD_ID                  AS erid,
    er.EXPERIMENT_ID                              AS exid,
    ec1.EXP_COND_ONT_ID                            AS ecoid,
    ec1.EXP_COND_DUR_SEC_HIGH_BOUND               AS dur
  FROM EXPERIMENT_RECORD er,
    COND_GROUP_EXPERIMENT_COND cg,
    EXPERIMENT_CONDITION ec1,
    MEASUREMENT_METHOD mm
  WHERE er.CURATION_STATUS in (35, 40)
  AND er.CONDITION_GROUP_ID        = cg.CONDITION_GROUP_ID
  AND cg.EXPERIMENT_CONDITION_ID     = ec1.EXPERIMENT_CONDITION_ID
  AND mm.MEASUREMENT_METHOD_ID       = er.MEASUREMENT_METHOD_ID
  AND ec1.EXP_COND_DUR_SEC_HIGH_BOUND > 0
  ) a
WHERE a.ecoid  = 'XCO:0000022'
AND a.dur      < 60
AND a.exid     = e.EXPERIMENT_ID
and s.STUDY_ID not in (14,21,22,41,401,527,461,529,717,441,421,526,481,482,381,528,522)
AND e.STUDY_ID = s.STUDY_ID
) b
group by b.ecoid

