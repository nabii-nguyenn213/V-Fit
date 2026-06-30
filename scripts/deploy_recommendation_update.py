import os
import sys
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
    
    files_to_upload = [
        (r"d:\EXE_PRM\AI-VFIT\V-Fit\RecommendationSystem\gemini_client.py", r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\gemini_client.py"),
        (r"d:\EXE_PRM\AI-VFIT\V-Fit\RecommendationSystem\.env", r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\.env"),
        (r"d:\EXE_PRM\AI-VFIT\V-Fit\RecommendationSystem\.env.production", r"C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem\.env.production"),
    ]
    
    for local_file, remote_file in files_to_upload:
        if not os.path.exists(local_file):
            print(f"[ERROR] Local file not found: {local_file}")
            sys.exit(1)
        
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # 1. Upload updated files
        print(f"[*] Opening SFTP connection to upload files...")
        sftp = ssh.open_sftp()
        for local_file, remote_file in files_to_upload:
            sftp.put(local_file, remote_file)
            print(f"[+] Uploaded {os.path.basename(local_file)} successfully!")
        sftp.close()
        
        # 2. Stop recommendation service
        print("[*] Stopping vfit-recommendation service...")
        status, out, err = execute_remote_cmd(ssh, "powershell Stop-Service vfit-recommendation")
        if status != 0:
            print(f"[WARNING] Failed to stop service or service already stopped: {err}")
        else:
            print("[+] Stopped vfit-recommendation service.")
            
        # 3. Start recommendation service
        print("[*] Starting vfit-recommendation service...")
        status, out, err = execute_remote_cmd(ssh, "powershell Start-Service vfit-recommendation")
        if status != 0:
            print(f"[ERROR] Failed to start service: {err}")
            sys.exit(1)
        print("[+] Started vfit-recommendation service successfully.")
        
        ssh.close()
        print("[+] Finished recommendation system deployment.")
        
    except Exception as e:
        print(f"[ERROR] Deployment script failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
