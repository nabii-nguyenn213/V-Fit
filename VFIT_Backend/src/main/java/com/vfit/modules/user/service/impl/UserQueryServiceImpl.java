package com.vfit.modules.user.service.impl;

import com.vfit.common.enums.RoleName;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.UserQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserQueryServiceImpl implements UserQueryService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Override
    public UserResponse getCurrentUser() {
        String userId = SecurityUtil.requireCurrentUserId();
        return userRepository.findById(userId).map(userMapper::toResponse)
                .orElseThrow(() -> new com.vfit.common.exception.ResourceNotFoundException("User not found"));
    }

    @Override
    public Page<UserResponse> getUsers(RoleName role, Pageable pageable) {
        if (role == null) {
            return userRepository.findAll(pageable).map(userMapper::toResponse);
        }
        return userRepository.findByRole(role, pageable).map(userMapper::toResponse);
    }
}
