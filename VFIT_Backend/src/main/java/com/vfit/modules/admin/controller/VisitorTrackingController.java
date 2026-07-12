package com.vfit.modules.admin.controller;

import com.vfit.modules.admin.service.VisitorLoggingService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/track")
@RequiredArgsConstructor
public class VisitorTrackingController {

    private final VisitorLoggingService visitorLoggingService;

    @PostMapping("/visit")
    public ResponseEntity<Void> trackVisit(HttpServletRequest request) {
        String ip = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        visitorLoggingService.logVisit(ip, userAgent);
        return ResponseEntity.accepted().build();
    }
}
