package com.vfit.modules.auth.service;

import com.vfit.modules.auth.dto.request.ForgotPasswordRequest;
import com.vfit.modules.auth.dto.request.LoginRequest;
import com.vfit.modules.auth.dto.request.RefreshTokenRequest;
import com.vfit.modules.auth.dto.request.RegisterRequest;
import com.vfit.modules.auth.dto.request.ResetPasswordRequest;
import com.vfit.modules.auth.dto.response.AuthResponse;
import com.vfit.modules.auth.dto.response.TokenResponse;

public interface AuthService {
    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    TokenResponse refresh(RefreshTokenRequest request);

    void logout(RefreshTokenRequest request);

    void forgotPassword(ForgotPasswordRequest request);

    void resetPassword(ResetPasswordRequest request);
}
