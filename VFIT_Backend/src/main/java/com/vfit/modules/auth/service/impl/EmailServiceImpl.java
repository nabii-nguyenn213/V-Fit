package com.vfit.modules.auth.service.impl;

import com.vfit.modules.auth.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    @Async
    @Override
    public void sendOtp(String to, String otp) {
        log.info("Sending real OTP email to: {}", to);
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject("Mã xác thực tài khoản V-FIT");
            message.setText("Chào bạn,\n\n" +
                    "Mã xác thực (OTP) đăng ký tài khoản V-FIT của bạn là: " + otp + "\n" +
                    "Mã này có hiệu lực trong vòng 5 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.\n\n" +
                    "Trân trọng,\n" +
                    "Đội ngũ V-FIT");
            
            mailSender.send(message);
            log.info("Successfully sent OTP email to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send OTP email to: {}", to, e);
        }
    }

    @Async
    @Override
    public void sendPasswordResetCode(String to, String code) {
        log.info("Sending password reset email to: {}", to);
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject("Mã đặt lại mật khẩu V-FIT");
            message.setText("Chào bạn,\n\n" +
                    "Bạn đã yêu cầu đặt lại mật khẩu cho tài khoản V-FIT của mình.\n" +
                    "Mã đặt lại mật khẩu của bạn là: " + code + "\n" +
                    "Mã này có hiệu lực trong vòng 15 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.\n\n" +
                    "Trân trọng,\n" +
                    "Đội ngũ V-FIT");
            
            mailSender.send(message);
            log.info("Successfully sent password reset email to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", to, e);
        }
    }
}
