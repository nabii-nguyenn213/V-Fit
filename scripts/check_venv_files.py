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
        
        # Check files inside C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\.venv
        print("\n--- RecommendationSystem .venv files ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-ChildItem -Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv -Force | Select-Object Name"'
        )
        print(stdout.read().decode('utf-8', errors='replace'))
        
        # Check files inside C:\V-Fit\AI-VFIT\V-Fit\.venv
        print("\n--- AI-VFIT\\V-Fit .venv files ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-ChildItem -Path C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv -Force | Select-Object Name"'
        )
        print(stdout.read().decode('utf-8', errors='replace'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
