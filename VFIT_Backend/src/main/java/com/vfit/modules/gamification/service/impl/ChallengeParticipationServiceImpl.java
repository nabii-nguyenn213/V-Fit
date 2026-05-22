package com.vfit.modules.gamification.service.impl;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.gamification.document.Challenge;
import com.vfit.modules.gamification.document.UserChallengeParticipation;
import com.vfit.modules.gamification.document.VerifiedPhoto;
import com.vfit.modules.gamification.repository.ChallengeRepository;
import com.vfit.modules.gamification.repository.UserChallengeParticipationRepository;
import com.vfit.modules.gamification.service.ChallengeParticipationService;
import com.vfit.modules.gamification.service.RewardDistributionService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Slf4j
@RequiredArgsConstructor
public class ChallengeParticipationServiceImpl implements ChallengeParticipationService {

    private static final ZoneId ZONE_VN = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final int REVIVE_COST_POINTS = 150;

    private final UserChallengeParticipationRepository participationRepo;
    private final ChallengeRepository challengeRepo;
    private final RewardDistributionService rewardDistributionService;
    private final UserRepository userRepo;

    @Override
    public UserChallengeParticipation joinChallenge(String userId, String challengeId) {
        Challenge challenge = challengeRepo.findById(challengeId)
            .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Thử thách không tồn tại."));

        if (!challenge.isActive()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Thử thách này hiện không còn hoạt động.");
        }

        // Avoid duplicate participation
        Optional<UserChallengeParticipation> existing = participationRepo.findByUserIdAndChallengeId(userId, challengeId);
        if (existing.isPresent()) {
            UserChallengeParticipation current = existing.get();
            if ("IN_PROGRESS".equals(current.getStatus())) {
                return current;
            } else if ("COMPLETED".equals(current.getStatus())) {
                throw new AppException(ErrorCode.BAD_REQUEST, "Bạn đã hoàn thành thử thách này rồi.");
            }
            // If failed, allow them to rejoin by resetting status
            current.setStatus("IN_PROGRESS");
            current.setStartedAt(Instant.now());
            current.setCompletedAt(null);
            current.setCurrentStreak(0);
            current.setMaxStreakAchieved(0);
            current.setLastCheckinDate(null);
            current.setVerifiedPhotos(new ArrayList<>());
            return participationRepo.save(current);
        }

        UserChallengeParticipation participation = UserChallengeParticipation.builder()
            .userId(userId)
            .challengeId(challengeId)
            .status("IN_PROGRESS")
            .startedAt(Instant.now())
            .idempotencyKey("user_challenge_claim:" + userId + ":" + challengeId)
            .verifiedPhotos(new ArrayList<>())
            .build();

        return participationRepo.save(participation);
    }

