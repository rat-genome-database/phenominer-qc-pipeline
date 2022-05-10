select ot.TERM_ACC,ot.TERM from ONT_TERMS ot
where ot.TERM_ACC like 'RS:%'
and ot.TERM_ACC not in
(
select os.term_acc from ONT_SYNONYMS os
where os.TERM_ACC like 'RS:%'
and lower(os.SYNONYM_NAME) like 'rgd id%'
)
and ot.IS_OBSOLETE=0
and ot.term_acc in
( 
select sa.strain_ont_id from SAMPLE sa, EXPERIMENT_RECORD er
where sa.sample_id = er.sample_id
and er.curation_status <> 50
)
