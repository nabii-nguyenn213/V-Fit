package com.vfit.modules.auth.service;

import com.vfit.modules.auth.document.EmailOtp;

public interface OtpService {
    EmailOtp generateAndSendOtp(String email);
    boolean verifyOtp(String email, String otpCode);
}
