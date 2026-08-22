package com.vfit.modules.user.service.impl;

import com.vfit.common.enums.RoleName;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.support.PageableExecutionUtils;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserQueryServiceImpl implements UserQueryService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final MongoTemplate mongoTemplate;

    @Override
    public UserResponse getCurrentUser() {
        String userId = SecurityUtil.requireCurrentUserId();
        return userRepository.findById(userId).map(userMapper::toResponse)
                .orElseThrow(() -> new com.vfit.common.exception.ResourceNotFoundException("User not found"));
    }

    @Override
    public Page<UserResponse> getUsers(RoleName role, String filter, String search, String startDate, String endDate, Pageable pageable) {
        Query query = new Query();
        List<Criteria> criteriaList = new ArrayList<>();

        if (role != null) {
            criteriaList.add(Criteria.where("role").is(role));
        }

        if ("VIP".equalsIgnoreCase(filter)) {
            criteriaList.add(Criteria.where("subscription.status").is("ACTIVE"));
            criteriaList.add(Criteria.where("subscription.planCode").in("VIP_MONTHLY", "VIP_YEARLY", "MONTHLY", "YEARLY"));
        }

        if (search != null && !search.trim().isEmpty()) {
            String keyword = search.trim();
            criteriaList.add(new Criteria().orOperator(
                Criteria.where("email").regex(keyword, "i"),
                Criteria.where("fullName").regex(keyword, "i")
            ));
        }

        if (startDate != null && !startDate.trim().isEmpty()) {
            try {
                Instant start = Instant.parse(startDate.trim());
                criteriaList.add(Criteria.where("createdAt").gte(start));
            } catch (Exception e) {
                // Ignore parse error
            }
        }
        if (endDate != null && !endDate.trim().isEmpty()) {
            try {
                Instant end = Instant.parse(endDate.trim());
                criteriaList.add(Criteria.where("createdAt").lte(end));
            } catch (Exception e) {
                // Ignore parse error
            }
        }

        if (!criteriaList.isEmpty()) {
            query.addCriteria(new Criteria().andOperator(criteriaList.toArray(new Criteria[0])));
        }

        long total = mongoTemplate.count(query, User.class);
        List<User> users = mongoTemplate.find(query.with(pageable), User.class);

        return PageableExecutionUtils.getPage(
                users,
                pageable,
                () -> total
        ).map(userMapper::toResponse);
    }
}
