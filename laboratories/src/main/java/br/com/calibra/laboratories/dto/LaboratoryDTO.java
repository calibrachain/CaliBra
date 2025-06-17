package br.com.calibra.laboratories.dto;

import java.util.UUID;

import br.com.calibra.laboratories.entity.Laboratory.Status;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LaboratoryDTO {

  private UUID id;

  @NotBlank(message = "Name must not be blank")
  private String name;

  @NotNull(message = "Accreditation number must be provided")
  private Integer accreditationNumber;

  @NotNull(message = "Status must be provided")
  private Status status;

  @NotBlank(message = "State must not be blank")
  private String state;

  @NotNull(message = "Calibration type must be provided")
  private UUID calibrationTypeId;
}