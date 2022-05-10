package edu.mcw.rgd.pipelines;

import edu.mcw.rgd.process.Utils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.beans.factory.xml.XmlBeanDefinitionReader;
import org.springframework.core.io.FileSystemResource;

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

        Dao dao = new Dao();

        // run queries
        List<String> multipleCMOAnnots = dao.getMultipleCMOAnnotations();
        log.info("QTLs with multiple CMO annotations: "+multipleCMOAnnots.size());

        List<String> multipleVTAnnots = dao.getMultipleVTAnnotations();
        log.info("QTLs with multiple VT annotations: "+multipleVTAnnots.size());

        String msg = "=== OK === elapsed "+ Utils.formatElapsedTime(time0, System.currentTimeMillis());
        log.info(msg);
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getVersion() {
        return version;
    }
}
