package com.vfit.modules.payment.repository;

import com.vfit.modules.payment.entity.Voucher;
import com.vfit.modules.payment.enums.VoucherStatus;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VoucherRepository extends MongoRepository<Voucher, String> {
    Optional<Voucher> findByCode(String code);

    List<Voucher> findByStatusInAndExpiredAtBefore(Collection<VoucherStatus> statuses, Instant now);
}
