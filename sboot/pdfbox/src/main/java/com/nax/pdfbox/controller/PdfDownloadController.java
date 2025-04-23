package com.nax.pdfbox.controller;


import com.nax.pdfbox.utils.FileGenerator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.pdfbox.cos.COSString;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDAnnotationWidget;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDField;
import org.apache.pdfbox.pdmodel.interactive.form.PDTextField;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;

@RestController
@RequestMapping("/api/download")
public class PdfDownloadController {

    File file = new File("");

    @GetMapping("pdf")
    public ResponseEntity<byte[]> downloadPdf() throws IOException {
        byte[] pdfBytes = FileGenerator.createPdf(getClass().getResourceAsStream("/doc/退休审批.pdf"));
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDisposition(
                ContentDisposition.attachment()
                        .filename("filled_form.pdf") // 设置下载文件名
                        .build()
        );

        // 3. 返回字节流与头信息
        return new ResponseEntity<byte[]>(pdfBytes, headers, HttpStatus.OK);
    }

    @GetMapping("pdf2")
    public void downloadPdf2(HttpServletRequest request, HttpServletResponse response) throws IOException {
        byte[] pdfBytes = FileGenerator.createPdf(getClass().getResourceAsStream("/doc/退休审批.pdf"));
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\""
                + "ceshi.pdf" + "\"");
        response.setHeader("Content-Length", String.valueOf(pdfBytes.length));
        OutputStream outputStream = response.getOutputStream();
        outputStream.write(pdfBytes);
        outputStream.flush();
    }

}