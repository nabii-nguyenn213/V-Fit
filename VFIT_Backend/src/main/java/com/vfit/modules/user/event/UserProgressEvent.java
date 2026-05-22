package com.vfit.modules.user.event;

public record UserProgressEvent(String userId, int xpDelta, String reason) {
}
