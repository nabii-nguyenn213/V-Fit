import json
import base64
import requests
from config import GEMINI_API_KEY, GEMINI_URL


def clean_json(text: str):
    text = text.replace("```json", "").replace("```", "").strip()
    return json.loads(text)


def gemini_text(prompt: str):
    if not GEMINI_API_KEY:
        raise Exception("Missing GEMINI_API_KEY in .env")

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ]
    }

    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY
    }

    response = requests.post(
        GEMINI_URL,
        headers=headers,
        json=payload,
        timeout=60
    )

    if response.status_code != 200:
        raise Exception(response.text)

    data = response.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]


def gemini_json(prompt: str):
    text = gemini_text(prompt)
    return clean_json(text)


def gemini_image_json(image_bytes: bytes, prompt: str):
    if not GEMINI_API_KEY:
        raise Exception("Missing GEMINI_API_KEY in .env")

    image_base64 = base64.b64encode(image_bytes).decode("utf-8")

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt},
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": image_base64
                        }
                    }
                ]
            }
        ]
    }

    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY
    }

    response = requests.post(
        GEMINI_URL,
        headers=headers,
        json=payload,
        timeout=60
    )

    if response.status_code != 200:
        raise Exception(response.text)

    data = response.json()
    text = data["candidates"][0]["content"]["parts"][0]["text"]

    return clean_json(text)