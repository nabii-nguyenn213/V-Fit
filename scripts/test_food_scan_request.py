import jwt
import time
import requests
import io

def main():
    secret = "VFITAa123@production_jwt_super_secret_key_2026_nabii_nguyenn213_secure"
    payload = {
        "sub": "6a2fc0e6ab92384a70d5f504",
        "email": "tranduytrung251105@gmail.com",
        "role": "USER",
        "sid": "6a440e2ee7afbe11f85d8a0b",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600
    }
    token = jwt.encode(payload, secret, algorithm="HS512")
    
    # Download potato image from wikimedia
    image_url = "https://upload.wikimedia.org/wikipedia/commons/a/ab/Patates.jpg"
    print(f"[*] Downloading potato image from: {image_url}")
    headers_get = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    }
    img_resp = requests.get(image_url, headers=headers_get)
    if img_resp.status_code != 200:
        print(f"[ERROR] Failed to download sample image, status code: {img_resp.status_code}")
        return
        
    img_bytes = img_resp.content
    
    url = "https://trungtranvfit.id.vn/api/ai/food-calorie-estimate"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    files = {
        "image": ("potato.jpg", img_bytes, "image/jpeg")
    }
    
    print(f"[*] Sending POST request to: {url}")
    try:
        resp = requests.post(url, headers=headers, files=files, timeout=30)
        print(f"[+] Response Code: {resp.status_code}")
        print("[+] Response JSON:")
        safe_str = repr(resp.json()).encode('ascii', errors='backslashreplace').decode('ascii')
        print(safe_str)
    except Exception as e:
        safe_err = str(e).encode('ascii', errors='backslashreplace').decode('ascii')
        print(f"[ERROR] Request failed: {safe_err}")

if __name__ == "__main__":
    main()
