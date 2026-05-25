package com.vfit.modules.user.scheduler;

import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class AccountCleanupScheduler {

    private final UserRepository userRepository;

    // Runs at 2 AM every day
    @Scheduled(cron = "0 0 2 * * *")
    public void cleanupDeactivatedAccounts() {
        log.info("Starting deactivated accounts cleanup job...");
        Instant threshold = Instant.now().minus(30, ChronoUnit.DAYS);
        List<User> usersToDelete = userRepository.findByActiveFalseAndDeactivatedAtBefore(threshold);

        if (!usersToDelete.isEmpty()) {
            log.info("Found {} deactivated accounts older than 30 days. Deleting permanently...", usersToDelete.size());
            userRepository.deleteAll(usersToDelete);
            log.info("Deactivated accounts cleanup job completed successfully.");
        } else {
            log.info("No deactivated accounts older than 30 days found.");
        }
    }
}
