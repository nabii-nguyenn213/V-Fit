import jwt
import time
import websocket

def test_url(url):
    print(f"[*] Connecting to: {url}")
    try:
        ws = websocket.create_connection(url, timeout=15)
        print(f"[+] Connected successfully! Protocol status: {ws.status}")
        ws.close()
    except Exception as e:
        print(f"[ERROR] Connection failed: {e}")

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
    
    url_body = f"wss://trungtranvfit.id.vn/ws/ai/body-analysis?token={token}"
    url_form = f"wss://trungtranvfit.id.vn/ws/ai/form-check?token={token}&exerciseId=squat&cameraView=side"
    
    print("--- Testing Body Analysis WS ---")
    test_url(url_body)
    
    print("\n--- Testing Form Check WS ---")
    test_url(url_form)

if __name__ == "__main__":
    main()

