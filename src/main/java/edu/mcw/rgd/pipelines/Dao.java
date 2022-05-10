package edu.mcw.rgd.pipelines;

import edu.mcw.rgd.dao.AbstractDAO;
import edu.mcw.rgd.dao.DataSourceFactory;
import edu.mcw.rgd.dao.impl.MapDAO;
import edu.mcw.rgd.dao.impl.SampleDAO;
import edu.mcw.rgd.dao.impl.variants.VariantDAO;
import edu.mcw.rgd.dao.spring.IntListQuery;
import edu.mcw.rgd.dao.spring.StringListQuery;
import edu.mcw.rgd.dao.spring.variants.VariantMapQuery;
import edu.mcw.rgd.dao.spring.variants.VariantSampleQuery;
import edu.mcw.rgd.dao.spring.variants.VariantTranscriptQuery;
import edu.mcw.rgd.datamodel.Sample;
import edu.mcw.rgd.datamodel.variants.VariantMapData;
import edu.mcw.rgd.datamodel.variants.VariantSampleDetail;
import edu.mcw.rgd.datamodel.variants.VariantTranscript;
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

    Logger logMultiCMO = LogManager.getLogger("multi_cmo");
    Logger logMultiVT = LogManager.getLogger("multi_vt");

    static final String HEADER = "RGD_ID\tQTL_SYMBOL\tCOUNT\tTERMS\tONTOLOGY_IDS";

    public List<String> getMultipleCMOAnnotations() throws Exception {

        String sql =
                "SELECT q.rgd_id || CHR(9) || qtl_symbol || CHR(9) || COUNT(*) || CHR(9) ||"+
                        "  LISTAGG(ot.term, ',') WITHIN GROUP (ORDER BY ot.term) || CHR(9) ||"+
                        "  LISTAGG(fa.term_acc, ',') WITHIN GROUP (ORDER BY fa.term_acc) "+
                        "FROM full_annot fa, qtls q, ont_terms ot "+
                        "WHERE fa.ANNOTATED_OBJECT_RGD_ID = q.RGD_ID"+
                        "  AND fa.TERM_ACC like 'CMO:%'"+
                        "  AND fa.TERM_ACC = ot.TERM_ACC "+
                        "GROUP BY q.rgd_id, qtl_symbol HAVING COUNT(*) > 1";

        List<String> multis = StringListQuery.execute(adao, sql);
        if( !multis.isEmpty() ) {
            logMultiCMO.debug(HEADER);
            for( String line: multis ) {
                logMultiCMO.debug(line);
            }
        }
        return multis;
    }

    public List<String> getMultipleVTAnnotations() throws Exception {

        String sql =
        "SELECT q.rgd_id || CHR(9) || qtl_symbol || CHR(9) || COUNT(*) || CHR(9) ||"+
        "  LISTAGG(ot.term, ',') WITHIN GROUP (ORDER BY ot.term) || CHR(9) ||"+
        "  LISTAGG(fa.term_acc, ',') WITHIN GROUP (ORDER BY fa.term_acc) "+
        "FROM full_annot fa, qtls q, ont_terms ot "+
        "WHERE fa.ANNOTATED_OBJECT_RGD_ID = q.RGD_ID"+
        "  AND fa.TERM_ACC like 'VT:%'"+
        "  AND fa.TERM_ACC = ot.TERM_ACC "+
        "GROUP BY q.rgd_id, qtl_symbol HAVING COUNT(*) > 1";

        List<String> multis = StringListQuery.execute(adao, sql);
        if( !multis.isEmpty() ) {
            logMultiVT.debug(HEADER);
            for( String line: multis ) {
                logMultiVT.debug(line);
            }
        }
        return multis;
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

    public List<VariantTranscript> getVariantTranscripts(int mapKey, String chr) throws Exception{
        String sql = "select vt.* from variant_transcript vt inner join  variant_map_data v on v.rgd_id=vt.variant_rgd_id AND v.map_key=? AND v.chromosome=?";
        return this.executeVarTranscriptQuery(sql, mapKey, chr);
    }
    public List<VariantTranscript> getVariantTranscripts(int rgdId) throws Exception{
        String sql = "select * from variant_transcript where variant_rgd_id = ?";
        return this.executeVarTranscriptQuery(sql, rgdId);
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

    public List<VariantMapData> executeVariantQuery(String query, Object... params) throws Exception {
        VariantMapQuery q = new VariantMapQuery(getVariantDataSource(), query);
        return q.execute(params);
    }

    public List<VariantTranscript> executeVarTranscriptQuery(String query, Object... params) throws Exception {
        //return VariantTranscriptQuery.execute(variantDAO, query, params);
        VariantTranscriptQuery q = new VariantTranscriptQuery(getVariantDataSource(), query);
        return q.execute(params);
    }
}
