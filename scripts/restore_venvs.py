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
        
        # 1. Restore RecommendationSystem .venv
        print("\n[*] Restoring RecommendationSystem .venv packages...")
        cmd_rec = (
            'powershell -Command "'
            'cd C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem; '
            '.venv\\Scripts\\python.exe -m pip install -r requirements.txt'
            '"'
        )
        stdin, stdout, stderr = ssh.exec_command(cmd_rec)
        exit_status = stdout.channel.recv_exit_status()
        print(f"[+] RecommendationSystem pip install status: {exit_status}")
        print(stdout.read().decode('utf-8', errors='replace'))
        print(stderr.read().decode('utf-8', errors='replace'))
        
        # 2. Restore V-Fit AI root .venv
        print("\n[*] Restoring V-Fit AI root .venv packages...")
        cmd_ai = (
            'powershell -Command "'
            'cd C:\\V-Fit\\AI-VFIT\\V-Fit; '
            '.venv\\Scripts\\python.exe -m pip install -r requirements.txt'
            '"'
        )
        stdin, stdout, stderr = ssh.exec_command(cmd_ai)
        exit_status = stdout.channel.recv_exit_status()
        print(f"[+] V-Fit AI root pip install status: {exit_status}")
        print(stdout.read().decode('utf-8', errors='replace'))
        print(stderr.read().decode('utf-8', errors='replace'))
        
        # 3. Restart services
        print("\n[*] Restarting services...")
        ssh.exec_command("powershell Stop-Service vfit-recommendation")
        ssh.exec_command("powershell Stop-Service vfit-ai")
        
        import time
        time.sleep(3)
        
        # Start services
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-recommendation")
        stdout.channel.recv_exit_status()
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-ai")
        stdout.channel.recv_exit_status()
        print("[+] Services started.")
        
        # 4. Wait and check
        time.sleep(5)
        print("\n--- Listening Ports after restoring packages ---")
        stdin, stdout, stderr = ssh.exec_command("netstat -ano | findstr LISTENING")
        print(stdout.read().decode('utf-8'))
        
        # Check active python processes
        print("\n--- Python Processes after restoring packages ---")
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
