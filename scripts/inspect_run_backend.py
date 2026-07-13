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
        
        # Check current time on VPS
        print("\n--- VPS Date and Time ---")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"Get-Date\"")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # Check current timestamp of stdout.log using Get-Item
        print("\n--- stdout.log details ---")
        stdin, stdout, stderr = ssh.exec_command("powershell -Command \"Get-Item C:\\V-Fit\\VFIT_Backend\\stdout.log | Select-Object LastWriteTime, Length\"")
        print(stdout.read().decode('utf-8', errors='ignore').strip())

        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
