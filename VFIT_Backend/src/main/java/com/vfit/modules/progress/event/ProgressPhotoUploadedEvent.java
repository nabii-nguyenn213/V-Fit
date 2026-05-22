package com.vfit.modules.progress.event;

import java.time.Instant;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class ProgressPhotoUploadedEvent extends ApplicationEvent {
    private final String userId;
    private final String photoId;
    private final String photoUrl;
    private final Instant uploadedAt;

    public ProgressPhotoUploadedEvent(Object source, String userId, String photoId, String photoUrl, Instant uploadedAt) {
        super(source);
        this.userId = userId;
        this.photoId = photoId;
        this.photoUrl = photoUrl;
        this.uploadedAt = uploadedAt;
    }
}
