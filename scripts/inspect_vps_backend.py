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
        print("[+] Connected to VPS.")
        
        # 1. List C:\V-Fit\VFIT_Backend
        print("\n--- List of files in VFIT_Backend ---")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"Get-ChildItem C:\\V-Fit\\VFIT_Backend | Select-Object Name, Length, LastWriteTime\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # 2. Check for *.log files anywhere in C:\V-Fit\VFIT_Backend
        print("\n--- Finding *.log files ---")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"Get-ChildItem -Path C:\\V-Fit\\VFIT_Backend -Filter *.log -Recurse | Select-Object FullName\"")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # 3. Read application.properties
        print("\n--- Reading application.properties ---")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"if (Test-Path C:\\V-Fit\\VFIT_Backend\\src\\main\\resources\\application.properties) { Get-Content C:\\V-Fit\\VFIT_Backend\\src\\main\\resources\\application.properties } else { Write-Host 'Not found' }\"")
        print(stdout.read().decode('utf-8', errors='ignore'))

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
