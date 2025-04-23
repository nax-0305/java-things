package com.nax.pdfbox;

import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDField;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import java.io.File;
import java.io.IOException;
import java.util.logging.Logger;

//@Slf4j
//@SpringBootTest
class PdfboxApplicationTests {

//    Logger logger = Logger.getLogger("com.nax.pdfbox");

//    @Test
//    void contextLoads() {
//    }

    @Test
    public void testDownloadPdf() throws IOException {
        File file = new File("src/main/resources/doc/退休审批.pdf");
        try (PDDocument document = PDDocument.load(file)) {
            PDAcroForm acroForm = document.getDocumentCatalog().getAcroForm();
            for (PDField pdField : acroForm.getFields()) {
                System.out.println(pdField.getFieldType());
                System.out.println(pdField.getFullyQualifiedName());
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
