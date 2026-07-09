import paramiko
import sys

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
        
        # Read config.py of RecommendationSystem on VPS
        safe_print("\n--- VPS RecommendationSystem config.py ---")
        stdin, stdout, stderr = ssh.exec_command("type C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\config.py")
        safe_print(stdout.read().decode('utf-8', errors='replace'))
        
        # Read gemini_client.py of RecommendationSystem on VPS
        safe_print("\n--- VPS RecommendationSystem gemini_client.py (lines 30-45) ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\gemini_client.py | Select-Object -Index (30..45)"'
        )
        safe_print(stdout.read().decode('utf-8', errors='replace'))
        
        # Check if there is any other .env or start script in VFIT_Backend that sets GEMINI_MODEL
        safe_print("\n--- VPS start-ai-services.bat or similar files ---")
        stdin, stdout, stderr = ssh.exec_command('powershell -Command "Get-ChildItem -Path C:\\V-Fit -Filter *.bat, *.ps1 -Recurse | Select-Object FullName"')
        safe_print(stdout.read().decode('utf-8', errors='replace'))
        
        ssh.close()
    except Exception as e:
        safe_print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
