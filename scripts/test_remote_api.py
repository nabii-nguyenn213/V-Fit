import urllib.request
import urllib.parse
import json

def test_api():
    url = "http://localhost:8082/v1/chat/completions"
    data = {
        "model": "gemini-3.5-flash",
        "messages": [
            {"role": "user", "content": "hello, response with the word 'SUCCESS' if you get this request"}
        ],
        "stream": False
    }
    
    body = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    print("[*] Sending request to web2api at localhost:8082...")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.status
            content = resp.read().decode("utf-8")
            print(f"[+] HTTP Status: {status}")
            print(f"[+] Response: {content}")
    except Exception as e:
        print(f"[ERROR] Failed to send request: {e}")
        if hasattr(e, 'read'):
            try:
                print(f"[ERROR] Server response: {e.read().decode('utf-8')}")
            except Exception:
                pass

if __name__ == "__main__":
    test_api()
