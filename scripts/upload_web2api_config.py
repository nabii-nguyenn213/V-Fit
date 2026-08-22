import paramiko
import os
import sys

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    local_config = r"d:\EXE_PRM\gemini-web2api\config.json"
    remote_config = r"C:\V-Fit\gemini-web2api\config.json"
    
    if not os.path.exists(local_config):
        print(f"[ERROR] Local config not found: {local_config}")
        sys.exit(1)
        
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # 1. Upload config.json
        print(f"[*] Uploading config.json -> {remote_config}")
        sftp = ssh.open_sftp()
        sftp.put(local_config, remote_config)
        sftp.close()
        print("[+] Successfully uploaded config.json.")
        
        # 2. Stop service
        print("[*] Stopping vfit-gemini-web2api service...")
        ssh.exec_command("powershell Stop-Service vfit-gemini-web2api")
        import time
        time.sleep(2)
        
        # 3. Start service
        print("[*] Starting vfit-gemini-web2api service...")
        stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-gemini-web2api")
        exit_status = stdout.channel.recv_exit_status()
        print(f"[+] Start service exit status: {exit_status}")
        
        ssh.close()
        print("[+] Done.")
    except Exception as e:
        print(f"[ERROR] Failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
