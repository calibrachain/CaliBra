package br.com.calibra.laboratories.entity;

import java.util.UUID;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Laboratory {

  @Id
  @GeneratedValue(strategy = GenerationType.AUTO)
  private UUID id;

  private String name;

  private Integer accreditationNumber;

  @Enumerated(EnumType.STRING)
  private Status status;

  private String state;

  @ManyToOne
  @JoinColumn(name = "calibration_type_id", nullable = false)
  private CalibrationType calibrationType;

  public enum Status {
    ACTIVE, INACTIVE
  }

  @Override
  public String toString() {
    return "Laboratory [id=" + id + ", name=" + name + ", accreditationNumber=" + accreditationNumber + ", status="
        + status + ", state=" + state + ", calibrationType=" + calibrationType + "]";
  }

}
