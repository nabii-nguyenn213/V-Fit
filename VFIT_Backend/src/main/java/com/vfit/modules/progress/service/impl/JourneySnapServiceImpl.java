package com.vfit.modules.progress.service.impl;

import com.vfit.common.api.PageResponse;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.bootstrap.storage.FileStorageService;
import com.vfit.modules.progress.document.JourneySnap;
import com.vfit.modules.progress.dto.response.JourneySnapResponse;
import com.vfit.modules.progress.mapper.JourneySnapMapper;
import com.vfit.modules.progress.repository.JourneySnapRepository;
import com.vfit.modules.progress.service.JourneySnapService;
import com.vfit.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class JourneySnapServiceImpl implements JourneySnapService {
    private static final int MAX_NOTE_LENGTH = 60;

    private final JourneySnapRepository journeySnapRepository;
    private final FileStorageService fileStorageService;
    private final JourneySnapMapper journeySnapMapper;
    private final AppProperties appProperties;
    private final UserRepository userRepository;
    private final org.springframework.context.ApplicationEventPublisher eventPublisher;

    @Override
    public JourneySnapResponse uploadSnap(String userId, MultipartFile file, String note) {
        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Image file is required");
        }

        if (!userRepository.existsById(userId)) {
            throw new AppException(ErrorCode.RESOURCE_NOT_FOUND, "User not found");
        }

        String relativePath = fileStorageService.store(file, "snaps");

        String sanitizedNote = sanitizeNote(note);

        JourneySnap snap = JourneySnap.builder()
                .userId(userId)
                .photoUrl(relativePath)
                .note(sanitizedNote)
                .build();
        
        JourneySnap savedSnap = journeySnapRepository.save(snap);
        
        eventPublisher.publishEvent(new com.vfit.modules.progress.event.ProgressPhotoUploadedEvent(
                this,
                userId,
                savedSnap.getId(),
                savedSnap.getPhotoUrl(),
                savedSnap.getCreatedAt() != null ? savedSnap.getCreatedAt() : java.time.Instant.now()
        ));

        return journeySnapMapper.toResponse(savedSnap, appProperties.getBaseUrl());
    }

    private String sanitizeNote(String note) {
        if (note == null || note.isBlank()) {
            return null;
        }
        String trimmed = note.trim();
        if (trimmed.length() > MAX_NOTE_LENGTH) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Journey snap note must be 60 characters or fewer");
        }
        return trimmed;
    }

    @Override
    public PageResponse<JourneySnapResponse> getSnaps(String userId, Pageable pageable) {
        Page<JourneySnap> page = journeySnapRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        return PageResponse.from(page.map(snap -> journeySnapMapper.toResponse(snap, appProperties.getBaseUrl())));
    }

    @Override
    public void deleteSnap(String userId, String snapId) {
        JourneySnap snap = journeySnapRepository.findById(snapId)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Snap not found"));
        
        if (!snap.getUserId().equals(userId)) {
            throw new AppException(ErrorCode.FORBIDDEN, "Not authorized to delete this snap");
        }
        
        journeySnapRepository.delete(snap);
        // Note: Actual file deletion from disk could be done here, but we keep it simple for now.
    }
}
