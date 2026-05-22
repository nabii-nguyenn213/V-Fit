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
@Document(collection = "form_check_results")
public class FormCheckResult {
    @Id
    private String id;
    @Indexed
    private String userId;
    private String videoUrl;
    private Map<String, Object> metadata;
    private Map<String, Object> result;
    @CreatedDate
    private Instant createdAt;
}
