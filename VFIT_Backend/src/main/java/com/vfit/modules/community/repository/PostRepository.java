package com.vfit.modules.community.repository;

import com.vfit.modules.community.document.Post;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface PostRepository extends MongoRepository<Post, String> {
}
