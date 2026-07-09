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
        
        # Check system env vars via PowerShell
        print("\n--- GEMINI_MODEL env var at different scopes ---")
        cmd = (
            'powershell -Command "'
            'Write-Host \'Machine scope:\' ([System.Environment]::GetEnvironmentVariable(\'GEMINI_MODEL\', \'Machine\')); '
            'Write-Host \'User scope:\' ([System.Environment]::GetEnvironmentVariable(\'GEMINI_MODEL\', \'User\')); '
            'Write-Host \'Process scope:\' ([System.Environment]::GetEnvironmentVariable(\'GEMINI_MODEL\', \'Process\')); '
            '"'
        )
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode('utf-8'))
        
        # Let's check all env vars from the running uvicorn process
        print("\n--- Full Environment of PID 86328 ---")
        cmd_env = 'powershell -Command "Get-CimInstance Win32_Process -Filter \\"ProcessId = 86328\\" | Select-Object -ExpandProperty EnvironmentVariables"'
        stdin, stdout, stderr = ssh.exec_command(cmd_env)
        out = stdout.read().decode('utf-8')
        for line in out.splitlines():
            if any(k in line for k in ("GEMINI", "MODEL", "WEB2API")):
                print(line)

        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
