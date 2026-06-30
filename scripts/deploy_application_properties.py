import os
import sys
import time
import paramiko

def execute_remote_cmd(ssh, cmd):
    print(f"[*] Running: {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    
    # Wait for the command to finish
    exit_status = stdout.channel.recv_exit_status()
    
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    
    return exit_status, out, err

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    local_properties = r"d:\EXE_PRM\VFIT_Backend\src\main\resources\application.properties"
    remote_properties = r"C:\V-Fit\VFIT_Backend\src\main\resources\application.properties"
    
    if not os.path.exists(local_properties):
        print(f"[ERROR] Local file not found: {local_properties}")
        sys.exit(1)
        
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # 1. Upload updated application.properties
        print(f"[*] Opening SFTP connection to upload application.properties...")
        sftp = ssh.open_sftp()
        sftp.put(local_properties, remote_properties)
        sftp.close()
        print("[+] Uploaded application.properties successfully!")
        
        # 2. Stop backend service to unlock the jar
        print("[*] Stopping vfit-backend service...")
        status, out, err = execute_remote_cmd(ssh, "powershell Stop-Service vfit-backend")
        if status != 0:
            print(f"[WARNING] Failed to stop service or service already stopped: {err}")
        else:
            print("[+] Stopped vfit-backend service.")
            
        # 2.5 Pull latest code from Git on VPS
        print("[*] Pulling latest code on VPS...")
        status_git, out_git, err_git = execute_remote_cmd(ssh, "cmd /c \"cd C:\\V-Fit\\VFIT_Backend && git pull\"")
        print(out_git)
        if err_git:
            print(f"[WARNING] Git pull warning/error: {err_git}")
            
        # 3. Build backend on VPS
        print("[*] Compiling and packaging backend on VPS (this may take a minute)...")
        # Compile command
        cmd_build = "powershell -Command \"cd C:\\V-Fit\\VFIT_Backend; mvn clean package -DskipTests\""
        status, out, err = execute_remote_cmd(ssh, cmd_build)
        
        print("\n=== BUILD OUTPUT ===")
        print(out)
        if err:
            print(f"[BUILD ERROR/WARNING OUTPUT]:\n{err}")
        print("====================\n")
        
        if status != 0:
            print("[ERROR] Maven build failed! Re-starting the original service just in case...")
            execute_remote_cmd(ssh, "powershell Start-Service vfit-backend")
            sys.exit(1)
            
        print("[+] Maven build succeeded!")
        
        # 4. Start backend service
        print("[*] Starting vfit-backend service...")
        status, out, err = execute_remote_cmd(ssh, "powershell Start-Service vfit-backend")
        if status != 0:
            print(f"[ERROR] Failed to start service: {err}")
            sys.exit(1)
        print("[+] Started vfit-backend service successfully.")
        
        # 5. Wait for Spring Boot to start and verify
        print("[*] Waiting for Spring Boot application to boot up and respond to health check...")
        
        max_attempts = 30
        poll_interval = 3
        success = False
        
        # Checking backend health endpoint
        cmd_test = "curl.exe -s http://127.0.0.1:8080/actuator/health"
        
        for attempt in range(1, max_attempts + 1):
            print(f"[*] Attempt {attempt}/{max_attempts}: Checking health endpoint...")
            status, out, err = execute_remote_cmd(ssh, cmd_test)
            if status == 0 and "UP" in out:
                print(f"[+] Health check response: '{out.strip()}'")
                print("[+] SUCCESS! Spring Boot is up and running on the VPS.")
                success = True
                break
            else:
                print(f"[*] App not ready yet (Exit code: {status}, Response: {out.strip()}). Waiting {poll_interval} seconds...")
                time.sleep(poll_interval)
                
        if not success:
            print("[ERROR] Health check failed after waiting 90 seconds!")
            # Check service status for debugging
            status, out, err = execute_remote_cmd(ssh, "powershell Get-Service vfit-backend")
            print(f"[Service Status]:\n{out}")
            sys.exit(1)
            
        ssh.close()
        print("[+] Finished deployment script.")
        
    except Exception as e:
        print(f"[ERROR] Deployment script failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
