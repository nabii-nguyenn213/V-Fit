package com.vfit.modules.user.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.GoalType;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.modules.ai.mapper.AiResultMapper;
import com.vfit.modules.ai.repository.BodyAnalysisRepository;
import com.vfit.modules.ai.document.BodyAnalysisResult;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.response.OnboardingResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.impl.OnboardingServiceImpl;
import com.vfit.security.model.CustomUserDetails;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.ArgumentMatchers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.multipart.MultipartFile;

@ExtendWith(MockitoExtension.class)
class OnboardingServiceImplTest {
    @Mock
    private UserRepository userRepository;
    @Mock
    private UserMapper userMapper;
    @Mock
    private AiClient aiClient;
    @Mock
    private BodyAnalysisRepository bodyAnalysisRepository;
    @Mock
    private AiResultMapper aiResultMapper;
    @Mock
    private MultipartFile file;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void completeBodyScanInfersLoseWeightFromHighUserBodyFat() {
        User user = pendingUserWithMetrics(170.0, 82.0, 29.0);
        AiBodyAnalysisResult aiResult = bodyAnalysis(21.0, "mobility and recomposition");
        OnboardingServiceImpl service = service();

        arrangeBodyScan(user, aiResult);

        service.completeBodyScan(file);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getGoalType()).isEqualTo(GoalType.LOSE_WEIGHT);
        assertThat(captor.getValue().getOnboardingStatus()).isEqualTo(OnboardingStatus.COMPLETED);
    }

    @Test
    void completeBodyScanInfersGainMuscleForLeanUser() {
        User user = pendingUserWithMetrics(175.0, 62.0, null);
        AiBodyAnalysisResult aiResult = bodyAnalysis(16.0, "strength and hypertrophy");
        OnboardingServiceImpl service = service();

        arrangeBodyScan(user, aiResult);

        service.completeBodyScan(file);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getGoalType()).isEqualTo(GoalType.GAIN_MUSCLE);
        assertThat(captor.getValue().getOnboardingStatus()).isEqualTo(OnboardingStatus.COMPLETED);
    }

    private OnboardingServiceImpl service() {
        return new OnboardingServiceImpl(
                userRepository,
                userMapper,
                aiClient,
                bodyAnalysisRepository,
                aiResultMapper,
                objectMapper);
    }

    private void arrangeBodyScan(User user, AiBodyAnalysisResult aiResult) {
        authenticate(user);
        when(file.isEmpty()).thenReturn(false);
        when(file.getContentType()).thenReturn("image/jpeg");
        try {
            when(file.getBytes()).thenReturn(new byte[] {1, 2, 3});
        } catch (java.io.IOException e) {
            throw new IllegalStateException(e);
        }
        when(file.getSize()).thenReturn(3L);
        when(userRepository.findById("user-1")).thenReturn(Optional.of(user));
        when(aiClient.analyzeBody(eq("user-1"), eq("transient-body-scan"), ArgumentMatchers.argThat(metadata ->
                metadata instanceof Map<?, ?> map && map.containsKey("frameBytes"))))
                .thenReturn(aiResult);
        when(aiResultMapper.toMap(any(ObjectMapper.class), any())).thenReturn(Map.of());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userMapper.toResponse(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            return UserResponse.builder()
                    .id(saved.getId())
                    .email(saved.getEmail())
                    .fullName(saved.getFullName())
                    .role(saved.getRole())
                    .active(saved.isActive())
                    .goalType(saved.getGoalType())
                    .onboardingStatus(saved.getOnboardingStatus())
                    .build();
        });
        when(aiResultMapper.toOnboardingResponse(any(), any(), any()))
                .thenAnswer(invocation -> OnboardingResponse.builder()
                        .onboardingStatus(invocation.getArgument(0))
                        .user(invocation.getArgument(1))
                        .fallback(false)
                        .build());
    }

    private User pendingUserWithMetrics(Double heightCm, Double weightKg, Double bodyFatPercent) {
        User.BodyMetrics metrics = new User.BodyMetrics();
        metrics.setHeightCm(heightCm);
        metrics.setWeightKg(weightKg);
        metrics.setBodyFatPercent(bodyFatPercent);
        if (heightCm != null && weightKg != null) {
            double meters = heightCm / 100.0;
            metrics.setBmi(Math.round((weightKg / (meters * meters)) * 10.0) / 10.0);
        }

        return User.builder()
                .id("user-1")
                .email("member@vfit.com")
                .fullName("Member")
                .role(RoleName.USER)
                .active(true)
                .onboardingStatus(OnboardingStatus.PENDING)
                .bodyMetrics(metrics)
                .build();
    }

    private AiBodyAnalysisResult bodyAnalysis(Double bodyFatPercent, String focus) {
        return new AiBodyAnalysisResult(
                new AiBodyAnalysisResult.Posture("Neutral", 10),
                new AiBodyAnalysisResult.Imbalance("Balanced", "LOW"),
                new AiBodyAnalysisResult.BodyEstimate(bodyFatPercent, 50.0, 0.8, null),
                new AiBodyAnalysisResult.Recommendation(focus, 4),
                false);
    }

    private void authenticate(User user) {
        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                new CustomUserDetails(user),
                null,
                new CustomUserDetails(user).getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    @Test
    void completeRealtimeBodyScanInfersGoalAndSavesResult() {
        User user = pendingUserWithMetrics(180.0, 75.0, 15.0);
        AiBodyAnalysisResult aiResult = bodyAnalysis(15.0, "strength training");
        OnboardingServiceImpl service = service();

        authenticate(user);
        when(userRepository.findById("user-1")).thenReturn(Optional.of(user));
        when(aiResultMapper.toMap(any(ObjectMapper.class), any())).thenReturn(Map.of());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userMapper.toResponse(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            return UserResponse.builder()
                    .id(saved.getId())
                    .email(saved.getEmail())
                    .fullName(saved.getFullName())
                    .role(saved.getRole())
                    .active(saved.isActive())
                    .goalType(saved.getGoalType())
                    .onboardingStatus(saved.getOnboardingStatus())
                    .build();
        });
        when(aiResultMapper.toOnboardingResponse(any(), any(), any()))
                .thenAnswer(invocation -> OnboardingResponse.builder()
                        .onboardingStatus(invocation.getArgument(0))
                        .user(invocation.getArgument(1))
                        .fallback(false)
                        .build());

        OnboardingResponse response = service.completeRealtimeBodyScan(aiResult);

        assertThat(response.getOnboardingStatus()).isEqualTo(OnboardingStatus.COMPLETED);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(userCaptor.getValue().getGoalType()).isEqualTo(GoalType.GAIN_MUSCLE);
        assertThat(userCaptor.getValue().getOnboardingStatus()).isEqualTo(OnboardingStatus.COMPLETED);
        assertThat(userCaptor.getValue().isActive()).isTrue();

        ArgumentCaptor<BodyAnalysisResult> resultCaptor = ArgumentCaptor.forClass(BodyAnalysisResult.class);
        verify(bodyAnalysisRepository).save(resultCaptor.capture());
        assertThat(resultCaptor.getValue().getMetadata().get("source")).isEqualTo("onboarding-realtime");
        assertThat(resultCaptor.getValue().getUserId()).isEqualTo("user-1");
    }
}
