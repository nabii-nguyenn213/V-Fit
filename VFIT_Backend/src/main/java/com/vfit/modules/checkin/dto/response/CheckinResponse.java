package com.vfit.modules.checkin.dto.response;

import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class CheckinResponse {
    private String checkinDate;
    private String monthKey;
    private long monthCheckinCount;
    private List<VoucherResponse> awardedVouchers;
}
