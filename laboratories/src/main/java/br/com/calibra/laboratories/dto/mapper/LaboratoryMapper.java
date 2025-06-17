package br.com.calibra.laboratories.dto.mapper;

import java.util.List;

import org.mapstruct.Mapper;

import br.com.calibra.laboratories.dto.CalibrationTypeDTO;
import br.com.calibra.laboratories.dto.LaboratoryDTO;
import br.com.calibra.laboratories.entity.CalibrationType;
import br.com.calibra.laboratories.entity.Laboratory;

@Mapper(componentModel = "spring")
public interface LaboratoryMapper {

  LaboratoryDTO toDto(Laboratory entity);

  Laboratory toEntity(LaboratoryDTO dto);

  CalibrationTypeDTO toDto(CalibrationType type);

  CalibrationType toEntity(CalibrationTypeDTO dto);

  List<LaboratoryDTO> toDtoList(List<Laboratory> list);

}
