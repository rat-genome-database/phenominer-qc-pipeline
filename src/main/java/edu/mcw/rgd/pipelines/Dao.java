package edu.mcw.rgd.pipelines;

import edu.mcw.rgd.dao.AbstractDAO;
import edu.mcw.rgd.dao.spring.StringListQuery;
import edu.mcw.rgd.dao.spring.StringMapQuery;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.List;

/**
 * Created by mtutaj on 1/14/2021
 * <p>
 * All database code lands here
 */
public class Dao {

    AbstractDAO adao = new AbstractDAO();

    Logger logXCO22Duration = LogManager.getLogger("xco22_duration");
    Logger logNullUnitConversions = LogManager.getLogger("null_unit_conversion");
    Logger logInvalidRsoUsage = LogManager.getLogger("invalid_rso_usage");
    Logger logNewStandardUnits = LogManager.getLogger("new_standard_units");
    Logger logCmoMissingStandardUnits = LogManager.getLogger("cmo_missing_standard_units");

    /// XCO22 (controlled sodium diet) duration must be shorter than 1 minute
    public List<String> checkXCO22Duration() throws Exception {

        String sql =
            "select concat('https://pipelines.rgd.mcw.edu/rgdweb/curation/phenominer/records.html?act=edit', " +
            "  LISTAGG(id_url, '') within group (order by id_url)) as record_urls \n" +
            "from (\n" +
            "SELECT s.STUDY_ID,\n" +
            "  e.EXPERIMENT_ID,\n" +
            "  e.EXPERIMENT_NAME,\n" +
            "  concat('&id=', a.ERID) as id_url,\n" +
            "  a.*\n" +
            "FROM study s,\n" +
            "  experiment e ,\n" +
            "  (\n" +
            "  SELECT er.EXPERIMENT_RECORD_ID     AS erid,\n" +
            "    er.EXPERIMENT_ID               AS exid,\n" +
            "    ec.EXP_COND_ONT_ID             AS ecoid,\n" +
            "    ec.EXP_COND_DUR_SEC_LOW_BOUND  AS dur\n" +
            "  FROM EXPERIMENT_RECORD er,\n" +
            "    EXPERIMENT_CONDITION ec,\n" +
            "    MEASUREMENT_METHOD mm\n" +
            "  WHERE er.CURATION_STATUS in (35, 40)\n" +
            "  AND er.EXPERIMENT_RECORD_ID       = ec.EXPERIMENT_RECORD_ID\n" +
            "  AND ec.EXP_COND_DUR_SEC_LOW_BOUND > 0\n" +
            "  AND mm.MEASUREMENT_METHOD_ID      = er.MEASUREMENT_METHOD_ID\n" +
            "  \n" +
            "  UNION ALL\n" +
            "  \n" +
            "  SELECT er.EXPERIMENT_RECORD_ID    AS erid,\n" +
            "    er.EXPERIMENT_ID                AS exid,\n" +
            "    ec1.EXP_COND_ONT_ID             AS ecoid,\n" +
            "    ec1.EXP_COND_DUR_SEC_HIGH_BOUND AS dur\n" +
            "  FROM EXPERIMENT_RECORD er,\n" +
            "    EXPERIMENT_CONDITION ec1,\n" +
            "    MEASUREMENT_METHOD mm\n" +
            "  WHERE er.CURATION_STATUS in (35, 40)\n" +
            "  AND er.EXPERIMENT_RECORD_ID       = ec1.EXPERIMENT_RECORD_ID\n" +
            "  AND mm.MEASUREMENT_METHOD_ID      = er.MEASUREMENT_METHOD_ID\n" +
            "  AND ec1.EXP_COND_DUR_SEC_HIGH_BOUND > 0\n" +
            "  ) a\n" +
            "WHERE a.ecoid  = 'XCO:0000022'\n" +
            "AND a.dur      < 60\n" +
            "AND a.exid     = e.EXPERIMENT_ID\n" +
            //"and s.STUDY_ID not in (14,21,22,41,401,527,461,529,717,441,421,526,481,482,381,528,522)\n" +
            "AND e.STUDY_ID = s.STUDY_ID\n" +
            ") b\n" +
            "group by b.ecoid";

        List<String> issues = StringListQuery.execute(adao, sql);
        if( !issues.isEmpty() ) {
            for( String line: issues ) {
                logXCO22Duration.debug(line);
            }
        }
        return issues;
    }

