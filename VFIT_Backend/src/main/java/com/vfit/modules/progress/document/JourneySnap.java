package com.vfit.modules.progress.document;

import java.time.Instant;
import lombok.Builder;
import lombok.Data;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Builder
@Document(collection = "journey_snaps")
public class JourneySnap {
    @Id
    private String id;

    @Indexed
    private String userId;

    private String photoUrl;
    
    private String note;

    @CreatedDate
    private Instant createdAt;
}
