package com.vfit.modules.ai.service;

import com.vfit.modules.ai.dto.response.FoodCalorieEstimateResponse;
import org.springframework.web.multipart.MultipartFile;

public interface AiFoodCalorieService {
    FoodCalorieEstimateResponse estimate(MultipartFile image);
}
