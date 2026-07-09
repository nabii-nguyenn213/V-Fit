import paramiko
import sys

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # List all files in RecommendationSystem including hidden
        print("\n--- RecommendationSystem Files (including hidden) ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-ChildItem -Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem -Force | Select-Object Name"'
        )
        print(stdout.read().decode('utf-8'))
        
        # Read .env if it exists
        print("\n--- RecommendationSystem .env Content ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.env) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.env } else { Write-Host \'Not found\' }"'
        )
        print(stdout.read().decode('utf-8'))
        
        # Check process environment for PID 86328 / 93148
        print("\n--- Uvicorn process environment ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-CimInstance Win32_Process -Filter \\"ProcessId = 86328\\" | Select-Object -ExpandProperty EnvironmentVariables"'
        )
        # EnvironmentVariables is an array of strings
        out = stdout.read().decode('utf-8')
        # Print first 20 lines or filter for GEMINI
        for line in out.splitlines():
            if "GEMINI" in line or "MODEL" in line or "WEB2API" in line:
                print(line)
                
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
