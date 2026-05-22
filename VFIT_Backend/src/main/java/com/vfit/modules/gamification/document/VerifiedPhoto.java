package com.vfit.modules.gamification.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifiedPhoto {
    private String photoId;
    private String photoUrl;
    private Instant uploadedAt;
    private String checkinDate; // Format YYYY-MM-DD
    private int challengeDayIndex;
    @Builder.Default
    private String status = "VERIFIED";
}
