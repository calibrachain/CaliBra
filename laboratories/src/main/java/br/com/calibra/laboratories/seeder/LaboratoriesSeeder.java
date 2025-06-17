package br.com.calibra.laboratories.seeder;

import java.io.InputStream;
import java.util.List;
import java.util.Map;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import br.com.calibra.laboratories.entity.CalibrationType;
import br.com.calibra.laboratories.entity.Laboratory;
import br.com.calibra.laboratories.repository.CalibrationTypeRepository;
import br.com.calibra.laboratories.repository.LaboratoryRepository;

@Component
public class LaboratoriesSeeder implements CommandLineRunner {

  private final LaboratoryRepository laboratoryRepository;
  private final CalibrationTypeRepository calibrationTypeRepository;

  private final ObjectMapper objectMapper;

  public LaboratoriesSeeder(LaboratoryRepository laboratoryRepository,
      CalibrationTypeRepository calibrationTypeRepository) {
    this.laboratoryRepository = laboratoryRepository;
    this.calibrationTypeRepository = calibrationTypeRepository;
    this.objectMapper = new ObjectMapper();
  }

  @SuppressWarnings("unchecked")
  @Override
  public void run(String... args) throws Exception {

    System.out.println("========== Checking laboratory data ==========");

    // Check if there are already laboratories in the database
    if (laboratoryRepository.count() > 0) {
      System.out.println("========== Laboratories already seeded. Skipping... ==========");
      return;
    }

    System.out.println("========== Loading laboratory data ==========");

    InputStream input = getClass().getResourceAsStream("/laboratories.json");
    List<Map<String, Object>> labs = objectMapper.readValue(input, new TypeReference<>() {
    });

    for (Map<String, Object> labData : labs) {
      Map<String, String> typeData = (Map<String, String>) labData.get("calibrationType");

      String description = typeData.get("description");

      // Search or create calibration type
      CalibrationType type = calibrationTypeRepository.findByDescription(description)
          .orElseGet(() -> calibrationTypeRepository.save(CalibrationType.builder().description(description).build()));

      Laboratory lab = Laboratory.builder()
          .name(labData.get("name").toString())
          .accreditationNumber(labData.get("accreditationNumber") != null
              ? Integer.parseInt(labData.get("accreditationNumber").toString())
              : null)
          .status(Laboratory.Status.valueOf(labData.get("status").toString()))
          .state(labData.get("state").toString())
          .calibrationType(type)
          .build();

      laboratoryRepository.save(lab);
    }

    System.out.println("========== Laboratory data loaded successfully ==========");
  }

}
