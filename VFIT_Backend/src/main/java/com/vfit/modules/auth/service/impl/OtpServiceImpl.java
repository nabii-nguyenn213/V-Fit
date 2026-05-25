package com.vfit.modules.auth.service.impl;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.auth.document.EmailOtp;
import com.vfit.modules.auth.repository.EmailOtpRepository;
import com.vfit.modules.auth.service.EmailService;
import com.vfit.modules.auth.service.OtpService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class OtpServiceImpl implements OtpService {
    private final EmailOtpRepository emailOtpRepository;
    private final EmailService emailService;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.security.otp-pepper:vfit_otp_secure_pepper_salt_secret_12345}")
    private String pepper;

    @Override
    public EmailOtp generateAndSendOtp(String email) {
        String normalizedEmail = email.toLowerCase().trim();
        
        int currentResendCount = 0;
        Instant originalCreatedAt = Instant.now();
        
        var existingOtpOpt = emailOtpRepository.findByEmail(normalizedEmail);
        if (existingOtpOpt.isPresent()) {
            EmailOtp existing = existingOtpOpt.get();
            // Check if within 10 minutes window (600 seconds)
            if (existing.getCreatedAt() != null && existing.getCreatedAt().plusSeconds(600).isAfter(Instant.now())) {
                currentResendCount = existing.getResendCount() + 1;
                if (currentResendCount > 3) {
                    throw new AppException(ErrorCode.RATE_LIMITED, "Bạn đã vượt quá giới hạn gửi lại mã OTP (tối đa 3 lần trong 10 phút). Vui lòng thử lại sau.");
                }
                originalCreatedAt = existing.getCreatedAt();
            }
            // Invalidate/delete old OTP
            emailOtpRepository.deleteByEmail(normalizedEmail);
        }

        // Generate 6-digit OTP
        int number = secureRandom.nextInt(900000) + 100000;
        String otpCode = String.valueOf(number);
        String otpHash = hashSha256(otpCode);

        EmailOtp newOtp = EmailOtp.builder()
                .email(normalizedEmail)
                .otpHash(otpHash)
                .expiresAt(Instant.now().plusSeconds(120)) // Strict 2-Minute OTP Window
                .attemptsLeft(3)
                .resendCount(currentResendCount)
                .createdAt(originalCreatedAt)
                .build();

        EmailOtp saved = emailOtpRepository.save(newOtp);
        emailService.sendOtp(normalizedEmail, otpCode);
        return saved;
    }

    @Override
    public boolean verifyOtp(String email, String otpCode) {
        String normalizedEmail = email.toLowerCase().trim();
        EmailOtp otpRecord = emailOtpRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new AppException(ErrorCode.BAD_REQUEST, "Mã OTP không tồn tại hoặc đã hết hạn."));

        if (otpRecord.isExpired()) {
            emailOtpRepository.deleteByEmail(normalizedEmail);
            throw new AppException(ErrorCode.BAD_REQUEST, "Mã OTP đã hết hạn.");
        }

        if (otpRecord.isAttemptLimitExceeded()) {
            emailOtpRepository.deleteByEmail(normalizedEmail);
            throw new AppException(ErrorCode.BAD_REQUEST, "Tài khoản bị khóa tạm thời do nhập sai OTP quá 3 lần. Vui lòng gửi lại mã mới.");
        }

        String codeHash = hashSha256(otpCode.trim());
        
        // Constant-time comparison
        byte[] a = otpRecord.getOtpHash().getBytes(StandardCharsets.UTF_8);
        byte[] b = codeHash.getBytes(StandardCharsets.UTF_8);
        boolean matches = MessageDigest.isEqual(a, b);

        if (!matches) {
            int attemptsLeft = otpRecord.getAttemptsLeft() - 1;
            otpRecord.setAttemptsLeft(attemptsLeft);
            if (attemptsLeft <= 0) {
                emailOtpRepository.deleteByEmail(normalizedEmail);
                throw new AppException(ErrorCode.BAD_REQUEST, "Nhập sai quá 3 lần. Mã OTP đã bị hủy.");
            } else {
                emailOtpRepository.save(otpRecord);
                throw new AppException(ErrorCode.BAD_REQUEST, "Mã OTP không chính xác. Bạn còn " + attemptsLeft + " lần thử.");
            }
        }

        emailOtpRepository.deleteByEmail(normalizedEmail);
        return true;
    }

    private String hashSha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            String dataWithPepper = input + pepper;
            byte[] hash = digest.digest(dataWithPepper.getBytes(StandardCharsets.UTF_8));
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
