"""
Gemini Client for V-Fit Recommendation System.

Strategy (in order of priority):
  1. Official Gemini REST API  — if GEMINI_API_KEY is set and valid
  2. gemini-web2api proxy      — text-only; image payload is ignored by proxy
  3. Graceful mock fallback    — returns structured dummy data so the app
                                 never receives a crash 500 or an empty body
"""

import json
import os
import sys
import requests
from dotenv import load_dotenv

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass
if hasattr(sys.stderr, 'reconfigure'):
    try:
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

load_dotenv()

# ── Config ────────────────────────────────────────────────────────────────────
GEMINI_API_KEY_RAW: str = os.getenv("GEMINI_API_KEY", "").strip()
API_KEYS: list = [k.strip() for k in GEMINI_API_KEY_RAW.split(",") if k.strip() and k.strip().lower() not in ("none", "")]
WEB2API_URL: str = os.getenv("WEB2API_URL", "http://localhost:8082/v1/chat/completions")
GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
REQUEST_TIMEOUT: int = int(os.getenv("REQUEST_TIMEOUT", 60))

_DIRECT_BASE = "https://generativelanguage.googleapis.com/v1beta/models"


# ── Helpers ──────────────────────────────────────────────────────────────────

def _has_valid_key() -> bool:
    return len(API_KEYS) > 0


def clean_json(text: str) -> dict:
    """Strip markdown fences and parse the first JSON object found."""
    text = text.strip()
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end != -1:
        text = text[start:end + 1]
    return json.loads(text)


# ── Strategy 1 – Official Gemini REST API ─────────────────────────────────────

def _direct_text(prompt: str) -> str:
    errors = []
    for key in API_KEYS:
        url = f"{_DIRECT_BASE}/{GEMINI_MODEL}:generateContent?key={key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}]
        }
        try:
            r = requests.post(url, json=payload, timeout=REQUEST_TIMEOUT)
            r.raise_for_status()
            data = r.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except Exception as e:
            errors.append(f"Key {key[:10]}... failed: {e}")
            print(f"[GeminiClient] Direct text request failed with key {key[:10]}...: {e}")
            continue
    raise RuntimeError(f"All API keys failed for direct text request: {errors}")


def _direct_image(prompt: str, image_base64: str, mime_type: str = "image/jpeg") -> str:
    errors = []
    for key in API_KEYS:
        url = f"{_DIRECT_BASE}/{GEMINI_MODEL}:generateContent?key={key}"
        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": mime_type,
                                "data": image_base64,
                            }
                        },
                    ]
                }
            ]
        }
        try:
            r = requests.post(url, json=payload, timeout=REQUEST_TIMEOUT)
            r.raise_for_status()
            data = r.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except Exception as e:
            errors.append(f"Key {key[:10]}... failed: {e}")
            print(f"[GeminiClient] Direct image request failed with key {key[:10]}...: {e}")
            continue
    raise RuntimeError(f"All API keys failed for direct image request: {errors}")



# ── Strategy 2 – gemini-web2api proxy (OpenAI-compat, text only) ─────────────

def _proxy_text(prompt: str) -> str:
    payload = {
        "model": GEMINI_MODEL,
        "messages": [{"role": "user", "content": prompt}],
    }
    r = requests.post(
        WEB2API_URL,
        headers={"Content-Type": "application/json", "Authorization": "Bearer anything"},
        json=payload,
        timeout=REQUEST_TIMEOUT,
    )
    if r.status_code != 200:
        raise RuntimeError(f"web2api error {r.status_code}: {r.text[:300]}")
    data = r.json()
    content = data["choices"][0]["message"]["content"]
    # Detect "please upload image" style non-answers and reject them
    lowered = content.lower()
    if any(kw in lowered for kw in ("forgot to attach", "please upload", "attach an image", "no image", "can't see")):
        raise RuntimeError("web2api proxy cannot process images in anonymous mode")
    return content


# ── Strategy 3 – Mock fallback ───────────────────────────────────────────────

_MOCK_FOOD_RESPONSE = {
    "food_name": "AI Unavailable",
    "portion_estimate": "1 serving",
    "total_calories": 0,
    "protein_g": 0.0,
    "carbs_g": 0.0,
    "fat_g": 0.0,
    "confidence": 0.0,
    "note": "AI service is temporarily unavailable. Please enter nutrition manually.",
    "items": [],
}

_MOCK_TEXT_RESPONSE = {
    "food_name": "AI Unavailable",
    "portion": "1 serving",
    "total_calories": 0,
    "protein_g": 0.0,
    "carbs_g": 0.0,
    "fat_g": 0.0,
    "confidence": 0.0,
    "note": "AI service is temporarily unavailable.",
}


# ── Public API ────────────────────────────────────────────────────────────────

def gemini_text(prompt: str) -> str:
    """Return raw text from Gemini (best-effort). Tries proxy first, then direct API."""
    try:
        return _proxy_text(prompt)
    except Exception as e:
        print(f"[GeminiClient] Proxy failed: {e}. Trying direct API.")
        
    if _has_valid_key():
        try:
            return _direct_text(prompt)
        except Exception as e:
            print(f"[GeminiClient] Direct API failed: {e}.")
            raise
    else:
        raise RuntimeError("No valid Gemini API key found for text fallback.")


def gemini_json(prompt: str) -> dict:
    """Return parsed JSON dict from Gemini. Falls back to a mock on total failure."""
    try:
        text = gemini_text(prompt)
        return clean_json(text)
    except Exception as e:
        print(f"[GeminiClient] gemini_json failed entirely: {e}. Returning mock.")
        return _MOCK_TEXT_RESPONSE


def web2api_image(prompt: str, image_base64: str, mime_type: str = "image/jpeg") -> str:
    """Send image+prompt. Tries direct API first (if key is present), then falls back to proxy, then raises."""
    if _has_valid_key():
        try:
            result = _direct_image(prompt, image_base64, mime_type)
            print(f"[GeminiClient] Direct image API succeeded.")
            return result
        except Exception as e:
            print(f"[GeminiClient] Direct image API failed: {e}. Falling back to proxy.")

    try:
        # Try proxy as fallback
        text_only_prompt = (
            prompt
            + "\n\n(Lưu ý: Không có ảnh được cung cấp. Hãy trả về dữ liệu mặc định.)"
        )
        result = _proxy_text(text_only_prompt)
        print(f"[GeminiClient] Proxy text fallback succeeded.")
        return result
    except Exception as e:
        print(f"[GeminiClient] Proxy failed: {e}.")
        raise RuntimeError(f"All image scan methods failed. Last error: {e}")




def gemini_image_json(prompt: str, image_base64: str, mime_type: str = "image/jpeg") -> dict:
    """
    Return parsed nutrition JSON from an image scan.
    Never raises — always returns a valid dict (may be mock on failure).
    """
    try:
        text = web2api_image(prompt, image_base64, mime_type)
        try:
            print(f"[GeminiClient] Raw image response (first 300 chars): {text[:300]}")
        except Exception:
            try:
                safe_text = text[:300].encode('ascii', errors='ignore').decode('ascii')
                print(f"[GeminiClient] Raw image response (first 300 chars, safe-ascii): {safe_text}")
            except Exception:
                pass
        return clean_json(text)
    except json.JSONDecodeError as e:
        print(f"[GeminiClient] JSON parse error: {e}. Returning mock.")
    except Exception as e:
        try:
            print(f"[GeminiClient] gemini_image_json failed: {e}. Returning mock.")
        except Exception:
            print("[GeminiClient] gemini_image_json failed with encoding error. Returning mock.")
    return _MOCK_FOOD_RESPONSE