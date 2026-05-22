package com.vfit.modules.payment.exception;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;

public class VoucherValidationException extends AppException {
    public VoucherValidationException(String message) {
        super(ErrorCode.CONFLICT, message);
    }
}
