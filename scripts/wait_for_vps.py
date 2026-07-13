import paramiko
import sys
import time
import socket

def wait_for_ssh(hostname, port=22, timeout=90):
    start_time = time.time()
    print(f"[*] Waiting for {hostname}:{port} to become available...")
    while time.time() - start_time < timeout:
        try:
            s = socket.create_connection((hostname, port), timeout=2)
            s.close()
            print(f"[+] {hostname}:{port} is open!")
            return True
        except (socket.timeout, ConnectionRefusedError, OSError):
            time.sleep(2)
    print(f"[-] Timeout waiting for {hostname}:{port}")
    return False

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    if not wait_for_ssh(hostname):
        sys.exit(1)
        
    print("[*] Connecting to VPS to inspect and start services...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH Connection successful!")
        
        # 1. Query MongoDB and Redis status
        print("\n--- Database service statuses ---")
        for svc in ["MongoDB", "redis"]:
            stdin, stdout, stderr = ssh.exec_command(f"sc.exe query {svc}")
            out = stdout.read().decode('utf-8', errors='ignore').strip()
            print(f"\nService: {svc}")
            print(out)
            
            if "STOPPED" in out:
                print(f"[*] Starting {svc}...")
                stdin, stdout, stderr = ssh.exec_command(f"net start {svc}")
                print(stdout.read().decode('utf-8', errors='ignore').strip())
                print(stderr.read().decode('utf-8', errors='ignore').strip())
                
        # 2. Query vfit-backend status
        print("\n--- vfit-backend service status ---")
        stdin, stdout, stderr = ssh.exec_command("sc.exe query vfit-backend")
        out = stdout.read().decode('utf-8', errors='ignore').strip()
        print(out)
        if "STOPPED" in out:
            print("[*] Starting vfit-backend...")
            stdin, stdout, stderr = ssh.exec_command("net start vfit-backend")
            print(stdout.read().decode('utf-8', errors='ignore').strip())
            
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
