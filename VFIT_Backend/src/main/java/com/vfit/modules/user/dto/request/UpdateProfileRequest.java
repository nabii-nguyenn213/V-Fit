package com.vfit.modules.user.dto.request;

import com.vfit.common.enums.Gender;
import com.vfit.common.enums.GoalType;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateProfileRequest {
    @Size(max = 120)
    private String fullName;
    private String avatarUrl;
    private Gender gender;
    private LocalDate dateOfBirth;
    private GoalType goalType;
    @DecimalMin("80.0")
    @DecimalMax("250.0")
    private Double heightCm;
    @DecimalMin("20.0")
    @DecimalMax("300.0")
    private Double weightKg;
    @DecimalMin("1.0")
    @DecimalMax("70.0")
    private Double bodyFatPercent;
}
