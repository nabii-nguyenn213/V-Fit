package com.vfit.modules.admin_dashboard.repository;

import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueAggregationResult;
import com.vfit.modules.admin_dashboard.entity.Order;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.Aggregation;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface OrderRepository extends MongoRepository<Order, String> {

    @Aggregation(pipeline = {
        "{ '$match': { 'status': 'SUCCESS' } }",
        "{ '$project': { 'month': { '$dateToString': { 'format': '%Y-%m', 'date': '$created_at', 'timezone': 'Asia/Ho_Chi_Minh' } }, 'amount': 1 } }",
        "{ '$group': { '_id': '$month', 'totalRevenue': { '$sum': '$amount' }, 'totalOrders': { '$sum': 1 } } }",
        "{ '$sort': { '_id': 1 } }"
    })
    List<MonthlyRevenueAggregationResult> aggregateMonthlyRevenue();

    List<Order> findTop5ByStatusOrderByCreatedAtDesc(String status);
    org.springframework.data.domain.Page<Order> findByStatusOrderByCreatedAtDesc(String status, Pageable pageable);
}
