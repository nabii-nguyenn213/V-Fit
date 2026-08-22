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
        
        # 1. Check for redis process
        print("\n--- tasklist matching redis ---")
        stdin, stdout, stderr = ssh.exec_command("tasklist | findstr /I redis")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # 2. Check for port 6379
        print("\n--- Checking port 6379 ---")
        stdin, stdout, stderr = ssh.exec_command("netstat -ano | findstr :6379")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # 3. Check for mongo process
        print("\n--- tasklist matching mongo ---")
        stdin, stdout, stderr = ssh.exec_command("tasklist | findstr /I mongo")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
