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
        
        # Files to check
        files_to_check = [
            r"C:\V-Fit\VFIT_Backend\.env",
            r"C:\V-Fit\VFIT_Backend\.env.production",
            r"C:\V-Fit\AI-VFIT\V-Fit\.env",
            r"C:\V-Fit\AI-VFIT\V-Fit\.env.prod"
        ]
        
        for fpath in files_to_check:
            print(f"\n--- Checking file: {fpath} ---")
            stdin, stdout, stderr = ssh.exec_command(f'powershell -Command "if (Test-Path \'{fpath}\') {{ Get-Content \'{fpath}\' }} else {{ Write-Host \'File not found\' }}"')
            out = stdout.read().decode('utf-8', errors='ignore').strip()
            print(out)
            
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
