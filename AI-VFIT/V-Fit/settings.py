"""
Production-Ready Configuration Management
Hỗ trợ: development, staging, production environments
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables từ .env file
load_dotenv()

# Xác định environment
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()

# Base directory
BASE_DIR = Path(__file__).resolve().parent

# ==================== ENVIRONMENT DETECTION ====================
DEBUG = ENVIRONMENT == "development"
IS_PRODUCTION = ENVIRONMENT == "production"
IS_STAGING = ENVIRONMENT == "staging"


class Config:
    """Base configuration - chung cho tất cả environments"""
    
    # App Settings
    APP_NAME = "V-Fit AI"
    APP_VERSION = "1.0.0"
    SECRET_KEY = os.getenv("SECRET_KEY", None)  # Will be validated per-environment
    
    # Server Settings
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 5000))
    DEBUG = DEBUG
    
    # Model Paths - SỬ DỤNG ENVIRONMENT VARIABLES
    MODEL_PATHS = {
        "shape": os.getenv("MODEL_PATH_SHAPE", str(BASE_DIR / "bmi_finetuned_model.pth")),
        "pose": os.getenv("MODEL_PATH_POSE", "yolov8n-pose.pt"),
        "rep_counter": os.getenv("MODEL_PATH_REP_COUNTER", str(BASE_DIR / "ai_rep_counter/models/phase_model.pt")),
        "body_detect": os.getenv("MODEL_PATH_BODY_DETECT", str(BASE_DIR / "best.pt")),
    }
    
    # Verify model files exist (except online models like yolov8n-pose.pt)
    @classmethod
    def verify_models(cls):
        """Check if required model files exist"""
        for key, path in cls.MODEL_PATHS.items():
            if key != "pose" and not path.startswith("yolo"):  # Skip online models
                if not os.path.exists(path):
                    raise FileNotFoundError(f"Model file not found: {path}")
    
    # Recommendation System / Gemini API
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
    USE_GEMINI_PROXY = os.getenv("USE_GEMINI_PROXY", "false").lower() == "true"
    
    # Smart defaults for proxy URLs: use Docker service names in containers, localhost in dev
    if USE_GEMINI_PROXY or ENVIRONMENT != "development":
        GEMINI_PROXY_URL = os.getenv("GEMINI_PROXY_URL", "http://gemini-proxy:8082")
        WEB2API_URL = os.getenv("WEB2API_URL", "http://web2api:8085/v1/chat/completions")
    else:
        # Development defaults to localhost
        GEMINI_PROXY_URL = os.getenv("GEMINI_PROXY_URL", "http://127.0.0.1:8082")
        WEB2API_URL = os.getenv("WEB2API_URL", "http://localhost:8085/v1/chat/completions")
    
    # Database (if using)
    # Production MUST use PostgreSQL, not SQLite
    _default_db = "postgresql://localhost/vfit" if ENVIRONMENT == "production" else "sqlite:///app.db"
    DATABASE_URL = os.getenv("DATABASE_URL", _default_db)
    
    # CORS Settings - set reasonable defaults per environment
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Logging
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE = os.getenv("LOG_FILE", str(BASE_DIR / "logs/app.log"))
    LOG_MAX_BYTES = int(os.getenv("LOG_MAX_BYTES", 10 * 1024 * 1024))  # 10MB per file
    LOG_BACKUP_COUNT = int(os.getenv("LOG_BACKUP_COUNT", 5))  # Keep 5 backups
    
    # Retry & Timeout Configuration  
    RETRY_ATTEMPTS = int(os.getenv("RETRY_ATTEMPTS", 3))
    RETRY_DELAY_SEC = float(os.getenv("RETRY_DELAY_SEC", 2.0))
    REQUEST_TIMEOUT_SEC = float(os.getenv("REQUEST_TIMEOUT_SEC", 180.0))
    
    # Request Settings
    MAX_CONTENT_LENGTH = int(os.getenv("MAX_CONTENT_LENGTH", 16 * 1024 * 1024))  # 16MB
    REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", 300))  # 5 minutes
    
    # File Upload Settings
    UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", str(BASE_DIR / "uploads"))
    ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "bmp"}
    MAX_UPLOAD_SIZE = int(os.getenv("MAX_UPLOAD_SIZE", 10 * 1024 * 1024))  # 10MB


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    LOG_LEVEL = "DEBUG"
    CORS_ORIGINS = ["*"]  # Allow all origins in development
    # In development, default to localhost
    HOST = os.getenv("HOST", "localhost")


class StagingConfig(Config):
    """Staging configuration - close to production"""
    DEBUG = False
    LOG_LEVEL = "INFO"
    # In staging, use restricted CORS
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "https://staging.example.com").split(",")


class ProductionConfig(Config):
    """Production configuration - maximum security"""
    DEBUG = False
    LOG_LEVEL = "WARNING"
    
    # Production CORS - MUST be configured via environment variable
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "").split(",")
    if not CORS_ORIGINS or CORS_ORIGINS == [""]:
        raise ValueError("CORS_ORIGINS must be set in production")
    
    # Production requires SECRET_KEY to be set
    SECRET_KEY = os.getenv("SECRET_KEY")
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY environment variable must be set in production")
    
    # Production requires GEMINI_API_KEY
    if not os.getenv("GEMINI_API_KEY"):
        raise ValueError("GEMINI_API_KEY environment variable must be set in production")


# ==================== CONFIG SELECTION ====================
def get_config():
    """Get configuration based on ENVIRONMENT variable"""
    config_map = {
        "development": DevelopmentConfig,
        "staging": StagingConfig,
        "production": ProductionConfig,
    }
    
    config_class = config_map.get(ENVIRONMENT, DevelopmentConfig)
    return config_class


# Load active configuration
config = get_config()

# Create necessary directories
os.makedirs(config.UPLOAD_FOLDER, exist_ok=True)
os.makedirs(os.path.dirname(config.LOG_FILE), exist_ok=True)
