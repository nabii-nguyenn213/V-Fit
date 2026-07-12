package com.vfit.modules.admin.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SearchMetricItem {
    private final String keyword;
    private final int searchCount;
}
