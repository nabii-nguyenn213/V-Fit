package com.vfit.modules.checkin.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.checkin.dto.response.CheckinResponse;
import com.vfit.modules.checkin.dto.response.CheckinStatusResponse;
import com.vfit.modules.checkin.service.CheckinService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/checkin")
@RequiredArgsConstructor
@Tag(name = "Daily Check-in", description = "Daily check-in and voucher rewards")
public class CheckinController {
    private final CheckinService checkinService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Daily check-in once per Asia/Ho_Chi_Minh day")
    public ApiResponse<CheckinResponse> checkin() {
        return ApiResponse.created(checkinService.checkin(SecurityUtil.requireCurrentUserId()));
    }

    @GetMapping("/status")
    @Operation(summary = "Get daily check-in status for current month")
    public ApiResponse<CheckinStatusResponse> getCheckinStatus() {
        return ApiResponse.ok(checkinService.getCheckinStatus(SecurityUtil.requireCurrentUserId()));
    }
}