    @Override
    public void mapPhotoToActiveChallenges(String userId, String photoId, String photoUrl, Instant uploadedAt) {
        List<UserChallengeParticipation> activeParticipations = participationRepo.findByUserIdAndStatus(userId, "IN_PROGRESS");
        if (activeParticipations.isEmpty()) {
            log.info("No active challenges found for user {}", userId);
            return;
        }

        LocalDate uploadDate = uploadedAt.atZone(ZONE_VN).toLocalDate();
        String checkinDateStr = uploadDate.format(DATE_FORMATTER);

        for (UserChallengeParticipation participation : activeParticipations) {
            try {
                Challenge challenge = challengeRepo.findById(participation.getChallengeId()).orElse(null);
                if (challenge == null) continue;

                // 1. Calculate Day Index (Day 1, Day 2, etc.)
                LocalDate startDate = participation.getStartedAt().atZone(ZONE_VN).toLocalDate();
                long daysDiff = ChronoUnit.DAYS.between(startDate, uploadDate);
                int dayIndex = (int) daysDiff + 1;

                // 2. Ensure only 1 photo checkin counts per day
                boolean alreadyCheckedInToday = participation.getVerifiedPhotos().stream()
                    .anyMatch(photo -> checkinDateStr.equals(photo.getCheckinDate()));

                if (alreadyCheckedInToday) {
                    log.info("User {} already checked in today for challenge {}. Skipping.", userId, challenge.getId());
                    continue;
                }

                // 3. Build & append verified photo reference
                VerifiedPhoto verifiedPhoto = VerifiedPhoto.builder()
                    .photoId(photoId)
                    .photoUrl(photoUrl)
                    .uploadedAt(uploadedAt)
                    .checkinDate(checkinDateStr)
                    .challengeDayIndex(dayIndex)
                    .status("VERIFIED")
                    .build();

                participation.getVerifiedPhotos().add(verifiedPhoto);

                // 4. Update Streak Logic
                LocalDate today = uploadDate;
                if (participation.getLastCheckinDate() == null) {
                    participation.setCurrentStreak(1);
                } else {
                    LocalDate lastCheckin = LocalDate.parse(participation.getLastCheckinDate(), DATE_FORMATTER);
                    LocalDate yesterday = today.minusDays(1);
                    
                    if (lastCheckin.equals(yesterday)) {
                        participation.setCurrentStreak(participation.getCurrentStreak() + 1);
                    } else if (lastCheckin.isBefore(yesterday)) {
                        // Streak was broken, but user uploaded a photo now, resetting streak to 1
                        participation.setCurrentStreak(1);
                    }
                }
                participation.setLastCheckinDate(checkinDateStr);
                participation.setMaxStreakAchieved(Math.max(participation.getMaxStreakAchieved(), participation.getCurrentStreak()));

                // 5. Evaluate completion conditions
                boolean isCompleted = false;
                if (challenge.getType() == null) {
                    // Default to simple targeted flexing if not set
                    isCompleted = true;
                } else {
                    switch (challenge.getType()) {
                        case STREAK:
                            if (participation.getCurrentStreak() >= challenge.getDurationDays()) {
                                isCompleted = true;
                            }
                            break;
                        case MILESTONE:
                            List<Integer> completedMilestoneDays = participation.getVerifiedPhotos().stream()
                                .map(VerifiedPhoto::getChallengeDayIndex)
                                .toList();
                            List<Integer> required = challenge.getRequiredPhotoMilestones();
                            if (required != null && completedMilestoneDays.containsAll(required)) {
                                isCompleted = true;
                            }
                            break;
                        case TARGETED:
                            // targeted muscle pump Flexing is immediately completed on first upload
                            isCompleted = true;
                            break;
                    }
                }

                participationRepo.save(participation);
                log.info("Progress photo associated with challenge {} for user {}. Streak: {}", 
                    challenge.getTitle(), userId, participation.getCurrentStreak());

                if (isCompleted) {
                    log.info("Challenge {} completed for user {}. Triggering rewards...", challenge.getId(), userId);
                    rewardDistributionService.distributeRewards(participation.getId());
                }
            } catch (Exception ex) {
                log.error("Error processing challenge mapping for participation {}", participation.getId(), ex);
            }
        }
    }

    @Override
    public UserChallengeParticipation getParticipation(String userId, String challengeId) {
        return participationRepo.findByUserIdAndChallengeId(userId, challengeId)
            .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy thông tin đăng ký thử thách."));
    }

    @Override
    public List<UserChallengeParticipation> getActiveParticipations(String userId) {
        return participationRepo.findByUserIdAndStatusIn(userId, java.util.List.of("IN_PROGRESS", "COMPLETED"));
    }

    @Override
    public UserChallengeParticipation reviveStreak(String userId, String challengeId) {
        UserChallengeParticipation participation = participationRepo.findByUserIdAndChallengeIdAndStatus(userId, challengeId, "IN_PROGRESS")
            .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy thử thách đang diễn ra."));

        User user = userRepo.findById(userId)
            .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Người dùng không tồn tại."));

        User.UserProgress progress = user.getProgress();
        if (progress == null || progress.getXp() < REVIVE_COST_POINTS) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Bạn không đủ điểm thưởng (V-Points) để cứu chuỗi (Yêu cầu 150 V-Points).");
        }

        // Deduct points
        progress.setXp(progress.getXp() - REVIVE_COST_POINTS);
        user.setProgress(progress);
        userRepo.save(user);

        // Restore streak to the max streak previously achieved
        int previousMax = participation.getMaxStreakAchieved();
        participation.setCurrentStreak(Math.max(1, previousMax));
        
        // Mock the last checkin date to yesterday so they can continue today
        LocalDate yesterday = LocalDate.now(ZONE_VN).minusDays(1);
        participation.setLastCheckinDate(yesterday.format(DATE_FORMATTER));
        
        log.info("User {} successfully revived streak in challenge {}. Cost: 150 V-Points.", userId, challengeId);
        return participationRepo.save(participation);
    }
}
