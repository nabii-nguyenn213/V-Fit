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
        
        # 1. Stop services and kill lingering python processes
        print("[*] Stopping services...")
        ssh.exec_command("powershell Stop-Service vfit-recommendation")
        ssh.exec_command("powershell Stop-Service vfit-ai")
        time.sleep(3)
        
        print("[*] Killing python processes...")
        # Kill python processes except PID 147676 (web2api)
        ssh.exec_command("taskkill /F /IM python.exe /FI \"PID ne 147676\"")
        time.sleep(2)
        
        # 2. Force delete and recreate RecommendationSystem .venv
        print("\n[*] Rebuilding RecommendationSystem .venv...")
        ssh.exec_command("powershell -Command \"Remove-Item -Recurse -Force -ErrorAction SilentlyContinue C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv\"")
        time.sleep(3)
        
        print("[*] Creating RecommendationSystem .venv using C:\\Python311\\python.exe...")
        stdin, stdout, stderr = ssh.exec_command("C:\\Python311\\python.exe -m venv C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv")
        stdout.channel.recv_exit_status()
        
        print("[*] Installing RecommendationSystem packages...")
        stdin, stdout, stderr = ssh.exec_command(
            "C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv\\Scripts\\python.exe -m pip install -r C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\requirements.txt"
        )
        stdout.channel.recv_exit_status()
        print("[+] RecommendationSystem .venv rebuilt successfully.")
        
        # 3. Force delete and recreate V-Fit AI root .venv
        print("\n[*] Rebuilding V-Fit AI root .venv...")
        ssh.exec_command("powershell -Command \"Remove-Item -Recurse -Force -ErrorAction SilentlyContinue C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\"")
        time.sleep(3)
        
        print("[*] Creating V-Fit AI root .venv using C:\\Python311\\python.exe...")
        stdin, stdout, stderr = ssh.exec_command("C:\\Python311\\python.exe -m venv C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv")
        stdout.channel.recv_exit_status()
        
        print("[*] Installing V-Fit AI root packages...")
        stdin, stdout, stderr = ssh.exec_command(
            "C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\\Scripts\\python.exe -m pip install -r C:\\V-Fit\\AI-VFIT\\V-Fit\\requirements.txt"
        )
        stdout.channel.recv_exit_status()
        print("[+] V-Fit AI root .venv rebuilt successfully.")
        
        # 4. Re-create run scripts
        print("\n[*] Re-creating run scripts...")
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
.\\.venv\\Scripts\\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8002
"""
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
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\run_rec.ps1", "w") as f:
            f.write(run_rec_content)
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\run_ai.ps1", "w") as f:
            f.write(run_ai_content)
        sftp.close()
        print("[+] Run scripts created successfully.")
        
        # 5. Start services
        print("\n[*] Starting services...")
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-recommendation")
        stdout.channel.recv_exit_status()
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-ai")
        stdout.channel.recv_exit_status()
        print("[+] Services started successfully.")
        
        # 6. Check status
        time.sleep(5)
        print("\n--- Listening Ports ---")
        stdin, stdout, stderr = ssh.exec_command("netstat -ano | findstr LISTENING")
        print(stdout.read().decode('utf-8'))
        
        ssh.close()
        print("[+] Finished venv rebuild process.")
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
