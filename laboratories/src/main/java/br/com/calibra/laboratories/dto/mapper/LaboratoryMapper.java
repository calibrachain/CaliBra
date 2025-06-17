package br.com.calibra.laboratories.dto.mapper;

import java.util.List;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import br.com.calibra.laboratories.dto.CalibrationTypeDTO;
import br.com.calibra.laboratories.dto.LaboratoryDTO;
import br.com.calibra.laboratories.entity.CalibrationType;
import br.com.calibra.laboratories.entity.Laboratory;
@Mapper(componentModel = "spring")
public interface LaboratoryMapper {

  @Mapping(target = "calibrationTypeId", source = "calibrationType.id")
  LaboratoryDTO toDto(Laboratory entity);

  @Mapping(target = "calibrationType.id", source = "calibrationTypeId")
  Laboratory toEntity(LaboratoryDTO dto);

  CalibrationTypeDTO toDto(CalibrationType type);

  CalibrationType toEntity(CalibrationTypeDTO dto);

  List<LaboratoryDTO> toDtoList(List<Laboratory> list);

}
