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
        
        # 1. Get system python path and version
        stdin, stdout, stderr = ssh.exec_command("python -c \"import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')\"")
        py_version = stdout.read().decode('utf-8').strip()
        print(f"[+] System Python version: {py_version}")
        
        # 2. Define pyvenv.cfg content
        cfg_content = f"""home = C:\\Python311
include-system-site-packages = false
version = {py_version}
executable = C:\\Python311\\python.exe
command = C:\\Python311\\python.exe -m venv
"""
        
        # 3. Create pyvenv.cfg in both virtual environments
        print("[*] Re-creating pyvenv.cfg files on VPS...")
        sftp = ssh.open_sftp()
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\.venv\pyvenv.cfg", "w") as f:
            f.write(cfg_content)
        with sftp.file(r"C:\V-Fit\AI-VFIT\V-Fit\.venv\pyvenv.cfg", "w") as f:
            f.write(cfg_content)
        sftp.close()
        print("[+] pyvenv.cfg files created successfully.")
        
        # 4. Restart services
        print("[*] Restarting services...")
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
        
        # 5. Wait and check
        time.sleep(5)
        print("\n--- Listening Ports after pyvenv.cfg fix ---")
        stdin, stdout, stderr = ssh.exec_command("netstat -ano | findstr LISTENING")
        print(stdout.read().decode('utf-8'))
        
        # Check active python processes
        print("\n--- Python Processes after pyvenv.cfg fix ---")
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