    /// validate table PHENOMINER_TERM_UNIT_SCALES
    public List<String> checkUnitConversionsForNulls() throws Exception {

        String sql =
        "select ONT_ID || '  UNIT_FROM[ ' ||unit_from||' ] UNIT_TO[ '||unit_to||' ]  TERM_SPECIFIC_SCALE[ '||term_specific_scale||' ] ZERO_OFFSET[ '||zero_offset||' ]'\n" +
            "from PHENOMINER_TERM_UNIT_SCALES ptus\n" +
            "where ptus.TERM_SPECIFIC_SCALE is null\n" +
            "or ptus.ZERO_OFFSET is null";

        List<String> issues = StringListQuery.execute(adao, sql);
        if( !issues.isEmpty() ) {
            for( String line: issues ) {
                logNullUnitConversions.debug(line);
            }
        }
        return issues;
    }

    public List<String> checkInvalidRsoUsage() throws Exception {

        String sql =
        "select ot.TERM_ACC||'  '||ot.TERM from ONT_TERMS ot\n" +
            "where ot.TERM_ACC like 'RS:%'\n" +
            "and ot.TERM_ACC not in\n" +
            "(\n" +
            "select os.term_acc from ONT_SYNONYMS os\n" +
            "where os.TERM_ACC like 'RS:%'\n" +
            "and lower(os.SYNONYM_NAME) like 'rgd id%'\n" +
            ")\n" +
            "and ot.IS_OBSOLETE=0\n" +
            "and ot.term_acc in\n" +
            "( \n" +
            "select sa.strain_ont_id from SAMPLE sa, EXPERIMENT_RECORD er\n" +
            "where sa.sample_id = er.sample_id\n" +
            "and er.curation_status <> 50\n" +
            ")\n";

        List<String> issues = StringListQuery.execute(adao, sql);
        if( !issues.isEmpty() ) {
            for( String line: issues ) {
                logInvalidRsoUsage.debug(line);
            }
        }
        return issues;
    }

    public List<StringMapQuery.MapPair> getCmoTermsWithoutStdUnits() throws Exception{
        String sql = "SELECT DISTINCT CLINICAL_MEASUREMENT_ONT_ID AS ont_id, er.MEASUREMENT_UNITS " +
                "FROM CLINICAL_MEASUREMENT cm, EXPERIMENT_RECORD er " +
                "WHERE er.CLINICAL_MEASUREMENT_ID = cm.CLINICAL_MEASUREMENT_ID " +
                "AND cm.CLINICAL_MEASUREMENT_ONT_ID IN ( " +
                "        SELECT ont_id FROM " +
                "            ( SELECT DISTINCT CLINICAL_MEASUREMENT_ONT_ID AS ont_id, er.MEASUREMENT_UNITS" +
                "                FROM CLINICAL_MEASUREMENT cm, EXPERIMENT_RECORD er" +
                "                WHERE er.CLINICAL_MEASUREMENT_ID = cm.CLINICAL_MEASUREMENT_ID AND er.CURATION_STATUS=40" +
                "                 AND cm.CLINICAL_MEASUREMENT_ONT_ID NOT IN (SELECT psu.ont_id FROM PHENOMINER_STANDARD_UNITS psu)" +
                "            ) a" +
                "        GROUP BY a.ont_id\n" +
                "        HAVING COUNT(*) = 1 )";
        return StringMapQuery.execute(adao, sql);
    }

    public boolean insertStandardUnit(String ontId, String stdUnit) throws Exception {
        String sql0 = "SELECT COUNT(*) FROM PHENOMINER_STANDARD_UNITS WHERE ont_id=? AND standard_unit=?";
        int cnt = adao.getCount(sql0, ontId, stdUnit);
        if( cnt!=0 ) {
            return false; // already in table
        }
        String sql = "INSERT INTO PHENOMINER_STANDARD_UNITS (ont_id, standard_unit) VALUES(?,?)";
        logNewStandardUnits.info("new standard unit: "+ontId+" "+stdUnit);
        adao.update(sql, ontId, stdUnit);
        return true;
    }

