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
        
        # List files in C:\Redis with extension .conf, .log, .rdb
        print("\n--- List of Redis files ---")
        stdin, stdout, stderr = ssh.exec_command("dir C:\\Redis /b")
        print(stdout.read().decode('utf-8', errors='ignore').strip())

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
