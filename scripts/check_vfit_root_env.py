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
        
        # Check files in C:\V-Fit\AI-VFIT\V-Fit
        print("\n--- AI-VFIT\\V-Fit Files (including hidden) ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-ChildItem -Path C:\\V-Fit\\AI-VFIT\\V-Fit -Force | Select-Object Name"'
        )
        print(stdout.read().decode('utf-8'))
        
        # Read .env or .env.production if they exist in C:\V-Fit\AI-VFIT\V-Fit
        print("\n--- AI-VFIT\\V-Fit .env Content ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\.env) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\.env } else { Write-Host \'Not found\' }"'
        )
        print(stdout.read().decode('utf-8'))
        
        print("\n--- AI-VFIT\\V-Fit .env.production Content ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "if (Test-Path C:\\V-Fit\\AI-VFIT\\V-Fit\\.env.production) { Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\.env.production } else { Write-Host \'Not found\' }"'
        )
        print(stdout.read().decode('utf-8'))

        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
