package br.com.calibra.laboratories.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import br.com.calibra.laboratories.entity.CalibrationType;

public interface CalibrationTypeRepository extends JpaRepository<CalibrationType, UUID> {

  Optional<CalibrationType> findByDescription(String description);

}
