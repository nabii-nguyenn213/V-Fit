package com.vfit.modules.auth.repository;

import com.vfit.modules.auth.document.EmailOtp;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EmailOtpRepository extends MongoRepository<EmailOtp, String> {
    Optional<EmailOtp> findByEmail(String email);
    void deleteByEmail(String email);
}
