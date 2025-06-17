package br.com.calibra.laboratories.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import br.com.calibra.laboratories.entity.Laboratory;

public interface LaboratoryRepository extends JpaRepository<Laboratory, UUID> {

  Optional<Laboratory> findByAccreditationNumber(Integer accreditationNumber);

  void deleteByAccreditationNumber(Integer accreditationNumber);

}
