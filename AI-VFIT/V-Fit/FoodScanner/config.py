import os
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
# Make model name configurable, with sensible default
MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

# Use proxy or direct endpoint based on environment
USE_GEMINI_PROXY = os.getenv("USE_GEMINI_PROXY", "false").lower() == "true"
if USE_GEMINI_PROXY:
    GEMINI_PROXY_URL = os.getenv("GEMINI_PROXY_URL", "http://127.0.0.1:8082")
    GEMINI_URL = f"{GEMINI_PROXY_URL}/v1beta/models/{MODEL}:generateContent"
else:
    GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"