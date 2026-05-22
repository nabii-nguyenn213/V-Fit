package com.vfit.modules.nutrition.repository;

import com.vfit.modules.nutrition.entity.Food;
import java.text.Normalizer;
import java.util.List;
import java.util.regex.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class FoodSearchRepositoryImpl implements FoodSearchRepository {
    private final MongoTemplate mongoTemplate;

    @Override
    public List<Food> searchByKeyword(String keyword, int limit) {
        String normalizedKeyword = keyword.trim();
        String asciiKeyword = normalizeForSearch(normalizedKeyword);
        String startsWithPattern = "^" + Pattern.quote(normalizedKeyword);
        String normalizedStartsWithPattern = "^" + Pattern.quote(asciiKeyword);
        Query regexQuery = new Query()
                .addCriteria(new Criteria().orOperator(
                        Criteria.where("name").regex(startsWithPattern, "i"),
                        Criteria.where("normalized_name").regex(normalizedStartsWithPattern, "i")))
                .with(Sort.by(
                        Sort.Order.desc("popularityScore"),
                        Sort.Order.desc("searchCount")))
                .limit(limit);
        return mongoTemplate.find(regexQuery, Food.class);
    }

    private String normalizeForSearch(String value) {
        String replaced = value.replace('Đ', 'D').replace('đ', 'd');
        String decomposed = Normalizer.normalize(replaced, Normalizer.Form.NFD);
        return decomposed
                .replaceAll("\\p{M}", "")
                .replaceAll("\\s+", " ")
                .trim()
                .toLowerCase();
    }
}
