package com.vfit.modules.auth.mapper;

import com.vfit.modules.auth.dto.response.AuthResponse;
import com.vfit.modules.auth.dto.response.TokenResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface AuthMapper {
    default AuthResponse toAuthResponse(UserResponse user, TokenResponse tokens) {
        return AuthResponse.builder().user(user).tokens(tokens).build();
    }
}
