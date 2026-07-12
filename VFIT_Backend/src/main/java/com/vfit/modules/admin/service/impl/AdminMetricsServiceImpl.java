package com.vfit.modules.admin.service.impl;

import com.vfit.modules.admin.document.VisitorLog;
import com.vfit.modules.admin.dto.SearchMetricItem;
import com.vfit.modules.admin.dto.TrafficMetricsResponse;
import com.vfit.modules.admin.repository.VisitorLogRepository;
import com.vfit.modules.admin.service.AdminMetricsService;
import com.vfit.modules.nutrition.repository.FoodRepository;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.GroupOperation;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminMetricsServiceImpl implements AdminMetricsService {

    private final VisitorLogRepository visitorLogRepository;
    private final FoodRepository foodRepository;
    private final MongoTemplate mongoTemplate;

    @Override
    public TrafficMetricsResponse getTrafficMetrics(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        long totalVisits = visitorLogRepository.count();
        Page<VisitorLog> logs = visitorLogRepository.findAllByOrderByCreatedAtDesc(pageable);
        
        Map<String, Long> osStats = getGroupStats("os");
        Map<String, Long> browserStats = getGroupStats("browser");

        return TrafficMetricsResponse.builder()
                .totalVisits(totalVisits)
                .logs(logs)
                .osStats(osStats)
                .browserStats(browserStats)
                .build();
    }

    @Override
    public List<SearchMetricItem> getSearchMetrics(int limit) {
        Pageable pageable = PageRequest.of(0, limit);
        return foodRepository.findBySearchCountGreaterThanOrderBySearchCountDesc(0, pageable)
                .stream()
                .map(food -> SearchMetricItem.builder()
                        .keyword(food.getName())
                        .searchCount(food.getSearchCount())
                        .build())
                .toList();
    }

    private Map<String, Long> getGroupStats(String field) {
        GroupOperation groupByField = Aggregation.group(field).count().as("count");
        Aggregation aggregation = Aggregation.newAggregation(groupByField);
        List<Map> results = mongoTemplate.aggregate(aggregation, VisitorLog.class, Map.class).getMappedResults();
        
        Map<String, Long> stats = new HashMap<>();
        for (Map r : results) {
            String key = (String) r.get("_id");
            if (key == null) {
                key = "Unknown";
            }
            Long count = ((Number) r.get("count")).longValue();
            stats.put(key, count);
        }
        return stats;
    }
}