    public boolean insertUnitScales(String ontId, String stdUnit) throws Exception {
        String sql0 = "SELECT COUNT(*) FROM PHENOMINER_TERM_UNIT_SCALES WHERE ont_id=? AND unit_from=? AND unit_to=? AND term_specific_scale=1 AND zero_offset=0";
        int cnt = adao.getCount(sql0, ontId, stdUnit, stdUnit);
        if( cnt!=0 ) {
            return false; // already in table
        }
        String sql = "INSERT INTO PHENOMINER_TERM_UNIT_SCALES (ont_id, unit_from, unit_to, term_specific_scale, zero_offset) "+
                "VALUES(?, ?, ?, 1, 0)";
        logNewStandardUnits.info("new unit scales:  term:"+ontId+" from:"+stdUnit+" to:"+stdUnit+", term_specific_scale=1, zero_offset=0");
        adao.update(sql, ontId, stdUnit, stdUnit);
        return true;
    }

    public int updatePhenominerTermUnitScales() throws Exception {
        // Update PHENOMINER_TERM_UNIT_SCALES with PHENOMINER_STANDARD_UNITS
        String sql1 = "update PHENOMINER_TERM_UNIT_SCALES tus " +
                "set (tus.UNIT_TO)= (select us.STANDARD_UNIT from PHENOMINER_STANDARD_UNITS us where us.ONT_ID=tus.ONT_ID) " +
                "where (tus.ONT_ID) in" +
                "(select us.ONT_ID from PHENOMINER_STANDARD_UNITS us)";
        int cnt1 = adao.update(sql1);

        // add to PHENOMINER_TERM_UNIT_SCALES for new records in PHENOMINER_UNIT_SCALES
        String sql2 =
                "INSERT INTO PHENOMINER_TERM_UNIT_SCALES " +
                "SELECT UNIQUE CM.CLINICAL_MEASUREMENT_ONT_ID,ER.MEASUREMENT_UNITS,SU.STANDARD_UNIT,US.SCALE,US.ZERO_OFFSET " +
                "FROM EXPERIMENT_RECORD ER, CLINICAL_MEASUREMENT CM,PHENOMINER_STANDARD_UNITS SU, PHENOMINER_UNIT_SCALES US " +
                "WHERE ER.CLINICAL_MEASUREMENT_ID = CM.CLINICAL_MEASUREMENT_ID AND CM.CLINICAL_MEASUREMENT_ONT_ID = SU.ONT_ID "+
                "  AND ER.MEASUREMENT_UNITS = US.UNIT_FROM AND SU.STANDARD_UNIT = US.UNIT_TO " +
                "  AND (ER.MEASUREMENT_UNITS,SU.STANDARD_UNIT) not in (" +
                "      select unit_from, unit_to from phenominer_term_unit_scales tus1 where tus1.ont_id=su.ont_id)";
        int cnt2 = adao.update(sql2);
        return cnt1+cnt2;
    }

    public int getCmoTermsWithoutStandardUnits() throws Exception {
        String sql = "SELECT a.ont_id||' '''||ot.TERM||'''   record_count='||a.record_count " +
                "FROM (" +
                "  SELECT CLINICAL_MEASUREMENT_ONT_ID AS ont_id, COUNT(*) AS record_count" +
                "  FROM CLINICAL_MEASUREMENT cm, EXPERIMENT_RECORD er" +
                "  WHERE er.CLINICAL_MEASUREMENT_ID = cm.CLINICAL_MEASUREMENT_ID" +
                "   AND er.CURATION_STATUS=40" +
                "   AND cm.CLINICAL_MEASUREMENT_ONT_ID NOT IN (SELECT psu.ont_id FROM PHENOMINER_STANDARD_UNITS psu)" +
                "  GROUP BY CLINICAL_MEASUREMENT_ONT_ID) a " +
                "LEFT JOIN ONT_TERMS ot " +
                "ON a.ont_id = ot.TERM_ACC " +
                "ORDER BY a.record_count DESC";

        List<String> issues = StringListQuery.execute(adao, sql);
        for( String line: issues ) {
            logCmoMissingStandardUnits.debug(line);
        }
        return issues.size();
    }
}
