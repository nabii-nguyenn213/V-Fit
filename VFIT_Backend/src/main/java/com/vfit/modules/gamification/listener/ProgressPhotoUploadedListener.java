package com.vfit.modules.gamification.listener;

import com.vfit.modules.gamification.service.ChallengeParticipationService;
import com.vfit.modules.progress.event.ProgressPhotoUploadedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
@Slf4j
@RequiredArgsConstructor
public class ProgressPhotoUploadedListener {

    private final ChallengeParticipationService participationService;

    @Async // Runs asynchronously in background to ensure zero latency impact on legacy photo uploads
    @EventListener
    public void handleProgressPhotoUploaded(ProgressPhotoUploadedEvent event) {
        log.info("Domain Event captured: Progress photo uploaded for user {}, photo ID: {}", 
            event.getUserId(), event.getPhotoId());
        try {
            participationService.mapPhotoToActiveChallenges(
                event.getUserId(), 
                event.getPhotoId(), 
                event.getPhotoUrl(), 
                event.getUploadedAt()
            );
        } catch (Exception ex) {
            log.error("Failed to map progress photo to challenges for user: {}", event.getUserId(), ex);
        }
    }
}
