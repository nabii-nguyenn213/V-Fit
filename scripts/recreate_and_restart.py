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
        
        # 1. Re-create C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\run_rec.ps1
        run_rec_content = """$ErrorActionPreference = 'Stop'
$projectPath = "C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem"
cd $projectPath

# Load env variables from parent .env.production
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

# Run uvicorn
.venv\\Scripts\\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8002
"""
        print("[*] Re-creating run_rec.ps1 on VPS...")
        sftp = ssh.open_sftp()
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\run_rec.ps1", "w") as f:
            f.write(run_rec_content)
            
        # 2. Re-create C:\V-Fit\AI-VFIT\V-Fit\run_ai.ps1
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
.venv\\Scripts\\python.exe api_server.py
"""
        print("[*] Re-creating run_ai.ps1 on VPS...")
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\run_ai.ps1", "w") as f:
            f.write(run_ai_content)
        sftp.close()
        print("[+] Run scripts created successfully.")
        
        # 3. Stop and Restart services
        print("[*] Restarting vfit-recommendation and vfit-ai services...")
        ssh.exec_command("powershell Stop-Service vfit-recommendation")
        ssh.exec_command("powershell Stop-Service vfit-ai")
        
        import time
        time.sleep(3)
        
        # Make sure old processes are killed just in case they survived Stop-Service
        ssh.exec_command("taskkill /F /IM python.exe /FI \"PID ne 77152\"") # Kill other python processes but keep web2api (77152)
        time.sleep(1)
        
        # Start services
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-recommendation")
        stdout.channel.recv_exit_status()
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-ai")
        stdout.channel.recv_exit_status()
        print("[+] Services started.")
        
        # 4. Wait a few seconds and check if they are running and listening
        time.sleep(5)
        print("\n--- Listening Ports after restart ---")
        stdin, stdout, stderr = ssh.exec_command("netstat -ano | findstr LISTENING")
        print(stdout.read().decode('utf-8'))
        
        # Check active python processes
        print("\n--- Python Processes after restart ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-CimInstance Win32_Process -Filter \\"name = \'python.exe\'\\" | Select-Object ProcessId, CommandLine, CreationDate | Format-List"'
        )
        print(stdout.read().decode('utf-8'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
