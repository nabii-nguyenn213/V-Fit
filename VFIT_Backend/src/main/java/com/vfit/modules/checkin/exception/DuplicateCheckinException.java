package com.vfit.modules.checkin.exception;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;

public class DuplicateCheckinException extends AppException {
    public DuplicateCheckinException(String message) {
        super(ErrorCode.CONFLICT, message);
    }
}
