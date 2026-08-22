import paramiko

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect("103.118.29.205", username="Administrator", password="VFITAa123@")
    
    script = """
import requests
import os
from dotenv import load_dotenv

load_dotenv(r"C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.env.production")
raw_key = os.getenv("GEMINI_API_KEY")
keys = [k.strip() for k in raw_key.split(",") if k.strip()]
model = os.getenv("GEMINI_MODEL")

for idx, key in enumerate(keys):
    print(f"Testing Key {idx}: {key[:15]}...")
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={key}"
    r = requests.get(url)
    print("Status:", r.status_code)
    print("Body:", r.text[:500])
"""
    stdin, stdout, stderr = ssh.exec_command(r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\.venv\Scripts\python")
    stdin.write(script)
    stdin.close()
    print(stdout.read().decode('utf-8'))
    print(stderr.read().decode('utf-8'))
    ssh.close()

if __name__ == "__main__":
    main()
