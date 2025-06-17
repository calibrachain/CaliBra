package br.com.calibra.laboratories.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class OpenApiConfig {

  @Bean
  public OpenAPI calibraOpenAPI() {
    return new OpenAPI()
        .info(new Info()
          .title("Calibra - Laboratories API")
          .description("API for managing laboratories accredited by the Brazilian Calibration Network")
          .version("1.0.0")
        );
  }
}
