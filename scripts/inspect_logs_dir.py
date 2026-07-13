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
        
        # 1. dir C:\V-Fit\VFIT_Backend
        print("\n--- dir C:\\V-Fit\\VFIT_Backend ---")
        stdin, stdout, stderr = ssh.exec_command("dir C:\\V-Fit\\VFIT_Backend")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # 2. Read src/main/resources/application-prod.properties or similar
        print("\n--- Listing src/main/resources ---")
        stdin, stdout, stderr = ssh.exec_command("dir C:\\V-Fit\\VFIT_Backend\\src\\main\\resources")
        print(stdout.read().decode('utf-8', errors='ignore'))

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
