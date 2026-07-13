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
        
        # Check system memory via wmic
        print("\n--- System Memory Status (WMI) ---")
        stdin, stdout, stderr = ssh.exec_command("wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # Check running processes sorted by memory or just tasklist
        print("\n--- Raw Tasklist ---")
        stdin, stdout, stderr = ssh.exec_command("tasklist")
        # Print top 40 lines of tasklist
        out = stdout.read().decode('utf-8', errors='ignore').strip()
        lines = out.split('\n')
        for line in lines[:50]:
            print(line)
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
