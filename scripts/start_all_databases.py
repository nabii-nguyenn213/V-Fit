import paramiko
import sys
import time

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print("[*] Connecting to VPS...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connected! Waiting 5 seconds for system shell initialization...")
        time.sleep(5)
        
        # Start MongoDB
        print("\n--- Starting MongoDB ---")
        try:
            stdin, stdout, stderr = ssh.exec_command("net start MongoDB", timeout=15)
            print("STDOUT:", stdout.read().decode('utf-8', errors='ignore').strip())
            print("STDERR:", stderr.read().decode('utf-8', errors='ignore').strip())
        except Exception as e:
            print(f"Error starting MongoDB: {e}")
            
        # Start Redis
        print("\n--- Starting Redis ---")
        try:
            stdin, stdout, stderr = ssh.exec_command("net start redis", timeout=15)
            print("STDOUT:", stdout.read().decode('utf-8', errors='ignore').strip())
            print("STDERR:", stderr.read().decode('utf-8', errors='ignore').strip())
        except Exception as e:
            print(f"Error starting Redis: {e}")
            
        # Start VFit Backend
        print("\n--- Starting vfit-backend ---")
        try:
            stdin, stdout, stderr = ssh.exec_command("net start vfit-backend", timeout=15)
            print("STDOUT:", stdout.read().decode('utf-8', errors='ignore').strip())
            print("STDERR:", stderr.read().decode('utf-8', errors='ignore').strip())
        except Exception as e:
            print(f"Error starting vfit-backend: {e}")
            
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
