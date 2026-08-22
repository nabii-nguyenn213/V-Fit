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
        
        # Start MongoDB
        print("\n--- Starting MongoDB service ---")
        stdin, stdout, stderr = ssh.exec_command("net start MongoDB")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        print(stderr.read().decode('utf-8', errors='ignore').strip())
        
        # Start Redis
        print("\n--- Starting redis service ---")
        stdin, stdout, stderr = ssh.exec_command("net start redis")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        print(stderr.read().decode('utf-8', errors='ignore').strip())
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
