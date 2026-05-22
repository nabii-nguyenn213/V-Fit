package com.vfit.modules.checkin.service;

import com.vfit.modules.checkin.dto.response.CheckinResponse;
import com.vfit.modules.checkin.dto.response.CheckinStatusResponse;

public interface CheckinService {
    CheckinResponse checkin(String userId);
    CheckinStatusResponse getCheckinStatus(String userId);
}
