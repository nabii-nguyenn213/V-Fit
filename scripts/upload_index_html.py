import os
import sys
import io
import paramiko

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    local_index_path = r"d:\EXE_PRM\VFIT_Fontend\web\index.html"
    remote_frontend_path = r"C:\V-Fit\VFIT_Fontend\web\index.html"
    remote_backend_path = r"C:\V-Fit\VFIT_Backend\web\index.html"
    
    local_robots_path = r"d:\EXE_PRM\VFIT_Fontend\web\robots.txt"
    remote_frontend_robots_path = r"C:\V-Fit\VFIT_Fontend\web\robots.txt"
    remote_backend_robots_path = r"C:\V-Fit\VFIT_Backend\web\robots.txt"
    
    # Check local files exist
    if not os.path.exists(local_index_path):
        print(f"[ERROR] Local file not found: {local_index_path}")
        sys.exit(1)
        
    if not os.path.exists(local_robots_path):
        print(f"[ERROR] Local file not found: {local_robots_path}")
        sys.exit(1)
        
    print(f"[*] Reading local index.html...")
    with open(local_index_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Translate base href for the compiled web version served by the backend
    backend_content = content.replace("$FLUTTER_BASE_HREF", "/")
    
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=15)
        print("[+] SSH connection successful!")
        
        # Open SFTP client
        print(f"[*] Opening SFTP connection...")
        sftp = ssh.open_sftp()
        
        # 1. Upload index.html
        print(f"[*] Uploading raw index.html to frontend: {remote_frontend_path}")
        sftp.put(local_index_path, remote_frontend_path)
        print("[+] Uploaded frontend source index.html successfully!")
        
        print(f"[*] Uploading translated index.html to backend: {remote_backend_path}")
        backend_file = io.BytesIO(backend_content.encode("utf-8"))
        sftp.putfo(backend_file, remote_backend_path)
        print("[+] Uploaded backend served index.html successfully!")
        
        # 2. Upload robots.txt
        print(f"[*] Uploading robots.txt to frontend: {remote_frontend_robots_path}")
        sftp.put(local_robots_path, remote_frontend_robots_path)
        print("[+] Uploaded frontend source robots.txt successfully!")
        
        print(f"[*] Uploading robots.txt to backend: {remote_backend_robots_path}")
        sftp.put(local_robots_path, remote_backend_robots_path)
        print("[+] Uploaded backend served robots.txt successfully!")
        
        sftp.close()
        
        # Verify remote files exist and check content
        print("[*] Verifying remote files...")
        cmd_verify = f"powershell \"Get-Content {remote_backend_path} | Select-String google-site-verification\""
        stdin, stdout, stderr = ssh.exec_command(cmd_verify)
        verification_match = stdout.read().decode('utf-8').strip()
        
        if "google-site-verification" in verification_match:
            print(f"[+] VPS backend verification tag confirmed: {verification_match}")
        else:
            print(f"[WARNING] Verification tag not found in remote output: {verification_match}")
            
        cmd_verify_robots = f"powershell \"Get-Content {remote_backend_robots_path}\""
        stdin, stdout, stderr = ssh.exec_command(cmd_verify_robots)
        robots_content = stdout.read().decode('utf-8').strip()
        print(f"[+] VPS backend robots.txt content:\n{robots_content}")
            
        ssh.close()
        print("[+] Deployment completed successfully!")
        
    except Exception as e:
        print(f"[ERROR] Failed to deploy or verify: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
