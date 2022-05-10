package edu.mcw.rgd.pipelines;

import edu.mcw.rgd.dao.AbstractDAO;
import edu.mcw.rgd.dao.DataSourceFactory;
import edu.mcw.rgd.dao.impl.MapDAO;
import edu.mcw.rgd.dao.impl.SampleDAO;
import edu.mcw.rgd.dao.impl.variants.VariantDAO;
import edu.mcw.rgd.dao.spring.StringListQuery;
import edu.mcw.rgd.dao.spring.variants.VariantMapQuery;
import edu.mcw.rgd.dao.spring.variants.VariantSampleQuery;
import edu.mcw.rgd.datamodel.Sample;
import edu.mcw.rgd.datamodel.variants.VariantMapData;
import edu.mcw.rgd.datamodel.variants.VariantSampleDetail;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.jdbc.core.SqlParameter;

import javax.sql.DataSource;
import java.sql.Types;
import java.util.List;
import java.util.Map;

/**
 * Created by mtutaj on 1/14/2021
 * <p>
 * All database code lands here
 */
public class Dao {

    AbstractDAO adao = new AbstractDAO();

    Logger logXCO22Duration = LogManager.getLogger("xco22_duration");

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








    edu.mcw.rgd.dao.impl.variants.VariantDAO variantDAO = new VariantDAO();

    MapDAO mapDAO = new MapDAO();
    public String getConnectionInfo() {
        return variantDAO.getConnectionInfo();
    }

    public DataSource getVariantDataSource() throws Exception {
        return DataSourceFactory.getInstance().getCarpeNovoDataSource();
    }

    public List<VariantMapData> getVariants(int speciesTypeKey, int mapKey, String chr) throws Exception{
        String sql = "SELECT * FROM variant v inner join variant_map_data vm on v.rgd_id = vm. rgd_id WHERE v.species_type_key = ? and vm.map_key = ? and vm.chromosome=?";

        VariantMapQuery q = new VariantMapQuery(getVariantDataSource(), sql);
        q.declareParameter(new SqlParameter(Types.INTEGER));
        q.declareParameter(new SqlParameter(Types.INTEGER));
        q.declareParameter(new SqlParameter(Types.VARCHAR));
        return q.execute(speciesTypeKey, mapKey, chr);
    }

    public List<VariantSampleDetail> getSampleIds(int mapKey, String chr) throws Exception{
        String sql = "select vs.* from variant_sample_detail vs inner join variant_map_data vm on vm.rgd_id = vs.rgd_id and vm.map_key=? and vm.chromosome = ?";
        VariantSampleQuery q = new VariantSampleQuery(this.getVariantDataSource(), sql);
        q.declareParameter(new SqlParameter(Types.INTEGER));
        q.declareParameter(new SqlParameter(Types.VARCHAR));
        return q.execute(mapKey, chr);
    }
    public List<String> getChromosomes(int mapKey) throws Exception {

        String sql = "SELECT DISTINCT chromosome FROM chromosomes WHERE map_key=? ";
        StringListQuery q = new StringListQuery(adao.getDataSource(), sql);
        q.declareParameter(new SqlParameter(Types.INTEGER));
        q.compile();
        return q.execute(new Object[]{mapKey});
    }
    public Sample getSample(int id) throws Exception{
        SampleDAO sampleDAO = new SampleDAO();
        sampleDAO.setDataSource(this.getVariantDataSource());
        return sampleDAO.getSample(id);
    }
    public int getSpeciesFromMap(int mapKey) throws Exception{

        return mapDAO.getSpeciesTypeKeyForMap(mapKey);
    }

    public Map<String,Integer> getChromosomeSizes(int mapKey) throws Exception{
        return mapDAO.getChromosomeSizes(mapKey);
    }
}
