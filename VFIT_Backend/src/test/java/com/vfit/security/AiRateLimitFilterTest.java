package com.vfit.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

class AiRateLimitFilterTest {
    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @Mock
    private FilterChain filterChain;

    private AiRateLimitFilter filter;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        filter = new AiRateLimitFilter(redisTemplate, objectMapper);
        ReflectionTestUtils.setField(filter, "foodScanMaxDailyRequests", 10L);
        ReflectionTestUtils.setField(filter, "failOpenWhenRedisUnavailable", false);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void foodScannerAllowsTenRequestsPerDayAndRejectsEleventh() throws Exception {
        when(valueOperations.increment(org.mockito.ArgumentMatchers.startsWith("rate-limit:ai-food-scan:")))
                .thenReturn(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L);

        for (int i = 0; i < 10; i++) {
            MockHttpServletResponse response = new MockHttpServletResponse();
            filter.doFilter(foodScanRequest(), response, filterChain);
            assertThat(response.getStatus()).isNotEqualTo(429);
        }

        MockHttpServletResponse blocked = new MockHttpServletResponse();
        filter.doFilter(foodScanRequest(), blocked, filterChain);

        assertThat(blocked.getStatus()).isEqualTo(429);
        assertThat(blocked.getContentAsString())
                .contains("\"code\":\"RATE_LIMITED\"")
                .contains("\"path\":\"/api/ai/food-calorie-estimate\"");
        verify(filterChain, org.mockito.Mockito.times(10))
                .doFilter(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
    }

    @Test
    void nonFoodAiEndpointUsesGenericWindowLimit() throws Exception {
        when(valueOperations.increment(org.mockito.ArgumentMatchers.startsWith("rate-limit:ai:")))
                .thenReturn(1L);
        ReflectionTestUtils.setField(filter, "maxRequests", 60L);
        ReflectionTestUtils.setField(filter, "windowSeconds", 60L);

        MockHttpServletResponse response = new MockHttpServletResponse();
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/ai/other");

        filter.doFilter(request, response, filterChain);

        assertThat(response.getStatus()).isNotEqualTo(429);
        verify(valueOperations, never())
                .increment(org.mockito.ArgumentMatchers.startsWith("rate-limit:ai-food-scan:"));
    }

    private MockHttpServletRequest foodScanRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/ai/food-calorie-estimate");
        request.setRemoteAddr("127.0.0.1");
        return request;
    }
}
