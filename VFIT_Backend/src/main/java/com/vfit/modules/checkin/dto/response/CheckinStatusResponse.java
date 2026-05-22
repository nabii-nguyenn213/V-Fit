package com.vfit.modules.checkin.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class CheckinStatusResponse {
    private boolean checkedToday;
    private long monthCheckinCount;
}
