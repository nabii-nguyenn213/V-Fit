package com.vfit.bootstrap.storage;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.infrastructure.config.AppProperties;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@Slf4j
public class LocalFileStorageService implements FileStorageService {
    private final Path uploadRoot;

    public LocalFileStorageService(AppProperties appProperties) {
        this.uploadRoot = Path.of(appProperties.getStorage().getUploadDir()).toAbsolutePath().normalize();
    }

    @Override
    public String store(MultipartFile file, String directory) {
        if (file.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Cannot store empty file");
        }
        String original = StringUtils.cleanPath(file.getOriginalFilename() == null ? "file" : file.getOriginalFilename());
        String filename = UUID.randomUUID() + "-" + original.replaceAll("[^a-zA-Z0-9._-]", "_");
        Path targetDir = uploadRoot.resolve(directory).normalize();
        Path target = targetDir.resolve(filename).normalize();
        if (!target.startsWith(uploadRoot)) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Invalid storage path");
        }
        try {
            Files.createDirectories(targetDir);
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, target, StandardCopyOption.REPLACE_EXISTING);
            }
            return uploadRoot.relativize(target).toString().replace("\\", "/");
        } catch (IOException ex) {
            log.error("Could not store uploaded file at {}", target, ex);
            throw new AppException(ErrorCode.INTERNAL_ERROR, "Could not store file");
        }
    }
}
