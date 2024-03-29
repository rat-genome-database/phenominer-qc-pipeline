package edu.mcw.rgd.pipelines;

import edu.mcw.rgd.dao.spring.StringMapQuery;
import edu.mcw.rgd.process.Utils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.beans.factory.xml.XmlBeanDefinitionReader;
import org.springframework.core.io.FileSystemResource;

import java.text.SimpleDateFormat;
import java.util.*;

/**
 * @author mtutaj
 * @since May 10, 2022
 */
public class PhenominerQC {

    private String version;

    Logger log = LogManager.getLogger("status");

    public static void main(String[] args) throws Exception {

        DefaultListableBeanFactory bf = new DefaultListableBeanFactory();
        new XmlBeanDefinitionReader(bf).loadBeanDefinitions(new FileSystemResource("properties/AppConfigure.xml"));
        PhenominerQC manager = (PhenominerQC) (bf.getBean("manager"));

        try {
            manager.run();
        } catch(Exception e) {
            Utils.printStackTrace(e, manager.log);
            throw e;
        }
    }

    public void run() throws Exception {

        long time0 = System.currentTimeMillis();

        log.info(getVersion());

        SimpleDateFormat sdt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        log.info("   started at "+sdt.format(time0));

        Dao dao = new Dao();

        // run queries
        List<String> issues = dao.checkXCO22Duration();
        log.info("XCO:0000022 records with duration less than 1 minute:   "+issues.size());

        issues = dao.checkUnitConversionsForNulls();
        log.info("unit conversions with nulls:   "+issues.size());

        issues = dao.checkInvalidRsoUsage();
        log.info("invalid RSO usages:   "+issues.size());

        addStandardUnitsBasedOnExistingRecords(dao);

        int cnt = dao.getCmoTermsWithoutStandardUnits();
        log.info("CMO terms without standard units: "+cnt);

        cnt = dao.getUndefinedUnitConversions();
        log.info("undefined unit conversions: "+cnt);

        dao.updateSemSdNoa();

        String msg = "=== OK === elapsed "+ Utils.formatElapsedTime(time0, System.currentTimeMillis());
        log.info(msg);
    }

    void addStandardUnitsBasedOnExistingRecords(Dao dao) throws Exception {

        int stdUnitsInserted = 0;
        int unitScalesInserted = 0;
        List<StringMapQuery.MapPair> cmoTermsWithoutStdUnits = dao.getCmoTermsWithoutStdUnits();
        for( StringMapQuery.MapPair pair: cmoTermsWithoutStdUnits ) {

            String cmoId = pair.keyValue;
            String unit = pair.stringValue;
            if( dao.insertUnitScales(cmoId, unit) ) {
                unitScalesInserted++;
            }
            if( dao.insertStandardUnit(cmoId, unit) ) {
                stdUnitsInserted++;
            }
        }
        log.info("potential new standard units: "+cmoTermsWithoutStdUnits.size());
        log.info("   new standard units inserted: "+stdUnitsInserted);
        log.info("   new unit scales inserted: "+unitScalesInserted);

        // Update and insert records for common unit conversions
        int cnt = dao.updatePhenominerTermUnitScales();
        log.info("PHENOMINER_TERM_UNIT_SCALES updated: "+cnt +" rows");
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getVersion() {
        return version;
    }
}
