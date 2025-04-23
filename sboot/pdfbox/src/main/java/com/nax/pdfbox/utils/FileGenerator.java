package com.nax.pdfbox.utils;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDAnnotationWidget;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDField;
import org.apache.pdfbox.pdmodel.interactive.form.PDTextField;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class FileGenerator {

    public static byte[] createPdf(InputStream stream) throws IOException {
        PDDocument document = PDDocument.load(stream);
        PDAcroForm acroForm = document.getDocumentCatalog().getAcroForm();
        for(PDField pdField : acroForm.getFields()) {
            PDTextField pdTextField = (PDTextField) pdField;
            pdTextField.setValue("你好123\'fa");  // 0 g代表黑色
            pdTextField.setReadOnly(true);
            // 3. 移除字段边框与填充色
            PDAnnotationWidget widget = pdTextField.getWidgets().get(0);
            widget.setBorderStyle(null);    // 清除边框色
            widget.setAppearance(null); // 清除背景色

        }
        acroForm.flatten();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        document.save(baos);
        document.close();
        return baos.toByteArray();
    }
}
