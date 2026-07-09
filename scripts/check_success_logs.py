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
        
        # Read recommendation stdout log
        safe_print("\n--- Recommendation System stdout.log ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stdout.log) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stdout.log -Tail 20 } else { Write-Host \'Log not found\' }"'
        )
        safe_print(stdout.read().decode('utf-8', errors='replace'))
        
        # Read recommendation stderr log
        safe_print("\n--- Recommendation System stderr.log ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log -Tail 20 } else { Write-Host \'Log not found\' }"'
        )
        safe_print(stdout.read().decode('utf-8', errors='replace'))
        
        ssh.close()
    except Exception as e:
        safe_print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
