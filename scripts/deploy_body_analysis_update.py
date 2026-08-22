import paramiko
import os

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    files_to_upload = [
        (r"d:\EXE_PRM\AI-VFIT\V-Fit\body_analysis\body_analyzer.py", r"C:\V-Fit\AI-VFIT\V-Fit\body_analysis\body_analyzer.py"),
        (r"d:\EXE_PRM\AI-VFIT\V-Fit\body_analysis\body_shape_predictor.py", r"C:\V-Fit\AI-VFIT\V-Fit\body_analysis\body_shape_predictor.py"),
    ]
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        sftp = ssh.open_sftp()
        for local, remote in files_to_upload:
            sftp.put(local, remote)
            print(f"[+] Uploaded {os.path.basename(local)} to VPS.")
        sftp.close()
        
        print("[*] Restarting vfit-ai service...")
        stdin, stdout, stderr = ssh.exec_command("powershell Restart-Service vfit-ai")
        exit_status = stdout.channel.recv_exit_status()
        print(f"[+] Restart service status: {exit_status}")
        
        ssh.close()
        print("[+] Deployment of body analysis update complete!")
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
