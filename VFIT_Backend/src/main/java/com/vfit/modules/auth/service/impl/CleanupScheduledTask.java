package com.vfit.modules.auth.service.impl;

import com.vfit.modules.user.repository.UserRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class CleanupScheduledTask {
    private final UserRepository userRepository;

    // Run every 5 minutes
    @Scheduled(fixedDelay = 300000)
    public void cleanupInactiveUsers() {
        log.info("Starting cleanup of inactive user accounts older than 30 minutes...");
        try {
            Instant threshold = Instant.now().minus(30, ChronoUnit.MINUTES);
            userRepository.deleteByActiveFalseAndCreatedAtBefore(threshold);
            log.info("Completed cleanup of inactive user accounts.");
        } catch (Exception e) {
            log.error("Error occurred during inactive user cleanup", e);
        }
    }
}
