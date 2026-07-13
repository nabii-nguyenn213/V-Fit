import paramiko
import os

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print("[*] Connecting to VPS via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH Connection successful!")
        
        # Run dir command to find files
        stdin, stdout, stderr = ssh.exec_command("dir C:\\V-Fit /s /b")
        files = stdout.read().decode('utf-8', errors='ignore').splitlines()
        print(f"[+] Found {len(files)} files in C:\\V-Fit. Searching for csv files...")
        
        csv_files = [f for f in files if f.endswith(".csv")]
        for csv in csv_files:
            print(f"  - {csv}")
            
        # Let's download the csv files we care about via SFTP
        sftp = ssh.open_sftp()
        for remote_path in csv_files:
            filename = os.path.basename(remote_path)
            local_path = os.path.join("d:\\EXE_PRM\\docs", filename)
            # ensure docs dir exists
            os.makedirs(os.path.dirname(local_path), exist_ok=True)
            print(f"[*] Downloading {remote_path} to {local_path}...")
            sftp.get(remote_path, local_path)
            print(f"[+] Downloaded {filename} successfully.")
            
            # Read first few lines of the downloaded file
            with open(local_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                print(f"=== Content of {filename} ===")
                print(content[:1000])
                print("=============================")
                
        sftp.close()
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
