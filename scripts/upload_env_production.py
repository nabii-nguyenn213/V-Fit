import os
import paramiko

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"

    local_path = r"d:\EXE_PRM\VFIT_Backend\.env.production"
    remote_path = r"C:\V-Fit\VFIT_Backend\.env.production"

    if not os.path.exists(local_path):
        print(f"[ERROR] Local file {local_path} does not exist!")
        return

    print("[*] Connecting to VPS...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=username, password=password, timeout=15)
    
    print(f"[*] Uploading {local_path} -> {remote_path}")
    sftp = ssh.open_sftp()
    sftp.put(local_path, remote_path)
    sftp.close()
    print("[+] Upload complete.")
    
    ssh.close()

if __name__ == "__main__":
    main()
