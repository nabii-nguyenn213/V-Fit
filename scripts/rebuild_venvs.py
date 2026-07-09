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
        
        print("[*] Killing other python processes...")
        # Kill python processes except PID 77152 (web2api)
        ssh.exec_command("taskkill /F /IM python.exe /FI \"PID ne 77152\"")
        time.sleep(2)
        
        # 2. Rebuild RecommendationSystem .venv
        print("\n[*] Rebuilding RecommendationSystem .venv...")
        # Remove directory using PowerShell to avoid aliasing and handle system folders
        ssh.exec_command("powershell -Command \"Remove-Item -Recurse -Force -ErrorAction SilentlyContinue C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv\"")
        time.sleep(3)
        
        # Create virtual env
        print("[*] Creating RecommendationSystem .venv...")
        stdin, stdout, stderr = ssh.exec_command("python -m venv C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv")
        stdout.channel.recv_exit_status()
        
        # Install packages
        print("[*] Installing RecommendationSystem packages...")
        stdin, stdout, stderr = ssh.exec_command(
            "C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv\\Scripts\\python.exe -m pip install -r C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\requirements.txt"
        )
        stdout.channel.recv_exit_status()
        print("[+] RecommendationSystem .venv rebuilt successfully.")
        
        # 3. Rebuild V-Fit AI root .venv
        print("\n[*] Rebuilding V-Fit AI root .venv...")
        ssh.exec_command("powershell -Command \"Remove-Item -Recurse -Force -ErrorAction SilentlyContinue C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\"")
        time.sleep(3)
        
        # Create virtual env
        print("[*] Creating V-Fit AI root .venv...")
        stdin, stdout, stderr = ssh.exec_command("python -m venv C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv")
        stdout.channel.recv_exit_status()
        
        # Install packages
        print("[*] Installing V-Fit AI root packages...")
        stdin, stdout, stderr = ssh.exec_command(
            "C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\\Scripts\\python.exe -m pip install -r C:\\V-Fit\\AI-VFIT\\V-Fit\\requirements.txt"
        )
        stdout.channel.recv_exit_status()
        print("[+] V-Fit AI root .venv rebuilt successfully.")
        
        # 4. Start services
        print("\n[*] Starting services...")
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-recommendation")
        stdout.channel.recv_exit_status()
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-ai")
        stdout.channel.recv_exit_status()
        print("[+] Services started.")
        
        # 5. Check status
        time.sleep(5)
        print("\n--- Listening Ports ---")
        stdin, stdout, stderr = ssh.exec_command("netstat -ano | findstr LISTENING")
        print(stdout.read().decode('utf-8'))
        
        # Check active python processes
        print("\n--- Python Processes ---")
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
