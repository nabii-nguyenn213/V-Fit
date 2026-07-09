import paramiko
import sys
import json

def safe_print(text):
    safe_text = text.encode('ascii', errors='replace').decode('ascii')
    print(safe_text)

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        safe_print("[+] SSH connection successful!")
        
        # We run a curl post request on the VPS to test the recommendation system
        # testing /api/v1/workout-planner/
        safe_print("\n[*] Sending test request to RecommendationSystem on VPS...")
        payload = {
            "age": 25,
            "gender": "Nam",
            "weight": 70,
            "height": 175,
            "goal": "Tăng cơ",
            "activity_level": "Vừa phải",
            "level": "Mới bắt đầu",
            "days_per_week": 3
        }
        payload_str = json.dumps(payload).replace('"', '\\"')
        
        cmd = f'powershell -Command "Invoke-RestMethod -Uri http://127.0.0.1:8002/api/v1/workout-planner/ -Method Post -Body \'{payload_str}\' -ContentType \'application/json\'"'
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        out = stdout.read().decode('utf-8', errors='replace')
        err = stderr.read().decode('utf-8', errors='replace')
        
        safe_print("\n--- Response from RecommendationSystem ---")
        safe_print(out)
        if err:
            safe_print("\n--- Error Output ---")
            safe_print(err)
            
        ssh.close()
    except Exception as e:
        safe_print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
