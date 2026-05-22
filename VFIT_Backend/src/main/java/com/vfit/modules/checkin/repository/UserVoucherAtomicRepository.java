package com.vfit.modules.checkin.repository;

import com.vfit.modules.checkin.entity.UserVoucher;
import com.vfit.modules.checkin.entity.UserVoucherStatus;
import java.time.Instant;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class UserVoucherAtomicRepository {
    private final MongoTemplate mongoTemplate;

    public Optional<UserVoucher> redeemAvailableVoucher(
            String userId,
            String code,
            Instant now,
            String orderId) {
        Query query = Query.query(Criteria.where("user_id").is(userId)
                .and("code").is(code)
                .and("status").is(UserVoucherStatus.AVAILABLE)
                .and("expired_at").gt(now));
        Update update = new Update()
                .set("status", UserVoucherStatus.USED)
                .set("used_at", now)
                .set("used_order_id", orderId);
        UserVoucher voucher = mongoTemplate.findAndModify(
                query,
                update,
                FindAndModifyOptions.options().returnNew(true),
                UserVoucher.class);
        return Optional.ofNullable(voucher);
    }
}
