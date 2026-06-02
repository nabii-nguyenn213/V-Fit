package com.vfit.modules.auth.service.impl;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.auth.dto.SocialLoginProvider;
import com.vfit.modules.auth.dto.SocialProviderProfile;
import com.vfit.modules.auth.document.UserSession;
import com.vfit.modules.auth.document.PasswordResetToken;
import com.vfit.modules.auth.dto.request.ForgotPasswordRequest;
import com.vfit.modules.auth.dto.request.LoginRequest;
import com.vfit.modules.auth.dto.request.RefreshTokenRequest;
import com.vfit.modules.auth.dto.request.RegisterRequest;
import com.vfit.modules.auth.dto.request.ResetPasswordRequest;
import com.vfit.modules.auth.dto.request.SocialLoginRequest;
import com.vfit.modules.auth.dto.request.VerifyOtpRequest;
import com.vfit.modules.auth.dto.response.AuthResponse;
import com.vfit.modules.auth.dto.response.TokenResponse;
import com.vfit.modules.auth.event.UserRegisteredEvent;
import com.vfit.modules.auth.mapper.AuthMapper;
import com.vfit.modules.auth.repository.PasswordResetTokenRepository;
import com.vfit.modules.auth.repository.UserSessionRepository;
import com.vfit.modules.auth.service.AuthService;
import com.vfit.modules.auth.service.EmailService;
import com.vfit.modules.auth.service.OtpService;
import com.vfit.modules.auth.service.SocialProviderVerifier;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserService;
import com.vfit.security.jwt.JwtProperties;
import com.vfit.security.jwt.JwtTokenProvider;
import com.vfit.security.model.CustomUserDetails;
import jakarta.servlet.http.HttpServletRequest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceImpl implements AuthService {
    private final JwtTokenProvider jwtTokenProvider;
    private final JwtProperties jwtProperties;
    private final UserSessionRepository userSessionRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final UserRepository userRepository;
    private final UserService userService;
    private final UserMapper userMapper;
    private final AuthMapper authMapper;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;
    private final OtpService otpService;
    private final EmailService emailService;
    private final List<SocialProviderVerifier> socialProviderVerifiers;
    private final SecureRandom secureRandom = new SecureRandom();

    @Override
    public void register(RegisterRequest request) {
        // Create user as inactive (active = false is set inside createLocalUser for RoleName.USER)
        User user = userService.createLocalUser(request.getEmail(), request.getPassword(), request.getFullName(), RoleName.USER);
        eventPublisher.publishEvent(new UserRegisteredEvent(user.getId(), user.getEmail()));
        
        // Generate and send OTP
        otpService.generateAndSendOtp(user.getEmail());
    }

    @Override
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        String normalizedEmail = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "User not found"));

        // Verify the OTP
        otpService.verifyOtp(normalizedEmail, request.getOtpCode());

        // Activate the user
        user.setActive(true);
        userRepository.save(user);

        // Issue tokens and return AuthResponse
        return authMapper.toAuthResponse(userMapper.toResponse(user), issueTokens(user));
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new AppException(ErrorCode.UNAUTHORIZED, "Email hoặc mật khẩu không chính xác."));

        // Block deactivated (soft-deleted) users before anything else
        if (user.getDeactivatedAt() != null) {
            throw new AppException(ErrorCode.FORBIDDEN, "Tài khoản đã bị vô hiệu hóa.");
        }

        // Validate password
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Email hoặc mật khẩu không chính xác.");
        }

        // For regular user: must be active (verified OTP)
        if (user.getRole() == RoleName.USER && !user.isActive()) {
            otpService.generateAndSendOtp(user.getEmail());
            throw new AppException(ErrorCode.UNAUTHORIZED, "Vui lòng xác thực email bằng mã OTP trước khi đăng nhập. Một mã OTP mới đã được gửi.");
        }

        return authMapper.toAuthResponse(userMapper.toResponse(user), issueTokens(user));
    }

    @Override
    public AuthResponse socialLogin(SocialLoginRequest request) {
        SocialProviderProfile profile = verifierFor(request.getProvider())
                .verify(request.getProviderToken());

        if (!profile.isEmailVerified() || profile.getEmail() == null || profile.getEmail().isBlank()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Social account must provide a verified email");
        }

        String provider = profile.getProvider().name();
        Optional<User> linkedUser = userRepository.findBySocialIdentity(provider, profile.getSubject());
        User user = linkedUser.orElseGet(() -> resolveUserForNewProviderIdentity(profile));

        rejectDisabledUser(user);
        linkOrRefreshProviderIdentity(user, profile);
        user = userRepository.save(user);

        log.info("[SECURITY AUDIT] Social login success. provider={}, userId={}", provider, user.getId());
        return authMapper.toAuthResponse(userMapper.toResponse(user), issueTokens(user));
    }

    @Override
    public TokenResponse refresh(RefreshTokenRequest request) {
        String incomingToken = request.getRefreshToken();
        String tokenHash = hashSha256(incomingToken);

        UserSession session = userSessionRepository.findByRefreshTokenHash(tokenHash)
                .orElse(null);

        // Reuse Detection: If session is found but it is already revoked due to being replaced,
        // it means this token is being reused (compromised refresh token).
        if (session != null && session.isRevoked() && "REPLACED_BY_NEW_TOKEN".equals(session.getRevokedReason())) {
            // Revoke all active sessions for this user immediately!
            List<UserSession> activeSessions = userSessionRepository.findByUserIdAndIsRevokedFalse(session.getUserId());
            for (UserSession activeSession : activeSessions) {
                activeSession.setRevoked(true);
                activeSession.setRevokedAt(Instant.now());
                activeSession.setRevokedReason("REUSE_DETECTED");
            }
            userSessionRepository.saveAll(activeSessions);
            throw new AppException(ErrorCode.UNAUTHORIZED, "Session compromise detected. All sessions revoked.");
        }

        if (session == null || !session.isActive()) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Refresh token is invalid, expired, or revoked");
        }

        // Valid active session found -> Rotate token
        session.setRevoked(true);
        session.setRevokedAt(Instant.now());
        session.setRevokedReason("REPLACED_BY_NEW_TOKEN");
        userSessionRepository.save(session);

        User user = userRepository.findById(session.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.UNAUTHORIZED, "User not found"));

        return issueTokens(user);
    }

    @Override
    public void logout(RefreshTokenRequest request) {
        String tokenHash = hashSha256(request.getRefreshToken());
        userSessionRepository.findByRefreshTokenHash(tokenHash).ifPresent(session -> {
            session.setRevoked(true);
            session.setRevokedAt(Instant.now());
            session.setRevokedReason("MANUALLY_LOGGED_OUT");
            userSessionRepository.save(session);
        });
    }

    @Override
    public void forgotPassword(ForgotPasswordRequest request) {
        userRepository.findByEmail(request.getEmail().toLowerCase().trim()).ifPresent(user -> {
            // Clear existing tokens
            passwordResetTokenRepository.deleteByUserId(user.getId());

            // Generate 6-digit password reset code
            int number = secureRandom.nextInt(900000) + 100000;
            String resetCode = String.valueOf(number);

            PasswordResetToken resetToken = PasswordResetToken.builder()
                    .token(resetCode)
                    .userId(user.getId())
                    .expiresAt(Instant.now().plusSeconds(900)) // 15 minutes
                    .build();
            passwordResetTokenRepository.save(resetToken);

            // Send reset code email
            emailService.sendPasswordResetCode(user.getEmail(), resetCode);
        });
    }

    @Override
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(request.getResetToken())
                .orElseThrow(() -> new AppException(ErrorCode.BAD_REQUEST, "Invalid password reset token"));
        if (!resetToken.isUsable()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Password reset token expired or used");
        }
        User user = userRepository.findById(resetToken.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.BAD_REQUEST, "Invalid password reset token"));
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        resetToken.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(resetToken);
        
        // Revoke all sessions on password reset
        List<UserSession> activeSessions = userSessionRepository.findByUserIdAndIsRevokedFalse(user.getId());
        for (UserSession session : activeSessions) {
            session.setRevoked(true);
            session.setRevokedAt(Instant.now());
            session.setRevokedReason("PASSWORD_RESET");
        }
        userSessionRepository.saveAll(activeSessions);
    }

    private TokenResponse issueTokens(User user) {
        String refreshToken = randomToken();
        String tokenHash = hashSha256(refreshToken);

        // Fetch client request metadata using RequestContextHolder
        String userAgent = "Unknown";
        String ipAddress = "Unknown";
        String deviceId = "Unknown Device";

        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes != null) {
            HttpServletRequest request = attributes.getRequest();
            userAgent = request.getHeader("User-Agent");
            if (userAgent == null || userAgent.isEmpty()) {
                userAgent = "Unknown";
            }
            ipAddress = request.getHeader("X-Forwarded-For");
            if (ipAddress != null && !ipAddress.isEmpty()) {
                // Take only the first IP (original client) to prevent spoofing
                ipAddress = ipAddress.split(",")[0].trim();
            } else {
                ipAddress = request.getRemoteAddr();
            }
            deviceId = request.getHeader("X-Device-Id");
            if (deviceId == null || deviceId.isEmpty()) {
                deviceId = "Mobile Device";
            }
        }

        UserSession session = UserSession.builder()
                .userId(user.getId())
                .refreshTokenHash(tokenHash)
                .deviceId(deviceId)
                .userAgent(userAgent)
                .ipAddress(ipAddress)
                .expiresAt(Instant.now().plusMillis(jwtProperties.getRefreshTokenExpirationMs()))
                .createdAt(Instant.now())
                .isRevoked(false)
                .build();
        userSessionRepository.save(session);

        CustomUserDetails details = new CustomUserDetails(user);
        String accessToken = jwtTokenProvider.createAccessToken(details, session.getId());

        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresInMs(jwtProperties.getAccessTokenExpirationMs())
                .build();
    }

    private SocialProviderVerifier verifierFor(SocialLoginProvider provider) {
        return socialProviderVerifiers.stream()
                .filter(verifier -> verifier.supports(provider))
                .findFirst()
                .orElseThrow(() -> new AppException(ErrorCode.BAD_REQUEST, "Unsupported social login provider"));
    }

    private User resolveUserForNewProviderIdentity(SocialProviderProfile profile) {
        Optional<User> existingByEmail = userRepository.findByEmail(profile.getEmail());
        if (existingByEmail.isPresent()) {
            User user = existingByEmail.get();
            rejectDisabledUser(user);
            rejectProviderConflictOnUser(user, profile);
            if (!user.isActive()) {
                user.setActive(true);
            }
            fillMissingProfileFields(user, profile);
            return user;
        }

        return User.builder()
                .email(profile.getEmail())
                .passwordHash(passwordEncoder.encode(randomToken()))
                .fullName(profile.getDisplayName())
                .avatarUrl(profile.getAvatarUrl())
                .role(RoleName.USER)
                .active(true)
                .onboardingStatus(OnboardingStatus.PENDING)
                .build();
    }

    private void rejectDisabledUser(User user) {
        if (user.getDeactivatedAt() != null) {
            throw new AppException(ErrorCode.FORBIDDEN, "ACCOUNT_DEACTIVATED");
        }
    }

    private void rejectProviderConflictOnUser(User user, SocialProviderProfile profile) {
        List<User.SocialProviderIdentity> identities = user.getSocialIdentities();
        if (identities == null) {
            return;
        }
        boolean sameProviderDifferentSubject = identities.stream()
                .anyMatch(identity -> profile.getProvider().name().equals(identity.getProvider())
                        && !profile.getSubject().equals(identity.getSubject()));
        if (sameProviderDifferentSubject) {
            throw new AppException(ErrorCode.CONFLICT, "Social provider is already linked to another identity");
        }
    }

    private void linkOrRefreshProviderIdentity(User user, SocialProviderProfile profile) {
        if (user.getSocialIdentities() == null) {
            user.setSocialIdentities(new ArrayList<>());
        }

        Instant now = Instant.now();
        Optional<User.SocialProviderIdentity> existing = user.getSocialIdentities().stream()
                .filter(identity -> profile.getProvider().name().equals(identity.getProvider())
                        && profile.getSubject().equals(identity.getSubject()))
                .findFirst();

        if (existing.isPresent()) {
            User.SocialProviderIdentity identity = existing.get();
            identity.setEmail(profile.getEmail());
            identity.setDisplayName(profile.getDisplayName());
            identity.setAvatarUrl(profile.getAvatarUrl());
            identity.setLastLoginAt(now);
            fillMissingProfileFields(user, profile);
            return;
        }

        user.getSocialIdentities().add(User.SocialProviderIdentity.builder()
                .provider(profile.getProvider().name())
                .subject(profile.getSubject())
                .email(profile.getEmail())
                .displayName(profile.getDisplayName())
                .avatarUrl(profile.getAvatarUrl())
                .linkedAt(now)
                .lastLoginAt(now)
                .build());
        fillMissingProfileFields(user, profile);
    }

    private void fillMissingProfileFields(User user, SocialProviderProfile profile) {
        if ((user.getFullName() == null || user.getFullName().isBlank()) && profile.getDisplayName() != null) {
            user.setFullName(profile.getDisplayName().trim());
        }
        if ((user.getAvatarUrl() == null || user.getAvatarUrl().isBlank()) && profile.getAvatarUrl() != null) {
            user.setAvatarUrl(profile.getAvatarUrl());
        }
    }

    @Override
    public void resendOtp(com.vfit.modules.auth.dto.request.ResendOtpRequest request) {
        String normalizedEmail = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Email chưa được đăng ký."));

        if (user.isActive()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Tài khoản đã được kích hoạt.");
        }

        otpService.generateAndSendOtp(user.getEmail());
    }

    private String randomToken() {
        byte[] bytes = new byte[64];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hashSha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not found", e);
        }
    }
}
