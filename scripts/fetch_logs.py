import paramiko
import sys
import os

def read_last_lines(filepath, num_lines=100):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            return "".join(lines[-num_lines:])
    except Exception as e:
        return f"Error reading file: {e}"

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print("[*] Connecting to VPS via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connection successful!")
        
        sftp = ssh.open_sftp()
        
        # 1. Fetch stdout.log
        local_stdout = "local_stdout.log"
        print("[*] Downloading stdout.log via SFTP...")
        try:
            sftp.get("C:\\V-Fit\\VFIT_Backend\\stdout.log", local_stdout)
            print("\n=== VFIT BACKEND STDOUT.LOG (Last 100 lines) ===")
            print(read_last_lines(local_stdout, 100))
        except Exception as e:
            print(f"[ERROR] Failed to fetch stdout.log: {e}")
        finally:
            if os.path.exists(local_stdout):
                os.remove(local_stdout)
                
        # 2. Fetch stderr.log
        local_stderr = "local_stderr.log"
        print("[*] Downloading stderr.log via SFTP...")
        try:
            sftp.get("C:\\V-Fit\\VFIT_Backend\\stderr.log", local_stderr)
            print("\n=== VFIT BACKEND STDERR.LOG (Last 100 lines) ===")
            print(read_last_lines(local_stderr, 100))
        except Exception as e:
            print(f"[ERROR] Failed to fetch stderr.log: {e}")
        finally:
            if os.path.exists(local_stderr):
                os.remove(local_stderr)
                
        sftp.close()
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
