package com.nax.pdfbox;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class})
public class PdfboxApplication {

    public static void main(String[] args) {
        SpringApplication.run(PdfboxApplication.class, args);
    }

}
