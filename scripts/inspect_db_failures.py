import paramiko
import sys

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connected to VPS.")
        
        # Find MongoDB files
        print("\n--- MongoDB directories ---")
        stdin, stdout, stderr = ssh.exec_command("dir \"C:\\Program Files\\MongoDB\" /s /b | findstr /i \"log\"")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # Search C:\data\db or similar for lock files
        print("\n--- Listing C:\\data or common database paths ---")
        stdin, stdout, stderr = ssh.exec_command("dir C:\\ /b")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # Let's find mongod.cfg
        print("\n--- Finding mongod.cfg ---")
        stdin, stdout, stderr = ssh.exec_command("dir \"C:\\Program Files\\MongoDB\\Server\" /s /b | findstr /i \"mongod.cfg\"")
        cfg_path = stdout.read().decode('utf-8', errors='ignore').strip()
        print(f"Config path: {cfg_path}")
        
        # Read the config if found
        if cfg_path:
            # Get the first line/path
            cfg_file = cfg_path.split('\n')[0]
            print(f"\n--- Contents of {cfg_file} ---")
            stdin, stdout, stderr = ssh.exec_command(f"cmd.exe /c type \"{cfg_file}\"")
            print(stdout.read().decode('utf-8', errors='ignore').strip())
            
        # Find Redis configuration
        print("\n--- Finding Redis files ---")
        stdin, stdout, stderr = ssh.exec_command("dir \"C:\\Program Files\\Redis\" /b")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        stdin, stdout, stderr = ssh.exec_command("dir C:\\Redis /b")
        print(stdout.read().decode('utf-8', errors='ignore').strip())

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
