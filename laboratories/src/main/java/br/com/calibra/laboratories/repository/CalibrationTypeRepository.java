package br.com.calibra.laboratories.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import br.com.calibra.laboratories.entity.CalibrationType;

public interface CalibrationTypeRepository extends JpaRepository<CalibrationType, UUID> {

}
