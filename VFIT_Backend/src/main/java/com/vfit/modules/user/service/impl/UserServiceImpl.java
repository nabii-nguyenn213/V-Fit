package com.vfit.modules.user.service.impl;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.common.util.SecurityUtil;
import com.vfit.bootstrap.storage.FileStorageService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.request.ChangePasswordRequest;
import com.vfit.modules.user.dto.request.UpdateProfileRequest;
import com.vfit.modules.user.dto.response.BodyMetricResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserService;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final FileStorageService fileStorageService;

    @Override
    public User createLocalUser(String email, String rawPassword, String fullName, RoleName role) {
        String normalizedEmail = email.toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new AppException(ErrorCode.CONFLICT, "Email already exists");
        }
        User user = User.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .fullName(fullName)
                .role(normalizeRole(role))
                .onboardingStatus(role == RoleName.ADMIN ? OnboardingStatus.COMPLETED : OnboardingStatus.PENDING)
                .active(role == RoleName.ADMIN)
                .build();
        return userRepository.save(user);
    }

    @Override
    public UserResponse updateCurrentUser(UpdateProfileRequest request) {
        User user = currentUser();
        user.setFullName(request.getFullName());
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

    @Override
    public UserResponse uploadCurrentUserAvatar(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Avatar image is required");
        }

        User user = currentUser();
        String avatarPath = fileStorageService.store(file, "avatars");
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
        user.setActive(false);
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
}
