package com.vfit.modules.progress.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.api.PageResponse;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.progress.dto.response.JourneySnapResponse;
import com.vfit.modules.progress.service.JourneySnapService;
import com.vfit.common.util.SecurityUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/progress/snaps")
@RequiredArgsConstructor
@Tag(name = "Progress Journey Snaps", description = "Endpoints for managing Locket-style progress photos")
public class JourneySnapController {
    private final JourneySnapService journeySnapService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Upload a new journey snap")
    public ApiResponse<JourneySnapResponse> uploadSnap(
            @RequestPart(value = "file", required = false) MultipartFile file,
            @RequestPart(value = "image", required = false) MultipartFile image,
            @RequestPart(value = "note", required = false) String note) {
        String userId = SecurityUtil.requireCurrentUserId();
        MultipartFile upload = file != null ? file : image;
        if (upload == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Image file is required");
        }
        return ApiResponse.created(journeySnapService.uploadSnap(userId, upload, note));
    }

    @GetMapping
    @Operation(summary = "Get current user's journey snaps")
    public ApiResponse<PageResponse<JourneySnapResponse>> getSnaps(Pageable pageable) {
        String userId = SecurityUtil.requireCurrentUserId();
        return ApiResponse.ok(journeySnapService.getSnaps(userId, pageable));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a journey snap")
    public ApiResponse<Void> deleteSnap(@PathVariable("id") String id) {
        String userId = SecurityUtil.requireCurrentUserId();
        journeySnapService.deleteSnap(userId, id);
        return ApiResponse.message("Snap deleted");
    }
}
