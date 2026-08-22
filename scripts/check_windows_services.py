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
        
        # 1. Get services matching 'vfit' or 'gemini'
        print("\n--- Services matching vfit or gemini ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-Service | Where-Object { $_.Name -like \'*vfit*\' -or $_.DisplayName -like \'*vfit*\' -or $_.Name -like \'*gemini*\' }"'
        )
        print(stdout.read().decode('utf-8', errors='replace'))
        
        # 2. Check registry configuration for services
        # Let's list all subkeys under HKLM:\System\CurrentControlSet\Services
        print("\n--- Registry parameters for vfit services ---")
        services = ['vfit-backend', 'vfit-ai', 'vfit-recommendation', 'vfit-web2api']
        for svc in services:
            print(f"\nService: {svc}")
            cmd = (
                f'powershell -Command "'
                f'if (Test-Path \'HKLM:\\System\\CurrentControlSet\\Services\\{svc}\\Parameters\') {{ '
                f'  Get-ItemProperty \'HKLM:\\System\\CurrentControlSet\\Services\\{svc}\\Parameters\' | Format-List '
                f'}} else {{ '
                f'  Write-Host \'No Parameters key found\' '
                f'}}"'
            )
            stdin, stdout, stderr = ssh.exec_command(cmd)
            print(stdout.read().decode('utf-8', errors='replace'))
            
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
