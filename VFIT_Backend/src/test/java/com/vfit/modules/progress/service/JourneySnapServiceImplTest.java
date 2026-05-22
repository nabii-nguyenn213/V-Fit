package com.vfit.modules.progress.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vfit.common.exception.AppException;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.bootstrap.storage.FileStorageService;
import com.vfit.modules.progress.document.JourneySnap;
import com.vfit.modules.progress.dto.response.JourneySnapResponse;
import com.vfit.modules.progress.mapper.JourneySnapMapper;
import com.vfit.modules.progress.repository.JourneySnapRepository;
import com.vfit.modules.progress.service.impl.JourneySnapServiceImpl;
import com.vfit.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

@ExtendWith(MockitoExtension.class)
class JourneySnapServiceImplTest {
    @Mock
    private JourneySnapRepository journeySnapRepository;
    @Mock
    private FileStorageService fileStorageService;
    @Mock
    private UserRepository userRepository;
    @Mock
    private org.springframework.context.ApplicationEventPublisher eventPublisher;

    private JourneySnapServiceImpl journeySnapService;

    @BeforeEach
    void setUp() {
        AppProperties appProperties = new AppProperties();
        appProperties.setBaseUrl("http://localhost:8080");
        appProperties.getStorage().setUploadDir("uploads");

        journeySnapService = new JourneySnapServiceImpl(
                journeySnapRepository,
                fileStorageService,
                new JourneySnapMapper(),
                appProperties,
                userRepository,
                eventPublisher);
    }

    @Test
    void uploadSnapStoresRelativePhotoPathForExistingUser() {
        MockMultipartFile file = new MockMultipartFile("file", "progress.jpg", "image/jpeg", "image".getBytes());

        when(userRepository.existsById("user-1")).thenReturn(true);
        when(fileStorageService.store(file, "snaps")).thenReturn("snaps/progress.jpg");
        when(journeySnapRepository.save(any(JourneySnap.class))).thenAnswer(invocation -> {
            JourneySnap snap = invocation.getArgument(0);
            snap.setId("snap-1");
            return snap;
        });

        JourneySnapResponse response = journeySnapService.uploadSnap("user-1", file, "day 1");

        assertThat(response.getId()).isEqualTo("snap-1");
        assertThat(response.getPhotoUrl()).isEqualTo("http://localhost:8080/uploads/snaps/progress.jpg");
        ArgumentCaptor<JourneySnap> captor = ArgumentCaptor.forClass(JourneySnap.class);
        verify(journeySnapRepository).save(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo("user-1");
        assertThat(captor.getValue().getPhotoUrl()).isEqualTo("snaps/progress.jpg");
        assertThat(captor.getValue().getNote()).isEqualTo("day 1");
    }

    @Test
    void uploadSnapRejectsMissingUser() {
        MockMultipartFile file = new MockMultipartFile("file", "progress.jpg", "image/jpeg", "image".getBytes());

        when(userRepository.existsById("user-1")).thenReturn(false);

        assertThatThrownBy(() -> journeySnapService.uploadSnap("user-1", file, null))
                .isInstanceOf(AppException.class)
                .hasMessage("User not found");
        verify(fileStorageService, never()).store(any(), any());
        verify(journeySnapRepository, never()).save(any());
    }
}
