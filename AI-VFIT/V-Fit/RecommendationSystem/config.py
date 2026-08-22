import os
from dotenv import load_dotenv

load_dotenv()

# The API key used to authenticate with Google Gemini (or the proxy)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

# The model to use for nutrition estimation
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")

# Toggle to enforce proxy usage (e.g. when using gemini-web2api or an internal gateway)
USE_GEMINI_PROXY = os.getenv("USE_GEMINI_PROXY", "false").lower() == "true"

# Proxy URL (defaults to localhost port 8082 for local development via web2api)
GEMINI_PROXY_URL = os.getenv("GEMINI_PROXY_URL", "http://127.0.0.1:8082")

# Construct the endpoint URL dynamically based on environment
if USE_GEMINI_PROXY or not GEMINI_API_KEY or GEMINI_API_KEY.lower() == "none":
    # Routed through the local/enterprise proxy
    GEMINI_URL = f"{GEMINI_PROXY_URL}/v1beta/models/{GEMINI_MODEL}:generateContent"
else:
    # Routed directly to Google's official Gemini API
    GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
