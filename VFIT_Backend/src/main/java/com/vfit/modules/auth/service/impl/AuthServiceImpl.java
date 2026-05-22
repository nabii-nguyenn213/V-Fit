package com.vfit.modules.auth.service.impl;

import com.vfit.common.enums.RoleName;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.auth.document.RefreshToken;
import com.vfit.modules.auth.document.PasswordResetToken;
import com.vfit.modules.auth.dto.request.ForgotPasswordRequest;
import com.vfit.modules.auth.dto.request.LoginRequest;
import com.vfit.modules.auth.dto.request.RefreshTokenRequest;
import com.vfit.modules.auth.dto.request.RegisterRequest;
import com.vfit.modules.auth.dto.request.ResetPasswordRequest;
import com.vfit.modules.auth.dto.response.AuthResponse;
import com.vfit.modules.auth.dto.response.TokenResponse;
import com.vfit.modules.auth.event.UserRegisteredEvent;
import com.vfit.modules.auth.mapper.AuthMapper;
import com.vfit.modules.auth.repository.PasswordResetTokenRepository;
import com.vfit.modules.auth.repository.RefreshTokenRepository;
import com.vfit.modules.auth.service.AuthService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserService;
import com.vfit.security.jwt.JwtProperties;
import com.vfit.security.jwt.JwtTokenProvider;
import com.vfit.security.model.CustomUserDetails;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final JwtProperties jwtProperties;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final UserRepository userRepository;
    private final UserService userService;
    private final UserMapper userMapper;
    private final AuthMapper authMapper;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;
    private final SecureRandom secureRandom = new SecureRandom();

    @Override
    public AuthResponse register(RegisterRequest request) {
        User user = userService.createLocalUser(request.getEmail(), request.getPassword(), request.getFullName(), RoleName.USER);
        eventPublisher.publishEvent(new UserRegisteredEvent(user.getId(), user.getEmail()));
        return authMapper.toAuthResponse(userMapper.toResponse(user), issueTokens(user));
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.getEmail().toLowerCase(), request.getPassword()));
        User user = userRepository.findByEmail(request.getEmail().toLowerCase())
                .orElseThrow(() -> new AppException(ErrorCode.UNAUTHORIZED, "Invalid email or password"));
        return authMapper.toAuthResponse(userMapper.toResponse(user), issueTokens(user));
    }

    @Override
    public TokenResponse refresh(RefreshTokenRequest request) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new AppException(ErrorCode.UNAUTHORIZED, "Invalid refresh token"));
        if (!refreshToken.isActive()) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Refresh token expired or revoked");
        }
        User user = userRepository.findById(refreshToken.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.UNAUTHORIZED, "Invalid refresh token"));
        refreshToken.setRevokedAt(Instant.now());
        refreshTokenRepository.save(refreshToken);
        return issueTokens(user);
    }

    @Override
    public void logout(RefreshTokenRequest request) {
        refreshTokenRepository.findByToken(request.getRefreshToken()).ifPresent(token -> {
            token.setRevokedAt(Instant.now());
            refreshTokenRepository.save(token);
        });
    }

    @Override
    public void forgotPassword(ForgotPasswordRequest request) {
        userRepository.findByEmail(request.getEmail().toLowerCase()).ifPresent(user -> {
            PasswordResetToken resetToken = PasswordResetToken.builder()
                    .token(randomToken())
                    .userId(user.getId())
                    .expiresAt(Instant.now().plusSeconds(900))
                    .build();
            passwordResetTokenRepository.save(resetToken);
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
        refreshTokenRepository.deleteByUserId(user.getId());
    }

    private TokenResponse issueTokens(User user) {
        CustomUserDetails details = new CustomUserDetails(user);
        String accessToken = jwtTokenProvider.createAccessToken(details);
        String refreshValue = randomToken();
        RefreshToken refreshToken = RefreshToken.builder()
                .token(refreshValue)
                .userId(user.getId())
                .expiresAt(Instant.now().plusMillis(jwtProperties.getRefreshTokenExpirationMs()))
                .build();
        refreshTokenRepository.save(refreshToken);
        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshValue)
                .tokenType("Bearer")
                .expiresInMs(jwtProperties.getAccessTokenExpirationMs())
                .build();
    }

    private String randomToken() {
        byte[] bytes = new byte[64];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
