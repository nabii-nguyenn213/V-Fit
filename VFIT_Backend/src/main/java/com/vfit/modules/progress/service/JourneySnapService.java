package com.vfit.modules.progress.service;

import com.vfit.common.api.PageResponse;
import com.vfit.modules.progress.dto.response.JourneySnapResponse;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

public interface JourneySnapService {
    JourneySnapResponse uploadSnap(String userId, MultipartFile file, String note);
    PageResponse<JourneySnapResponse> getSnaps(String userId, Pageable pageable);
    void deleteSnap(String userId, String snapId);
}
