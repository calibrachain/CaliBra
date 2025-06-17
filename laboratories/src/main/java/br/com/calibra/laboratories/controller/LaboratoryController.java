package br.com.calibra.laboratories.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import br.com.calibra.laboratories.dto.LaboratoryDTO;
import br.com.calibra.laboratories.dto.mapper.LaboratoryMapper;
import br.com.calibra.laboratories.entity.CalibrationType;
import br.com.calibra.laboratories.entity.Laboratory;
import br.com.calibra.laboratories.repository.CalibrationTypeRepository;
import br.com.calibra.laboratories.service.LaboratoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/laboratories")
@RequiredArgsConstructor
public class LaboratoryController {

  private final LaboratoryService service;
  private final LaboratoryMapper mapper;
  private final CalibrationTypeRepository calibrationTypeRepository;

  @GetMapping("/{accreditationNumber}")
  public ResponseEntity<LaboratoryDTO> findByAccreditationNumber(@PathVariable Integer accreditationNumber) {
    return service.findByAccreditationNumber(accreditationNumber)
        .map(mapper::toDto)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.notFound().build());
  }

  @PostMapping
  public LaboratoryDTO create(@RequestBody @Valid LaboratoryDTO dto) {
    CalibrationType calibrationType = calibrationTypeRepository
        .findById(dto.getCalibrationTypeId())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Calibration Type not found"));

    Laboratory lab = Laboratory.builder()
        .name(dto.getName())
        .accreditationNumber(dto.getAccreditationNumber())
        .status(dto.getStatus())
        .state(dto.getState())
        .calibrationType(calibrationType)
        .build();

    return mapper.toDto(service.save(lab));
  }

  @DeleteMapping("/{accreditationNumber}")
  public ResponseEntity<Void> delete(@PathVariable Integer accreditationNumber) {
    service.deleteByAccreditationNumber(accreditationNumber);
    return ResponseEntity.noContent().build();
  }

  @PatchMapping("/{accreditationNumber}/status/{status}")
  public ResponseEntity<LaboratoryDTO> updateStatus(
      @PathVariable Integer accreditationNumber,
      @PathVariable Laboratory.Status status) {

    return service.updateStatus(accreditationNumber, status)
        .map(mapper::toDto)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.notFound().build());
  }

  @GetMapping("/{accreditationNumber}/status")
  public ResponseEntity<Laboratory.Status> getStatus(@PathVariable Integer accreditationNumber) {
    return service.findByAccreditationNumber(accreditationNumber)
        .map(Laboratory::getStatus)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.notFound().build());
  }

  @GetMapping
  public List<LaboratoryDTO> list() {
    return mapper.toDtoList(service.findAll());
  }
}