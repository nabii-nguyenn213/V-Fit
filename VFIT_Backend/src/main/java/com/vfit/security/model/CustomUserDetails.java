package com.vfit.security.model;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.document.User;
import java.util.Collection;
import java.util.List;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

@Getter
public class CustomUserDetails implements UserDetails {
    private final String id;
    private final String email;
    private final String password;
    private final RoleName role;
    private final OnboardingStatus onboardingStatus;
    private final boolean active;

    public CustomUserDetails(User user) {
        this.id = user.getId();
        this.email = user.getEmail();
        this.password = user.getPasswordHash();
        this.role = user.getRole();
        this.onboardingStatus = user.getOnboardingStatus() != null
                ? user.getOnboardingStatus()
                : user.isActive() ? OnboardingStatus.COMPLETED : OnboardingStatus.PENDING;
        this.active = user.isActive();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        RoleName effectiveRole = role == RoleName.ADMIN ? RoleName.ADMIN : RoleName.USER;
        return List.of(new SimpleGrantedAuthority("ROLE_" + effectiveRole.name()));
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return active || onboardingStatus == OnboardingStatus.PENDING;
    }

    @Override
    public boolean isAccountNonLocked() {
        return active || onboardingStatus == OnboardingStatus.PENDING;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return active || onboardingStatus == OnboardingStatus.PENDING;
    }

    @Override
    public boolean isEnabled() {
        return active || onboardingStatus == OnboardingStatus.PENDING;
    }
}
