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
        
        # Read recommendation stderr log
        print("\n--- Recommendation System stderr.log ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log -Tail 30 } else { Write-Host \'Log not found\' }"'
        )
        print(stdout.read().decode('utf-8', errors='replace'))
        
        # Check service status of vfit-recommendation
        print("\n--- Service Status ---")
        stdin, stdout, stderr = ssh.exec_command('powershell -Command "Get-Service vfit-recommendation | Format-List"')
        print(stdout.read().decode('utf-8'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
