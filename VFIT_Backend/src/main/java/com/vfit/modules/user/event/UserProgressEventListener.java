package com.vfit.modules.user.event;

import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class UserProgressEventListener {
    private final UserRepository userRepository;

    @EventListener
    public void onUserProgress(UserProgressEvent event) {
        userRepository.findById(event.userId()).ifPresent(user -> {
            User.UserProgress progress = user.getProgress() == null ? User.UserProgress.initial() : user.getProgress();
            progress.setXp(Math.max(0, progress.getXp() + event.xpDelta()));
            progress.setLevel((progress.getXp() / 1000) + 1);
            user.setProgress(progress);
            userRepository.save(user);
        });
    }
}
