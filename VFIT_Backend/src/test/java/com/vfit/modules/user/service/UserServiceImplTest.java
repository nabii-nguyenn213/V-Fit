package com.vfit.modules.user.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.AppException;
import com.vfit.bootstrap.storage.FileStorageService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.impl.UserServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {
    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private UserMapper userMapper;
    @Mock
    private FileStorageService fileStorageService;
    @InjectMocks
    private UserServiceImpl userService;

    @Test
    void createLocalUserStoresNormalizedEmailAndHashedPassword() {
        when(userRepository.existsByEmail("member@vfit.com")).thenReturn(false);
        when(passwordEncoder.encode("Password1")).thenReturn("hash");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User user = userService.createLocalUser("Member@VFIT.com", "Password1", "Member", RoleName.USER);

        assertThat(user.getEmail()).isEqualTo("member@vfit.com");
        assertThat(user.getPasswordHash()).isEqualTo("hash");
        assertThat(user.getRole()).isEqualTo(RoleName.USER);
        assertThat(user.getOnboardingStatus()).isEqualTo(OnboardingStatus.PENDING);
        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().isActive()).isFalse();
    }

    @Test
    void createLocalUserRejectsDuplicateEmail() {
        when(userRepository.existsByEmail("member@vfit.com")).thenReturn(true);

        assertThatThrownBy(() -> userService.createLocalUser("member@vfit.com", "Password1", "Member", RoleName.USER))
                .isInstanceOf(AppException.class)
                .hasMessage("Email already exists");
    }
}
