package br.com.calibra.laboratories.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.calibra.laboratories.dto.CalibrationTypeDTO;
import br.com.calibra.laboratories.dto.mapper.LaboratoryMapper;
import br.com.calibra.laboratories.service.CalibrationTypeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/calibration-types")
@RequiredArgsConstructor
public class CalibrationTypeController {

  private final CalibrationTypeService service;
  private final LaboratoryMapper mapper;

  @GetMapping
  public List<CalibrationTypeDTO> findAll() {
    return service.findAll().stream().map(mapper::toDto).toList();
  }

  @PostMapping
  public CalibrationTypeDTO create(@RequestBody @Valid CalibrationTypeDTO dto) {
    return mapper.toDto(service.save(mapper.toEntity(dto)));
  }
}
