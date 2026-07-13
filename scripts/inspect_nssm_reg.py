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
        
        # reg query HKLM\System\CurrentControlSet\Services\vfit-backend /s
        print("\n--- Registry Configuration ---")
        stdin, stdout, stderr = ssh.exec_command("reg query HKLM\\System\\CurrentControlSet\\Services\\vfit-backend /s")
        print(stdout.read().decode('utf-8', errors='ignore'))

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
