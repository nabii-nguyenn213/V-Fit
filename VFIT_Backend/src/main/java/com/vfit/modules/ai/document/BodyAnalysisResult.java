package com.vfit.modules.ai.document;

import java.time.Instant;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "body_analysis_results")
public class BodyAnalysisResult {
    @Id
    private String id;
    @Indexed
    private String userId;
    private String imageUrl;
    private Map<String, Object> metadata;
    private Map<String, Object> posture;
    private Map<String, Object> imbalance;
    private Map<String, Object> estimate;
    private Map<String, Object> recommendation;
    private Map<String, Object> result;
    @CreatedDate
    private Instant createdAt;
}
