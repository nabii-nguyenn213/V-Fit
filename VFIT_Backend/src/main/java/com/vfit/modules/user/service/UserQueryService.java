package com.vfit.modules.user.service;

import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.dto.response.UserResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface UserQueryService {
    UserResponse getCurrentUser();

    Page<UserResponse> getUsers(RoleName role, Pageable pageable);
}
