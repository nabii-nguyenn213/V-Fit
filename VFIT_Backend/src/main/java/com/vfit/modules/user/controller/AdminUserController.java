package com.vfit.modules.user.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.api.PageResponse;
import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.service.UserQueryService;
import com.vfit.modules.user.service.UserService;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {
    private final UserQueryService userQueryService;
    private final UserService userService;

    @GetMapping
    public ApiResponse<PageResponse<UserResponse>> users(
            @RequestParam(required = false) RoleName role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(PageResponse.from(userQueryService.getUsers(role, PageRequest.of(page, size))));
    }

    @PutMapping("/{id}/role")
    public ApiResponse<Void> updateRole(@PathVariable String id, @RequestBody UpdateRoleRequest request) {
        userService.updateRole(id, request.getRole());
        return ApiResponse.message("Role updated");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteUser(@PathVariable String id) {
        userService.deleteUser(id);
        return ApiResponse.message("User deactivated");
    }

    @Getter
    @Setter
    public static class UpdateRoleRequest {
        @NotNull
        private RoleName role;
    }
}
