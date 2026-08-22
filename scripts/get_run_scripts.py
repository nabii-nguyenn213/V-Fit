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
        
        # Check files using Get-Content
        for path in [
            r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\run_rec.ps1",
            r"C:\V-Fit\AI-VFIT\V-Fit\run_ai.ps1"
        ]:
            print(f"\n--- Content of {path} ---")
            stdin, stdout, stderr = ssh.exec_command(f'powershell -Command "if (Test-Path \'{path}\') {{ Get-Content \'{path}\' }} else {{ Write-Host \'File not found\' }}"')
            print(stdout.read().decode('utf-8', errors='replace'))
            
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
