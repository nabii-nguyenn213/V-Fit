package com.vfit.modules.user.service.impl;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.common.util.SecurityUtil;
import com.vfit.bootstrap.storage.CloudinaryService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.request.ChangePasswordRequest;
import com.vfit.modules.user.dto.request.UpdateProfileRequest;
import com.vfit.modules.user.dto.response.BodyMetricResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserService;
import com.vfit.modules.auth.document.UserSession;
import com.vfit.modules.auth.repository.UserSessionRepository;
import com.vfit.modules.auth.dto.response.ActiveSessionResponse;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final CloudinaryService cloudinaryService;
    private final UserSessionRepository userSessionRepository;

    @Override
    public User createLocalUser(String email, String rawPassword, String fullName, RoleName role) {
        String normalizedEmail = email.toLowerCase().trim();
        java.util.Optional<User> existing = userRepository.findByEmail(normalizedEmail);
        if (existing.isPresent()) {
            User exUser = existing.get();
            if (exUser.isActive()) {
                throw new AppException(ErrorCode.CONFLICT, "Email đã được đăng ký. Vui lòng đăng nhập hoặc sử dụng email khác.");
            } else {
                userRepository.delete(exUser);
            }
        }
        User user = User.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .fullName(sanitizeInput(fullName))
                .role(normalizeRole(role))
                .onboardingStatus(role == RoleName.ADMIN ? OnboardingStatus.COMPLETED : OnboardingStatus.PENDING)
                .active(role == RoleName.ADMIN)
                .subscription(role == RoleName.ADMIN ? User.SubscriptionSnapshot.free() : User.SubscriptionSnapshot.builder()
                        .status(com.vfit.common.enums.SubscriptionStatus.ACTIVE)
                        .planCode("VIP_TRIAL")
                        .premiumUntil(Instant.now().plus(java.time.Duration.ofDays(3)))
                        .build())
                .build();
        return userRepository.save(user);
    }

    @Override
    @CacheEvict(value = "personalized_workouts", key = "T(com.vfit.common.util.SecurityUtil).requireCurrentUserId()")
    public UserResponse updateCurrentUser(UpdateProfileRequest request) {
        User user = currentUser();
        user.setFullName(sanitizeInput(request.getFullName()));
        user.setAvatarUrl(request.getAvatarUrl());
        user.setGender(request.getGender());
        user.setDateOfBirth(request.getDateOfBirth());
        user.setGoalType(request.getGoalType());
        User.BodyMetrics metrics = user.getBodyMetrics() == null ? new User.BodyMetrics() : user.getBodyMetrics();
        metrics.setHeightCm(request.getHeightCm());
        metrics.setWeightKg(request.getWeightKg());
        metrics.setBodyFatPercent(request.getBodyFatPercent());
        metrics.setBmi(calculateBmi(request.getHeightCm(), request.getWeightKg()));
        metrics.setMeasuredAt(Instant.now());
        user.setBodyMetrics(metrics);
        return userMapper.toResponse(userRepository.save(user));
    }

    private String sanitizeInput(String input) {
        if (input == null) return null;
        // Strip out HTML tags to prevent XSS attacks
        return input.replaceAll("<[^>]*>", "").trim();
    }

    @Override
    public UserResponse uploadCurrentUserAvatar(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Avatar image is required");
        }

        User user = currentUser();
        String avatarPath = cloudinaryService.upload(file, "avatars");
        user.setAvatarUrl(avatarPath);
        return userMapper.toResponse(userRepository.save(user));
    }

    @Override
    public void changeCurrentUserPassword(ChangePasswordRequest request) {
        User user = currentUser();
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Current password is incorrect");
        }
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Revoke all active sessions on password change (same as resetPassword)
        List<UserSession> activeSessions = userSessionRepository
                .findByUserIdAndIsRevokedFalse(user.getId());
        for (UserSession session : activeSessions) {
            session.setRevoked(true);
            session.setRevokedAt(Instant.now());
            session.setRevokedReason("PASSWORD_CHANGED");
        }
        userSessionRepository.saveAll(activeSessions);
    }

    @Override
    public BodyMetricResponse getCurrentUserBodyMetrics() {
        return userMapper.toBodyMetricResponse(currentUser().getBodyMetrics());
    }

    @Override
    public void updateRole(String userId, RoleName role) {
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setRole(normalizeRole(role));
        userRepository.save(user);
    }

    @Override
    public void deleteUser(String userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (user.getRole() == RoleName.ADMIN) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Administrators cannot delete their account");
        }
        user.setActive(false);
        user.setDeactivatedAt(Instant.now());
        user.setOnboardingStatus(OnboardingStatus.COMPLETED);
        userRepository.save(user);
    }

    private User currentUser() {
        return userRepository.findById(SecurityUtil.requireCurrentUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private Double calculateBmi(Double heightCm, Double weightKg) {
        if (heightCm == null || weightKg == null || heightCm <= 0) {
            return null;
        }
        double meters = heightCm / 100.0;
        return Math.round((weightKg / (meters * meters)) * 10.0) / 10.0;
    }

    private RoleName normalizeRole(RoleName role) {
        return role == RoleName.ADMIN ? RoleName.ADMIN : RoleName.USER;
    }

    @Override
    public List<ActiveSessionResponse> getCurrentUserActiveSessions() {
        String currentUserId = SecurityUtil.requireCurrentUserId();
        List<UserSession> sessions = userSessionRepository.findByUserIdAndIsRevokedFalse(currentUserId);
        return sessions.stream()
                .filter(UserSession::isActive)
                .map(s -> ActiveSessionResponse.builder()
                        .id(s.getId())
                        .deviceId(s.getDeviceId())
                        .userAgent(s.getUserAgent())
                        .ipAddress(s.getIpAddress())
                        .expiresAt(s.getExpiresAt())
                        .createdAt(s.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public void revokeSession(String sessionId) {
        String currentUserId = SecurityUtil.requireCurrentUserId();
        UserSession session = userSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));
        if (!session.getUserId().equals(currentUserId)) {
            throw new AppException(ErrorCode.FORBIDDEN, "Cannot revoke another user's session");
        }
        session.setRevoked(true);
        session.setRevokedAt(Instant.now());
        session.setRevokedReason("MANUALLY_REVOKED");
        userSessionRepository.save(session);
    }
}
