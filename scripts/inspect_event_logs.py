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
        
        # 1. Query Event Log for redis
        print("\n--- Windows Event Logs for redis ---")
        cmd_redis = "wevtutil qe Application \"/q:*[System[Provider[@Name='redis'] or Provider[@Name='redis-server'] or Provider[@Name='redis-service']]]\" /c:5 /rd:true /f:text"
        stdin, stdout, stderr = ssh.exec_command(cmd_redis)
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # 2. General Application errors from last 10 minutes
        print("\n--- Recent Application Errors ---")
        cmd_errors = "wevtutil qe Application \"/q:*[System[(Level=1 or Level=2)]]\" /c:5 /rd:true /f:text"
        stdin, stdout, stderr = ssh.exec_command(cmd_errors)
        print(stdout.read().decode('utf-8', errors='ignore').strip())

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
