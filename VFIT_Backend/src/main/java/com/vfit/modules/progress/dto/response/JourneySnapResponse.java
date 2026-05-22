package com.vfit.modules.progress.dto.response;

import java.time.Instant;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class JourneySnapResponse {
    private String id;
    private String photoUrl;
    private String note;
    private Instant createdAt;
}
