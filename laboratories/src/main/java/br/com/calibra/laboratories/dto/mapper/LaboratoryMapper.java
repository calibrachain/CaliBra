package br.com.calibra.laboratories.dto.mapper;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import br.com.calibra.laboratories.dto.CalibrationTypeDTO;
import br.com.calibra.laboratories.dto.LaboratoryDTO;
import br.com.calibra.laboratories.entity.CalibrationType;
import br.com.calibra.laboratories.entity.Laboratory;

@Component
public class LaboratoryMapper {

  public LaboratoryDTO toDto(Laboratory entity) {
    if (entity == null) {
      return null;
    }

    LaboratoryDTO dto = new LaboratoryDTO();
    dto.setId(entity.getId());
    dto.setName(entity.getName());
    dto.setAccreditationNumber(entity.getAccreditationNumber());
    dto.setStatus(entity.getStatus());
    dto.setState(entity.getState());

    if (entity.getCalibrationType() != null) {
      dto.setCalibrationTypeId(entity.getCalibrationType().getId());
    }

    return dto;
  }

  public Laboratory toEntity(LaboratoryDTO dto) {
    if (dto == null) {
      return null;
    }

    Laboratory entity = new Laboratory();
    entity.setId(dto.getId());
    entity.setName(dto.getName());
    entity.setAccreditationNumber(dto.getAccreditationNumber());
    entity.setStatus(dto.getStatus());
    entity.setState(dto.getState());

    if (dto.getCalibrationTypeId() != null) {
      CalibrationType calibrationType = new CalibrationType();
      calibrationType.setId(dto.getCalibrationTypeId());
      entity.setCalibrationType(calibrationType);
    }

    return entity;
  }

  public CalibrationTypeDTO toDto(CalibrationType type) {
    if (type == null) {
      return null;
    }

    CalibrationTypeDTO dto = new CalibrationTypeDTO();
    dto.setId(type.getId());
    dto.setDescription(type.getDescription());

    return dto;
  }

  public CalibrationType toEntity(CalibrationTypeDTO dto) {
    if (dto == null) {
      return null;
    }

    CalibrationType entity = new CalibrationType();
    entity.setId(dto.getId());
    entity.setDescription(dto.getDescription());

    return entity;
  }

  public List<LaboratoryDTO> toDtoList(List<Laboratory> list) {
    if (list == null) {
      return null;
    }

    return list.stream()
        .map(this::toDto)
        .collect(Collectors.toList());
  }
}
