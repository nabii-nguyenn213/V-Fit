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
import com.vfit.bootstrap.storage.FileStorageService;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.modules.ai.mapper.AiResultMapper;
import com.vfit.modules.ai.repository.BodyAnalysisRepository;
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
    private FileStorageService fileStorageService;
    @Mock
    private AiClient aiClient;
    @Mock
    private BodyAnalysisRepository bodyAnalysisRepository;
    @Mock
    private AiResultMapper aiResultMapper;
    @Mock
    private MultipartFile file;

    private final AppProperties appProperties = new AppProperties();
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
        appProperties.setName("V-FIT");
        appProperties.setBaseUrl("http://localhost:8080");
        appProperties.getStorage().setUploadDir("uploads");
        appProperties.getSwagger().setTitle("API");
        appProperties.getSwagger().setVersion("test");
        appProperties.getSwagger().setDescription("test");
        appProperties.getBootstrap().getPublicConfig().setAppName("V-FIT");

        return new OnboardingServiceImpl(
                userRepository,
                userMapper,
                fileStorageService,
                aiClient,
                bodyAnalysisRepository,
                appProperties,
                aiResultMapper,
                objectMapper);
    }

    private void arrangeBodyScan(User user, AiBodyAnalysisResult aiResult) {
        authenticate(user);
        when(file.isEmpty()).thenReturn(false);
        when(userRepository.findById("user-1")).thenReturn(Optional.of(user));
        when(fileStorageService.store(file, "body-scans")).thenReturn("body-scans/user-1.jpg");
        when(aiClient.analyzeBody(eq("user-1"), eq("http://localhost:8080/uploads/body-scans/user-1.jpg"), any()))
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
                new AiBodyAnalysisResult.BodyEstimate(bodyFatPercent, 50.0, 0.8),
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
}
