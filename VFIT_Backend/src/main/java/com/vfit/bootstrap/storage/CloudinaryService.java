package com.vfit.bootstrap.storage;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import java.io.IOException;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@Slf4j
@RequiredArgsConstructor
public class CloudinaryService {

    private final Cloudinary cloudinary;

    @jakarta.annotation.PostConstruct
    public void init() {
        log.info("Kiểm tra cấu hình và kết nối Cloudinary...");
        if (checkConnection()) {
            log.info("Kết nối Cloudinary thành công!");
        } else {
            log.error("Kết nối Cloudinary thất bại! Vui lòng kiểm tra lại CLOUD_NAME, API_KEY và API_SECRET trong file .env.");
        }
    }

    public boolean checkConnection() {
        try {
            cloudinary.api().ping(ObjectUtils.emptyMap());
            return true;
        } catch (Exception e) {
            log.error("Cloudinary ping failed: {}", e.getMessage());
            return false;
        }
    }

    public String upload(MultipartFile file, String folder) {
        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "File is empty");
        }
        try {
            Map<?, ?> uploadResult = cloudinary.uploader().upload(
                    file.getBytes(),
                    ObjectUtils.asMap(
                            "folder", "vfit/" + folder,
                            "resource_type", "auto"
                    )
            );
            return (String) uploadResult.get("secure_url");
        } catch (IOException e) {
            log.error("Cloudinary upload failed", e);
            throw new AppException(ErrorCode.INTERNAL_ERROR, "Đăng tải ảnh lên Cloudinary thất bại: " + e.getMessage());
        }
    }
}
