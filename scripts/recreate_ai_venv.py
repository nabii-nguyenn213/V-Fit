import paramiko
import sys
import time

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # 1. Stop vfit-ai service
        print("[*] Stopping vfit-ai service...")
        stdin, stdout, stderr = ssh.exec_command("powershell Stop-Service vfit-ai")
        stdout.channel.recv_exit_status()
        time.sleep(2)
        
        # 2. Force delete V-Fit AI root .venv (blocking)
        print("[*] Deleting old .venv...")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"Remove-Item -Recurse -Force -ErrorAction SilentlyContinue C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\"")
        stdout.channel.recv_exit_status()
        print("[+] Old .venv deleted.")
        
        # 3. Recreate V-Fit AI root .venv
        print("[*] Creating new .venv...")
        stdin, stdout, stderr = ssh.exec_command("C:\\Python311\\python.exe -m venv C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv")
        stdout.channel.recv_exit_status()
        print("[+] New .venv created.")
        
        # 4. Install packages
        print("[*] Installing requirements...")
        stdin, stdout, stderr = ssh.exec_command(
            "C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\\Scripts\\python.exe -m pip install -r C:\\V-Fit\\AI-VFIT\\V-Fit\\requirements.txt"
        )
        stdout.channel.recv_exit_status()
        print("[+] Requirements installed.")
        
        # 5. Write run_ai.ps1
        print("[*] Creating run_ai.ps1...")
        run_ai_content = """$ErrorActionPreference = 'Stop'
$projectPath = "C:\\V-Fit\\AI-VFIT\\V-Fit"
cd $projectPath

# Load env variables from .env.production
$envFile = "C:\\V-Fit\\AI-VFIT\\V-Fit\\.env.production"
if (Test-Path $envFile) {
    Get-Content $envFile | Foreach-Object {
        if ($_ -match '^\\s*([^#=\\s]+)\\s*=\\s*(.*)$') {
            $name = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Run api_server.py
.\\.venv\\Scripts\\python.exe api_server.py
"""
        sftp = ssh.open_sftp()
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\run_ai.ps1", "w") as f:
            f.write(run_ai_content)
        sftp.close()
        print("[+] run_ai.ps1 created.")
        
        # 6. Start service
        print("[*] Starting vfit-ai service...")
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-ai")
        stdout.channel.recv_exit_status()
        print("[+] vfit-ai service started.")
        
        ssh.close()
        print("[+] Done.")
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
