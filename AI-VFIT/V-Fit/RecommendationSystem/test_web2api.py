import requests
import json

url = "http://127.0.0.1:8082/v1/chat/completions"
payload = {
    "model": "gemini-3.5-flash",
    "messages": [
        {
            "role": "user",
            "content": "Hello, write a 1-word greeting"
        }
    ]
}
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer anything"
}

try:
    response = requests.post(url, headers=headers, json=payload, timeout=10)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
