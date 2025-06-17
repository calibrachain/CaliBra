package br.com.calibra.laboratories.service;

import java.util.List;

import org.springframework.stereotype.Service;

import br.com.calibra.laboratories.entity.CalibrationType;
import br.com.calibra.laboratories.repository.CalibrationTypeRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CalibrationTypeService {
  
  private final CalibrationTypeRepository repository;

  public List<CalibrationType> findAll() {
    return repository.findAll();
  }

  public CalibrationType save(CalibrationType type) {
    return repository.save(type);
  }
}