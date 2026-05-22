package com.vfit.modules.gamification.service.impl;

import com.vfit.modules.gamification.document.Challenge;
import com.vfit.modules.gamification.document.UserChallengeParticipation;
import com.vfit.modules.gamification.repository.ChallengeRepository;
import com.vfit.modules.gamification.repository.UserChallengeParticipationRepository;
import com.vfit.modules.gamification.service.RewardDistributionService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.checkin.entity.UserVoucher;
import com.vfit.modules.checkin.entity.UserVoucherStatus;
import com.vfit.modules.checkin.repository.UserVoucherRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.UUID;

@Service
@Slf4j
@RequiredArgsConstructor
public class RewardDistributionServiceImpl implements RewardDistributionService {

    private final UserChallengeParticipationRepository participationRepo;
    private final ChallengeRepository challengeRepo;
    private final UserRepository userRepo;
    private final UserVoucherRepository voucherRepo;
    private final StringRedisTemplate redisTemplate;

    @Override
    @Transactional // Ensures transactional safety across multiple collections
    public void distributeRewards(String participationId) {
        UserChallengeParticipation participation = participationRepo.findById(participationId)
            .orElseThrow(() -> new IllegalArgumentException("Participation record not found: " + participationId));

        if (!"IN_PROGRESS".equals(participation.getStatus())) {
            log.warn("Participation {} is already in status: {}", participationId, participation.getStatus());
            return;
        }

        // Enforce Redis Lock for Idempotency
        String lockKey = "vfit:lock:claim:" + participation.getIdempotencyKey();
        Boolean acquired = redisTemplate.opsForValue().setIfAbsent(lockKey, "PROCESSING", Duration.ofSeconds(10));
        if (Boolean.FALSE.equals(acquired)) {
            throw new IllegalStateException("Transaction is already being processed for this challenge.");
        }

        try {
            Challenge challenge = challengeRepo.findById(participation.getChallengeId())
                .orElseThrow(() -> new IllegalArgumentException("Challenge rule not found: " + participation.getChallengeId()));

            // 1. Mark status as completed
            participation.setStatus("COMPLETED");
            participation.setCompletedAt(Instant.now());
            participationRepo.save(participation);

            // 2. Fetch User Profile
            User user = userRepo.findById(participation.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + participation.getUserId()));

            // 3. Grant XP Points & Increment stats
            User.UserProgress progress = user.getProgress();
            if (progress == null) {
                progress = User.UserProgress.initial();
            }
            int rewardPoints = challenge.getRewards() != null ? challenge.getRewards().getPoints() : challenge.getXpReward();
            progress.setXp(progress.getXp() + rewardPoints);
            progress.setCompletedChallenges(progress.getCompletedChallenges() + 1);
            user.setProgress(progress);

            // 4. Grant Virtual Badge if present
            String rewardBadgeId = challenge.getRewards() != null ? challenge.getRewards().getBadgeId() : challenge.getBadgeName();
            if (rewardBadgeId != null && !rewardBadgeId.isEmpty()) {
                if (user.getBadges() == null) {
                    user.setBadges(new ArrayList<>());
                }
                boolean alreadyHas = user.getBadges().stream().anyMatch(b -> rewardBadgeId.equals(b.getBadgeId()));
                if (!alreadyHas) {
                    user.getBadges().add(User.UserBadgeSnapshot.builder()
                        .badgeId(rewardBadgeId)
                        .name(rewardBadgeId)
                        .iconUrl("badge_completed_challenge")
                        .awardedAt(Instant.now())
                        .build());
                }
            }

            // 5. Grant Premium Trial Days
            int grantDays = challenge.getRewards() != null ? challenge.getRewards().getPremiumDaysGranted() : 0;
            if (grantDays > 0) {
                User.SubscriptionSnapshot sub = user.getSubscription();
                if (sub == null) {
                    sub = User.SubscriptionSnapshot.free();
                }
                Instant currentExp = sub.getPremiumUntil();
                Instant baseTime = (currentExp != null && currentExp.isAfter(Instant.now())) ? currentExp : Instant.now();
                sub.setPremiumUntil(baseTime.plus(Duration.ofDays(grantDays)));
                sub.setStatus(com.vfit.common.enums.SubscriptionStatus.ACTIVE);
                user.setSubscription(sub);
            }
            userRepo.save(user);

            // 6. Issue Non-Stackable Discount Voucher (Voucher 30k default)
            String templateId = challenge.getRewards() != null ? challenge.getRewards().getVoucherTemplateId() : null;
            if (templateId != null && !templateId.isEmpty()) {
                String uniqueCode = "CHALLENGE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
                
                // Build voucher safely aligning with compound index uniqueness requirements
                UserVoucher voucher = UserVoucher.builder()
                    .userId(user.getId())
                    .code(uniqueCode)
                    .amount(BigDecimal.valueOf(30000))
                    .status(UserVoucherStatus.AVAILABLE)
                    .issuedAt(Instant.now())
                    .expiredAt(Instant.now().plus(Duration.ofDays(30)))
                    .monthKey("CHALLENGE-" + challenge.getId())
                    .rewardMilestone((int) (Instant.now().getEpochSecond() % 1000000)) // Safe index value
                    .build();
                voucherRepo.save(voucher);
                log.info("Successfully issued voucher {} to user {}", uniqueCode, user.getId());
            }

            log.info("Atomic rewards distributed successfully for participation ID {}", participationId);

        } catch (Exception ex) {
            log.error("Failed to distribute rewards for participation ID {}", participationId, ex);
            throw ex;
        } finally {
            redisTemplate.delete(lockKey);
        }
    }
}
