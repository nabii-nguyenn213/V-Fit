package com.vfit.modules.admin.document;

import java.time.Instant;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Document(collection = "visitor_logs")
@CompoundIndexes({
    @CompoundIndex(name = "createdAt_desc", def = "{'createdAt': -1}")
})
public class VisitorLog {
    @Id
    private String id;
    private String ip;
    private String os;
    private String browser;
    private String action;
    private String location;
    
    @Indexed(expireAfter = "90d")
    private Instant createdAt;
}
