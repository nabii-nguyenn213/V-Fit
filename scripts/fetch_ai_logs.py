import paramiko
import sys

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print("[*] Connecting to VPS via SSH to fetch AI logs...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # Read vfit-ai stderr.log
        print("\n=== VFIT-AI STDERR.LOG (Last 30 lines) ===")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\stderr.log) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\stderr.log -Tail 30 } else { Write-Host 'No stderr.log' }\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # Read vfit-ai stdout.log
        print("\n=== VFIT-AI STDOUT.LOG (Last 30 lines) ===")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\stdout.log) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\stdout.log -Tail 30 } else { Write-Host 'No stdout.log' }\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # Read vfit-recommendation stderr.log
        print("\n=== VFIT-RECOMMENDATION STDERR.LOG (Last 30 lines) ===")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log -Tail 30 } else { Write-Host 'No stderr.log' }\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed to fetch logs: {e}")

if __name__ == "__main__":
    main()
