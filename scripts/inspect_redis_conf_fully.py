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
        
        # Read active lines in redis.windows.conf (skipping comments and empty lines)
        print("\n--- Active lines in redis.windows.conf ---")
        cmd = "cmd.exe /c \"findstr /V /R \"^#\" C:\\Redis\\redis.windows.conf | findstr /V \"^$\"\""
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode('utf-8', errors='ignore').strip())

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
