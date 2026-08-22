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
        
        # Search for "gemini-2.5-flash" in all files in C:\V-Fit
        print("\n--- Searching for 'gemini-2.5-flash' in C:\\V-Fit ---")
        cmd = 'powershell -Command "Get-ChildItem -Path C:\\V-Fit -Recurse -File -Exclude *.log, *.pyc, *.pt, *.pth, *.jar, *.exe, .git, .venv, node_modules | Select-String -Pattern \'gemini-2.5-flash\' | Select-Object Path, LineNumber, Line"'
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Format and print results
        out = stdout.read().decode('utf-8', errors='replace')
        safe_text = out.encode('ascii', errors='replace').decode('ascii')
        print(safe_text)
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
