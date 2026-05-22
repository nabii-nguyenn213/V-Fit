package com.vfit.modules.gamification.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "challenges")
public class Challenge {
    @Id
    private String id;
    private String title;
    private String description;
    
    // Existing fields kept for backward compatibility
    private int targetValue;
    private int xpReward;
    private String badgeName;
    
    @Builder.Default
    private boolean active = true;

    // Advanced Event-Driven Gamification Fields
    private ChallengeType type;
    private int durationDays;
    private ChallengeReward rewards;
    private List<Integer> requiredPhotoMilestones;
}
