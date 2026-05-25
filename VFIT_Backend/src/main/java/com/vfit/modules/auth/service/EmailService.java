package com.vfit.modules.auth.service;

public interface EmailService {
    void sendOtp(String to, String otp);
    void sendPasswordResetCode(String to, String code);
}
