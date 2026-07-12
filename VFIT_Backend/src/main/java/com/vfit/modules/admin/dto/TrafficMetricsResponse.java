package com.vfit.modules.admin.dto;

import com.vfit.modules.admin.document.VisitorLog;
import java.util.Map;
import lombok.Builder;
import lombok.Getter;
import org.springframework.data.domain.Page;

@Getter
@Builder
public class TrafficMetricsResponse {
    private final long totalVisits;
    private final Page<VisitorLog> logs;
    private final Map<String, Long> osStats;
    private final Map<String, Long> browserStats;
}
