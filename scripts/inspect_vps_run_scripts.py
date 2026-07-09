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
        
        # 1. Read run_rec.ps1
        print("\n--- run_rec.ps1 content ---")
        stdin, stdout, stderr = ssh.exec_command("type C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\run_rec.ps1")
        print(stdout.read().decode('utf-8', errors='replace'))
        
        # 2. Read run_ai.ps1
        print("\n--- run_ai.ps1 content ---")
        stdin, stdout, stderr = ssh.exec_command("type C:\\V-Fit\\AI-VFIT\\V-Fit\\run_ai.ps1")
        print(stdout.read().decode('utf-8', errors='replace'))
        
        # 3. Read registry parameters for vfit-gemini-web2api
        print("\n--- Registry parameters for vfit-gemini-web2api ---")
        cmd = 'powershell -Command "Get-ItemProperty HKLM:\\System\\CurrentControlSet\\Services\\vfit-gemini-web2api\\Parameters | Format-List"'
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode('utf-8', errors='replace'))
        
        # 4. Check if there are any other run scripts or environment files
        # Let's read the environment variables set inside run_rec.ps1 or run_ai.ps1
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
