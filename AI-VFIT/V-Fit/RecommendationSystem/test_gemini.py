import os
import requests
from dotenv import load_dotenv

load_dotenv()

key = os.getenv("GEMINI_API_KEY")
print(f"Loaded Key: {key}")

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={key}"
payload = {
    "contents": [{"parts": [{"text": "Hello, write a 1-word greeting"}]}]
}
headers = {"Content-Type": "application/json"}

try:
    response = requests.post(url, headers=headers, json=payload)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
