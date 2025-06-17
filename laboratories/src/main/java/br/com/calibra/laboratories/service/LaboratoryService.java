package br.com.calibra.laboratories.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Service;

import br.com.calibra.laboratories.entity.Laboratory;
import br.com.calibra.laboratories.repository.LaboratoryRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class LaboratoryService {
  private final LaboratoryRepository repository;

  public List<Laboratory> findAll() {
    return repository.findAll();
  }

  public Optional<Laboratory> findById(UUID id) {
    return repository.findById(id);
  }

  public Optional<Laboratory> findByAccreditationNumber(Integer accreditationNumber) {
    return repository.findByAccreditationNumber(accreditationNumber);
  }

  public Laboratory save(Laboratory lab) {
    return repository.save(lab);
  }

  public void deleteById(UUID id) {
    repository.deleteById(id);
  }

  public void deleteByAccreditationNumber(Integer accreditationNumber) {
    repository.deleteByAccreditationNumber(accreditationNumber);
  }

  public Optional<Laboratory> updateStatus(Integer accreditationNumber, Laboratory.Status newStatus) {
    Optional<Laboratory> laboratoryOpt = repository.findByAccreditationNumber(accreditationNumber);

    if (laboratoryOpt.isPresent()) {
      Laboratory laboratory = laboratoryOpt.get();
      laboratory.setStatus(newStatus);
      return Optional.of(repository.save(laboratory));
    }

    return Optional.empty();
  }
}