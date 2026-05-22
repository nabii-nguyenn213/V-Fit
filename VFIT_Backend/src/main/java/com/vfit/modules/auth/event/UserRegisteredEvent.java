package com.vfit.modules.auth.event;

public record UserRegisteredEvent(String userId, String email) {
}
