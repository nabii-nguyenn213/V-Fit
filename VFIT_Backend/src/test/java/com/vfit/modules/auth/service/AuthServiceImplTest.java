package com.vfit.modules.auth.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.modules.auth.dto.SocialLoginProvider;
import com.vfit.modules.auth.dto.SocialProviderProfile;
import com.vfit.modules.auth.dto.request.SocialLoginRequest;
import com.vfit.modules.auth.dto.response.AuthResponse;
import com.vfit.modules.auth.dto.response.TokenResponse;
import com.vfit.modules.auth.mapper.AuthMapper;
import com.vfit.modules.auth.repository.PasswordResetTokenRepository;
import com.vfit.modules.auth.repository.UserSessionRepository;
import com.vfit.modules.auth.service.impl.AuthServiceImpl;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserService;
import com.vfit.security.jwt.JwtProperties;
import com.vfit.security.jwt.JwtTokenProvider;
import com.vfit.security.model.CustomUserDetails;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceImplTest {
    @Mock
    private JwtTokenProvider jwtTokenProvider;
    @Mock
    private JwtProperties jwtProperties;
    @Mock
    private UserSessionRepository userSessionRepository;
    @Mock
    private PasswordResetTokenRepository passwordResetTokenRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private UserService userService;
    @Mock
    private UserMapper userMapper;
    @Mock
    private AuthMapper authMapper;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private ApplicationEventPublisher eventPublisher;
    @Mock
    private OtpService otpService;
    @Mock
    private EmailService emailService;
    @Mock
    private SocialProviderVerifier socialProviderVerifier;

    @Test
    void socialLoginLinksVerifiedProviderEmailToExistingUser() {
        User existing = User.builder()
                .id("user-1")
                .email("member@vfit.com")
                .fullName("Member")
                .role(RoleName.USER)
                .active(true)
                .onboardingStatus(OnboardingStatus.PENDING)
                .build();
        SocialProviderProfile profile = SocialProviderProfile.builder()
                .provider(SocialLoginProvider.GOOGLE)
                .subject("google-sub")
                .email("member@vfit.com")
                .emailVerified(true)
                .displayName("Google Member")
                .avatarUrl("https://example.com/avatar.png")
                .build();
        SocialLoginRequest request = new SocialLoginRequest();
        request.setProvider(SocialLoginProvider.GOOGLE);
        request.setProviderToken("provider-token");

        UserResponse userResponse = UserResponse.builder()
                .id("user-1")
                .email("member@vfit.com")
                .role(RoleName.USER)
                .active(true)
                .onboardingStatus(OnboardingStatus.PENDING)
                .build();
        TokenResponse tokenResponse = TokenResponse.builder()
                .accessToken("access")
                .refreshToken("refresh")
                .tokenType("Bearer")
                .expiresInMs(900000)
                .build();
        AuthResponse authResponse = AuthResponse.builder()
                .user(userResponse)
                .tokens(tokenResponse)
                .build();

        when(socialProviderVerifier.supports(SocialLoginProvider.GOOGLE)).thenReturn(true);
        when(socialProviderVerifier.verify("provider-token")).thenReturn(profile);
        when(userRepository.findBySocialIdentity("GOOGLE", "google-sub")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("member@vfit.com")).thenReturn(Optional.of(existing));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userMapper.toResponse(any(User.class))).thenReturn(userResponse);
        when(jwtProperties.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtProperties.getAccessTokenExpirationMs()).thenReturn(900000L);
        when(jwtTokenProvider.createAccessToken(any(CustomUserDetails.class), nullable(String.class)))
                .thenReturn("access");
        when(authMapper.toAuthResponse(eq(userResponse), any(TokenResponse.class), eq(false)))
                .thenReturn(authResponse);

        AuthServiceImpl service = new AuthServiceImpl(
                jwtTokenProvider,
                jwtProperties,
                userSessionRepository,
                passwordResetTokenRepository,
                userRepository,
                userService,
                userMapper,
                authMapper,
                passwordEncoder,
                eventPublisher,
                otpService,
                emailService,
                List.of(socialProviderVerifier));

        AuthResponse result = service.socialLogin(request);

        assertThat(result).isEqualTo(authResponse);
        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User saved = captor.getValue();
        assertThat(saved.getSocialIdentities()).hasSize(1);
        assertThat(saved.getSocialIdentities().get(0).getProvider()).isEqualTo("GOOGLE");
        assertThat(saved.getSocialIdentities().get(0).getSubject()).isEqualTo("google-sub");
        verify(userSessionRepository).save(any());
        verify(authMapper).toAuthResponse(eq(userResponse), any(TokenResponse.class), eq(false));
    }

    @Test
    void socialLoginMarksNewAccountAsNewRegistration() {
        SocialProviderProfile profile = SocialProviderProfile.builder()
                .provider(SocialLoginProvider.GOOGLE)
                .subject("new-google-sub")
                .email("new-member@vfit.com")
                .emailVerified(true)
                .displayName("New Member")
                .avatarUrl("https://example.com/new-avatar.png")
                .build();
        SocialLoginRequest request = new SocialLoginRequest();
        request.setProvider(SocialLoginProvider.GOOGLE);
        request.setProviderToken("new-provider-token");

        UserResponse userResponse = UserResponse.builder()
                .id("new-user")
                .email("new-member@vfit.com")
                .role(RoleName.USER)
                .active(true)
                .onboardingStatus(OnboardingStatus.PENDING)
                .build();
        AuthResponse authResponse = AuthResponse.builder()
                .user(userResponse)
                .tokens(TokenResponse.builder()
                        .accessToken("access")
                        .refreshToken("refresh")
                        .tokenType("Bearer")
                        .expiresInMs(900000)
                        .build())
                .newRegistration(true)
                .build();

        when(socialProviderVerifier.supports(SocialLoginProvider.GOOGLE)).thenReturn(true);
        when(socialProviderVerifier.verify("new-provider-token")).thenReturn(profile);
        when(userRepository.findBySocialIdentity("GOOGLE", "new-google-sub"))
                .thenReturn(Optional.empty());
        when(userRepository.findByEmail("new-member@vfit.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("generated-password-hash");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            if (user.getId() == null) {
                user.setId("new-user");
            }
            return user;
        });
        when(userMapper.toResponse(any(User.class))).thenReturn(userResponse);
        when(jwtProperties.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtProperties.getAccessTokenExpirationMs()).thenReturn(900000L);
        when(jwtTokenProvider.createAccessToken(any(CustomUserDetails.class), nullable(String.class)))
                .thenReturn("access");
        when(authMapper.toAuthResponse(eq(userResponse), any(TokenResponse.class), eq(true)))
                .thenReturn(authResponse);

        AuthServiceImpl service = new AuthServiceImpl(
                jwtTokenProvider,
                jwtProperties,
                userSessionRepository,
                passwordResetTokenRepository,
                userRepository,
                userService,
                userMapper,
                authMapper,
                passwordEncoder,
                eventPublisher,
                otpService,
                emailService,
                List.of(socialProviderVerifier));

        AuthResponse result = service.socialLogin(request);

        assertThat(result.isNewRegistration()).isTrue();
        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User saved = captor.getValue();
        assertThat(saved.getSubscription().getPlanCode()).isEqualTo("VIP_TRIAL");
        assertThat(saved.getSubscription().getPremiumUntil()).isAfter(java.time.Instant.now());
        verify(authMapper).toAuthResponse(eq(userResponse), any(TokenResponse.class), eq(true));
    }
}
