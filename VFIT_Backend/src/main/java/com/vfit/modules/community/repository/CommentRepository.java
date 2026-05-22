package com.vfit.modules.community.repository;

import com.vfit.modules.community.document.Comment;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface CommentRepository extends MongoRepository<Comment, String> {
}
