package com.vfit.modules.admin.service;

import com.vfit.modules.admin.dto.SearchMetricItem;
import com.vfit.modules.admin.dto.TrafficMetricsResponse;
import java.util.List;

public interface AdminMetricsService {
    TrafficMetricsResponse getTrafficMetrics(int page, int size);
    List<SearchMetricItem> getSearchMetrics(int limit);
}
