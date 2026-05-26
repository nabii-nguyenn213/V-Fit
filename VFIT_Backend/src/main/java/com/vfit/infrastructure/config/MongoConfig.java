package com.vfit.infrastructure.config;

import com.mongodb.client.model.IndexOptions;
import org.bson.Document;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@Configuration
@EnableMongoRepositories(basePackages = "com.vfit")
public class MongoConfig {
    @Bean
    ApplicationRunner exerciseCatalogIndexes(MongoTemplate mongoTemplate) {
        return args -> {
            mongoTemplate.getCollection("exercise_catalogs")
                    .createIndex(
                            new Document("locale", 1).append("active", 1),
                            new IndexOptions()
                                    .name("ux_exercise_catalog_active_locale")
                                    .unique(true)
                                    .partialFilterExpression(new Document("active", true)));
            mongoTemplate.getCollection("exercise_catalogs")
                    .createIndex(
                            new Document("groups.name", "text")
                                    .append("groups.subGroups.name", "text")
                                    .append("groups.subGroups.exercises.name", "text"),
                            new IndexOptions().name("txt_exercise_catalog_search"));
            mongoTemplate.getCollection("foods")
                    .createIndex(
                            new Document("name", 1),
                            new IndexOptions().name("idx_food_name"));
            mongoTemplate.getCollection("foods")
                    .createIndex(
                            new Document("normalized_name", 1),
                            new IndexOptions().name("idx_food_normalized_name"));
            mongoTemplate.getCollection("foods")
                    .createIndex(
                            new Document("is_gym_friendly", -1).append("popularity_score", -1),
                            new IndexOptions().name("idx_food_gym_friendly_popularity"));
            mongoTemplate.getCollection("checkin_logs")
                    .createIndex(
                            new Document("user_id", 1).append("checkin_date", 1),
                            new IndexOptions().name("ux_checkin_user_date").unique(true));
            mongoTemplate.getCollection("checkin_logs")
                    .createIndex(
                            new Document("user_id", 1).append("month_key", 1),
                            new IndexOptions().name("idx_checkin_user_month"));
            mongoTemplate.getCollection("user_vouchers")
                    .createIndex(
                            new Document("user_id", 1).append("status", 1).append("expired_at", 1),
                            new IndexOptions().name("idx_user_voucher_status_expiry"));
            mongoTemplate.getCollection("payment_orders")
                    .createIndex(
                            new Document("user_id", 1).append("status", 1).append("created_at", -1),
                            new IndexOptions().name("idx_payment_order_user_status_created"));
            mongoTemplate.getCollection("password_reset_tokens")
                    .createIndex(
                            new Document("expiresAt", 1),
                            new IndexOptions().name("idx_password_reset_token_expiry").expireAfter(0L, java.util.concurrent.TimeUnit.SECONDS));
            mongoTemplate.getCollection("user_sessions")
                    .createIndex(
                            new Document("expiresAt", 1),
                            new IndexOptions().name("idx_user_session_expiry").expireAfter(0L, java.util.concurrent.TimeUnit.SECONDS));
            mongoTemplate.getCollection("user_sessions")
                    .createIndex(
                            new Document("userId", 1).append("isRevoked", 1),
                            new IndexOptions().name("idx_user_session_user_revoked"));
        };
    }
}
