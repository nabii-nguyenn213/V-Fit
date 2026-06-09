package com.vfit.modules.ai.service.impl;

import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiFoodCalorieEstimate;
import com.vfit.modules.ai.dto.response.FoodCalorieEstimateResponse;
import com.vfit.modules.ai.mapper.AiResultMapper;
import com.vfit.modules.ai.service.AiFoodCalorieService;
import java.io.IOException;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class AiFoodCalorieServiceImpl implements AiFoodCalorieService {
    private final AiClient aiClient;
    private final AiResultMapper aiResultMapper;

    @Override
    public FoodCalorieEstimateResponse estimate(MultipartFile image) {
        String fileName = image == null || image.getOriginalFilename() == null
                ? "camera-preview"
                : image.getOriginalFilename();
        String contentType = image == null || image.getContentType() == null
                ? "unknown"
                : image.getContentType();
        Map<String, Object> metadata = Map.of(
                "source", "camera",
                "fileName", fileName,
                "contentType", contentType,
                "sizeBytes", image == null ? 0L : image.getSize());

        AiFoodCalorieEstimate result =
                aiClient.estimateFoodCalories(fileName, readImageBytes(image), metadata);
        return aiResultMapper.toFoodCalorieEstimateResponse(result);
    }

    private byte[] readImageBytes(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            return new byte[0];
        }
        try {
            return image.getBytes();
        } catch (IOException e) {
            return new byte[0];
        }
    }
}
