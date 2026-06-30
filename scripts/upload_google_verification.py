import os
import sys
import paramiko

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    local_file = r"d:\EXE_PRM\googlec5a363f8efe4656c.html"
    remote_backend_path = r"C:\V-Fit\VFIT_Backend\web\googlec5a363f8efe4656c.html"
    remote_frontend_path = r"C:\V-Fit\VFIT_Fontend\web\googlec5a363f8efe4656c.html"
    
    if not os.path.exists(local_file):
        print(f"[ERROR] Local file not found: {local_file}")
        sys.exit(1)
        
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=15)
        print("[+] SSH connection successful!")
        
        # Open SFTP client
        print(f"[*] Opening SFTP connection...")
        sftp = ssh.open_sftp()
        
        # Upload to backend web directory
        print(f"[*] Uploading to backend web directory: {remote_backend_path}")
        sftp.put(local_file, remote_backend_path)
        print("[+] Uploaded successfully!")
        
        # Upload to frontend web directory
        print(f"[*] Uploading to frontend web directory: {remote_frontend_path}")
        sftp.put(local_file, remote_frontend_path)
        print("[+] Uploaded successfully!")
        
        sftp.close()
        
        # Verify remote files exist and check content
        print("[*] Verifying remote files...")
        cmd_backend = f"powershell Get-Content {remote_backend_path}"
        stdin, stdout, stderr = ssh.exec_command(cmd_backend)
        backend_content = stdout.read().decode('utf-8').strip()
        print(f"[+] Backend remote file content: '{backend_content}'")
        
        cmd_frontend = f"powershell Get-Content {remote_frontend_path}"
        stdin, stdout, stderr = ssh.exec_command(cmd_frontend)
        frontend_content = stdout.read().decode('utf-8').strip()
        print(f"[+] Frontend remote file content: '{frontend_content}'")
        
        ssh.close()
        print("[+] Verification file uploaded and verified successfully on VPS!")
        
    except Exception as e:
        print(f"[ERROR] Failed to upload or verify: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
