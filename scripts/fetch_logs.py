import paramiko
import sys

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print("[*] Connecting to VPS via SSH to fetch backend logs...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # Read stdout.log
        print("\n=== VFIT BACKEND STDOUT.LOG (Last 50 lines) ===")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"if (Test-Path C:\\V-Fit\\VFIT_Backend\\stdout.log) { Get-Content C:\\V-Fit\\VFIT_Backend\\stdout.log -Tail 50 } else { Write-Host 'No stdout.log' }\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # Read stderr.log
        print("\n=== VFIT BACKEND STDERR.LOG (Last 50 lines) ===")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"if (Test-Path C:\\V-Fit\\VFIT_Backend\\stderr.log) { Get-Content C:\\V-Fit\\VFIT_Backend\\stderr.log -Tail 50 } else { Write-Host 'No stderr.log' }\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed to fetch logs: {e}")

if __name__ == "__main__":
    main()
