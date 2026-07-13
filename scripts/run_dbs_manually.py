import paramiko
import sys
import os

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connected to VPS.")
        
        # 1. Read mongod.log via SFTP
        print("\n--- Last 50 lines of mongod.log ---")
        sftp = ssh.open_sftp()
        local_log = "local_mongod.log"
        try:
            sftp.get("C:\\Program Files\\MongoDB\\Server\\4.4\\log\\mongod.log", local_log)
            with open(local_log, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                print("".join(lines[-50:]))
        except Exception as e:
            print(f"Error reading mongod.log: {e}")
        finally:
            if os.path.exists(local_log):
                os.remove(local_log)
        sftp.close()
        
        # 2. Run redis-server manually to capture output
        print("\n--- Running redis-server manually (5s timeout) ---")
        # Run in cmd with timeout
        stdin, stdout, stderr = ssh.exec_command("cmd.exe /c \"cd C:\\Redis && redis-server.exe redis.windows-service.conf\"", timeout=10)
        # Wait up to 5 seconds
        import time
        time.sleep(3)
        if not stdout.channel.closed:
            # Send Ctrl+C or close channel
            stdout.channel.close()
        print("STDOUT:")
        print(stdout.read().decode('utf-8', errors='ignore'))
        print("STDERR:")
        print(stderr.read().decode('utf-8', errors='ignore'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
