import os
import sys
import shutil
import zipfile
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
    
    local_web_dir = r"d:\EXE_PRM\VFIT_Fontend\build\web"
    local_index = os.path.join(local_web_dir, "index.html")
    local_zip = r"d:\EXE_PRM\VFIT_Fontend\build\web.zip"
    
    remote_zip = r"C:\V-Fit\VFIT_Backend\web.zip"
    remote_web_dir = r"C:\V-Fit\VFIT_Backend\web"
    
    if not os.path.exists(local_web_dir):
        print(f"[ERROR] Local build/web directory not found: {local_web_dir}")
        sys.exit(1)
        
    # 1. Modify index.html base href
    print("[*] Processing local index.html base href...")
    if os.path.exists(local_index):
        with open(local_index, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Replace $FLUTTER_BASE_HREF with /
        if "$FLUTTER_BASE_HREF" in content:
            content = content.replace("$FLUTTER_BASE_HREF", "/")
            with open(local_index, "w", encoding="utf-8") as f:
                f.write(content)
            print("[+] Successfully replaced $FLUTTER_BASE_HREF with / in index.html")
        else:
            print("[*] base href already processed or placeholder not found.")
    else:
        print("[WARNING] index.html not found in build directory.")
        
    # 2. Create zip archive of build/web contents
    print(f"[*] Creating zip archive of {local_web_dir}...")
    if os.path.exists(local_zip):
        os.remove(local_zip)
        
    shutil.make_archive(r"d:\EXE_PRM\VFIT_Fontend\build\web", 'zip', local_web_dir)
    print(f"[+] Zip archive created successfully at {local_zip}")
    
    # 3. Connect to VPS
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=30)
        print("[+] SSH connection successful!")
        
        # 4. Upload zip file
        print(f"[*] Opening SFTP connection to upload {local_zip}...")
        sftp = ssh.open_sftp()
        sftp.put(local_zip, remote_zip)
        sftp.close()
        print(f"[+] Uploaded web.zip successfully to {remote_zip}")
        
        # 5. Extract zip on VPS
        print("[*] Extracting web.zip on VPS...")
        # Force extraction (overwrite existing files)
        cmd_extract = f"powershell -Command \"Expand-Archive -Path {remote_zip} -DestinationPath {remote_web_dir} -Force\""
        status, out, err = execute_remote_cmd(ssh, cmd_extract)
        if status != 0:
            print(f"[ERROR] Failed to extract archive on VPS: {err}")
            sys.exit(1)
        print("[+] Extracted web files on VPS.")
        
        # 6. Delete remote zip to clean up
        print("[*] Cleaning up remote zip file...")
        execute_remote_cmd(ssh, f"powershell -Command \"Remove-Item -Path {remote_zip} -Force\"")
        print("[+] Cleaned up VPS archive.")
        
        # 7. Delete local zip to clean up
        if os.path.exists(local_zip):
            os.remove(local_zip)
            print("[+] Cleaned up local archive.")
            
        ssh.close()
        print("[+] Web frontend deployment completed successfully!")
        
    except Exception as e:
        print(f"[ERROR] Deployment failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
