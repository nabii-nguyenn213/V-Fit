package com.vfit.modules.checkin.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vfit.modules.checkin.dto.response.CheckinResponse;
import com.vfit.modules.checkin.entity.CheckinLog;
import com.vfit.modules.checkin.exception.DuplicateCheckinException;
import com.vfit.modules.checkin.repository.CheckinLogRepository;
import com.vfit.modules.checkin.repository.UserVoucherRepository;
import com.vfit.modules.checkin.service.impl.CheckinServiceImpl;
import com.vfit.modules.user.repository.UserRepository;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

@ExtendWith(MockitoExtension.class)
class CheckinServiceImplTest {
    @Mock
    private CheckinLogRepository checkinLogRepository;
    @Mock
    private UserVoucherRepository userVoucherRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private StringRedisTemplate redisTemplate;
    @Mock
    private ValueOperations<String, String> valueOperations;

    private CheckinServiceImpl checkinService;

    @BeforeEach
    void setUp() {
        checkinService = new CheckinServiceImpl(
                checkinLogRepository,
                userVoucherRepository,
                userRepository,
                redisTemplate);
    }

    @Test
    void checkinFallsBackToMongoWhenRedisUnavailable() {
        when(userRepository.existsById("user-1")).thenReturn(true);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.setIfAbsent(anyString(), eq("1"), any(Duration.class)))
                .thenThrow(new DataAccessResourceFailureException("redis down"));
        when(checkinLogRepository.save(any(CheckinLog.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(checkinLogRepository.countByUserIdAndMonthKey(eq("user-1"), anyString())).thenReturn(1L);

        CheckinResponse response = checkinService.checkin("user-1");

        assertThat(response.getMonthCheckinCount()).isEqualTo(1);
        assertThat(response.getAwardedVouchers()).isEmpty();
        ArgumentCaptor<CheckinLog> captor = ArgumentCaptor.forClass(CheckinLog.class);
        verify(checkinLogRepository).save(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo("user-1");
        assertThat(captor.getValue().getCheckinDate()).matches("\\d{4}-\\d{2}-\\d{2}");
    }

    @Test
    void checkinRejectsConcurrentClickWhenRedisLockExists() {
        when(userRepository.existsById("user-1")).thenReturn(true);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.setIfAbsent(anyString(), eq("1"), any(Duration.class))).thenReturn(false);

        assertThatThrownBy(() -> checkinService.checkin("user-1"))
                .isInstanceOf(DuplicateCheckinException.class)
                .hasMessage("Điểm danh đang được xử lý, vui lòng không bấm liên tục.");
        verify(checkinLogRepository, never()).save(any());
    }
}
