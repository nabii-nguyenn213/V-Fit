package com.vfit.modules.progress.mapper;

import com.vfit.modules.progress.document.JourneySnap;
import com.vfit.modules.progress.dto.response.JourneySnapResponse;
import org.springframework.stereotype.Component;

@Component
public class JourneySnapMapper {
    public JourneySnapResponse toResponse(JourneySnap snap, String baseUrl) {
        String fullUrl = snap.getPhotoUrl();
        if (fullUrl != null && !fullUrl.startsWith("http")) {
            fullUrl = baseUrl + "/uploads/" + fullUrl;
        }
        return JourneySnapResponse.builder()
                .id(snap.getId())
                .photoUrl(fullUrl)
                .note(snap.getNote())
                .createdAt(snap.getCreatedAt())
                .build();
    }
}
