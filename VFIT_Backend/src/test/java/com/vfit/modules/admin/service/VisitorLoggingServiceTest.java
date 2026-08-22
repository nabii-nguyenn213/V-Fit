package com.vfit.modules.admin.service;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.vfit.modules.admin.document.VisitorLog;
import com.vfit.modules.admin.repository.VisitorLogRepository;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

class VisitorLoggingServiceTest {

    @Mock
    private VisitorLogRepository visitorLogRepository;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private VisitorLoggingService visitorLoggingService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void shouldIgnoreBotUserAgents() {
        visitorLoggingService.logVisit("192.168.1.1", "Googlebot/2.1 (+http://www.google.com/bot.html)");
        verifyNoInteractions(visitorLogRepository);
    }

    @Test
    void shouldRateLimitWhenRequestsExceedLimit() {
        when(valueOperations.increment(any(String.class))).thenReturn(25L);
        visitorLoggingService.logVisit("192.168.1.1", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0");
        verifyNoInteractions(visitorLogRepository);
    }

    @Test
    void shouldDeduplicateVisitsWithin60Seconds() {
        when(valueOperations.increment(any(String.class))).thenReturn(1L);
        // First request is a duplicate (setIfAbsent returns false)
        when(valueOperations.setIfAbsent(any(String.class), any(String.class), any(Duration.class))).thenReturn(false);

        visitorLoggingService.logVisit("192.168.1.1", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0");
        verifyNoInteractions(visitorLogRepository);
    }

    @Test
    void shouldLogNewVisitSuccessfully() {
        when(valueOperations.increment(any(String.class))).thenReturn(1L);
        // New visit (setIfAbsent returns true)
        when(valueOperations.setIfAbsent(any(String.class), any(String.class), any(Duration.class))).thenReturn(true);

        visitorLoggingService.logVisit("192.168.1.1", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0");
        verify(visitorLogRepository, times(1)).save(any(VisitorLog.class));
    }
}
