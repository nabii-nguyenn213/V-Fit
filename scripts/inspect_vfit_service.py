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
        
        # 1. sc qc vfit-backend
        print("\n--- sc qc vfit-backend ---")
        stdin, stdout, stderr = ssh.exec_command("sc.exe qc vfit-backend")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # 2. sc query vfit-backend
        print("\n--- sc query vfit-backend ---")
        stdin, stdout, stderr = ssh.exec_command("sc.exe query vfit-backend")
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # 3. Get-Service vfit-backend status via Powershell
        print("\n--- Get-Service vfit-backend ---")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"Get-Service vfit-backend | Select-Object *\"")
        print(stdout.read().decode('utf-8', errors='ignore'))

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
