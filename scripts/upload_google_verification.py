import os
import sys
import paramiko

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    files_to_upload = [
        {
            "local": r"d:\EXE_PRM\googlec5a363f8efe4656c.html",
            "remote_backend": r"C:\V-Fit\VFIT_Backend\web\googlec5a363f8efe4656c.html",
            "remote_frontend": r"C:\V-Fit\VFIT_Fontend\web\googlec5a363f8efe4656c.html"
        },
        {
            "local": r"d:\EXE_PRM\sitemap.xml",
            "remote_backend": r"C:\V-Fit\VFIT_Backend\web\sitemap.xml",
            "remote_frontend": r"C:\V-Fit\VFIT_Fontend\web\sitemap.xml"
        }
    ]
    
    for f in files_to_upload:
        if not os.path.exists(f["local"]):
            print(f"[ERROR] Local file not found: {f['local']}")
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
        
        for f in files_to_upload:
            # Upload to backend web directory
            print(f"[*] Uploading to backend: {f['remote_backend']}")
            sftp.put(f["local"], f["remote_backend"])
            print("[+] Uploaded successfully!")
            
            # Upload to frontend web directory
            print(f"[*] Uploading to frontend: {f['remote_frontend']}")
            sftp.put(f["local"], f["remote_frontend"])
            print("[+] Uploaded successfully!")
            
        sftp.close()
        
        # Verify remote files exist and check content
        print("[*] Verifying remote files...")
        for f in files_to_upload:
            cmd_backend = f"powershell Get-Content {f['remote_backend']}"
            stdin, stdout, stderr = ssh.exec_command(cmd_backend)
            backend_content = stdout.read().decode('utf-8').strip()
            print(f"[+] Backend remote file content ({os.path.basename(f['local'])}): '{backend_content[:50]}...'")
            
            cmd_frontend = f"powershell Get-Content {f['remote_frontend']}"
            stdin, stdout, stderr = ssh.exec_command(cmd_frontend)
            frontend_content = stdout.read().decode('utf-8').strip()
            print(f"[+] Frontend remote file content ({os.path.basename(f['local'])}): '{frontend_content[:50]}...'")
            
        ssh.close()
        print("[+] Verification and sitemap files uploaded and verified successfully on VPS!")
        
    except Exception as e:
        print(f"[ERROR] Failed to upload or verify: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
