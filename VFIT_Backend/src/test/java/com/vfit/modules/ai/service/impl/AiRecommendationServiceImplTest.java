package com.vfit.modules.ai.service.impl;

import static org.junit.jupiter.api.Assertions.*;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import java.time.LocalDate;
import com.vfit.common.enums.Gender;
import com.vfit.common.enums.GoalType;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;

class AiRecommendationServiceImplTest {

    private AiRecommendationServiceImpl service;
    private AiClient aiClientMock;
    private UserRepository userRepoMock;

    @BeforeEach
    void setUp() {
        aiClientMock = Mockito.mock(AiClient.class);
        userRepoMock = Mockito.mock(UserRepository.class);
        service = new AiRecommendationServiceImpl(aiClientMock, userRepoMock);
        // Mock authenticated user
        User mockUser = new User();
        mockUser.setId("test-user-id");
        mockUser.setDateOfBirth(LocalDate.of(1990, 1, 1));
        mockUser.setGender(Gender.MALE);
        mockUser.setGoalType(GoalType.LOSE_WEIGHT);
        User.BodyMetrics bm = new User.BodyMetrics();
        bm.setWeightKg(70.0);
        bm.setHeightCm(175.0);
        mockUser.setBodyMetrics(bm);
        Mockito.when(userRepoMock.findById("test-user-id")).thenReturn(java.util.Optional.of(mockUser));
        Authentication auth = new UsernamePasswordAuthenticationToken(
                new com.vfit.security.model.CustomUserDetails(mockUser), null,
                java.util.Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    void createMealPlan_WithFullProfile_ReturnsAiResponse() {
        Map<String, Object> request = new HashMap<>();
        request.put("activity_level", "moderate");
        request.put("age", 30);
        request.put("gender", "male");
        request.put("weight", 70);
        request.put("height", 175);
        request.put("goal", "lose_weight");

        Map<String, Object> fakeResponse = new HashMap<>();
        fakeResponse.put("food_name", "Salad");
        Mockito.when(aiClientMock.createMealPlan(Mockito.anyMap())).thenReturn(fakeResponse);

        Map<String, Object> result = service.createMealPlan(request);
        assertEquals("Salad", result.get("food_name"));
    }

    @Test
    void createMealPlan_MissingProfile_FallbackToUser_ThrowsIfUserIncomplete() {
        // Remove bodyMetrics from mocked user
        User incompleteUser = new User();
        incompleteUser.setId("incomplete-id");
        incompleteUser.setDateOfBirth(null);
        Mockito.when(userRepoMock.findById("incomplete-id")).thenReturn(java.util.Optional.of(incompleteUser));
        Authentication auth = new UsernamePasswordAuthenticationToken(
                new com.vfit.security.model.CustomUserDetails(incompleteUser), null,
                java.util.Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")));
        SecurityContextHolder.getContext().setAuthentication(auth);

        Map<String, Object> request = new HashMap<>();
        request.put("activity_level", "moderate");
        // No profile fields
        assertThrows(AppException.class, () -> service.createMealPlan(request));
    }
}
