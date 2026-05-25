package com.vfit.modules.user.service;

import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.request.ChangePasswordRequest;
import com.vfit.modules.user.dto.request.UpdateProfileRequest;
import com.vfit.modules.user.dto.response.BodyMetricResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import org.springframework.web.multipart.MultipartFile;

public interface UserService {
    User createLocalUser(String email, String rawPassword, String fullName, RoleName role);

    UserResponse updateCurrentUser(UpdateProfileRequest request);

    UserResponse uploadCurrentUserAvatar(MultipartFile file);

    void changeCurrentUserPassword(ChangePasswordRequest request);

    BodyMetricResponse getCurrentUserBodyMetrics();

    void updateRole(String userId, RoleName role);

    void deleteUser(String userId);

    java.util.List<com.vfit.modules.auth.dto.response.ActiveSessionResponse> getCurrentUserActiveSessions();

    void revokeSession(String sessionId);
}
