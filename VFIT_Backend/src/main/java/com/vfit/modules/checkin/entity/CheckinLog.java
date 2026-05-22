package com.vfit.modules.checkin.entity;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "checkin_logs")
@CompoundIndex(name = "ux_checkin_user_date", def = "{'user_id': 1, 'checkin_date': 1}", unique = true)
public class CheckinLog {
    @Id
    private String id;

    @Indexed
    @Field("user_id")
    private String userId;

    @Field("checkin_date")
    private String checkinDate;

    @Indexed
    @Field("month_key")
    private String monthKey;

    @CreatedDate
    @Field("created_at")
    private Instant createdAt;
}
