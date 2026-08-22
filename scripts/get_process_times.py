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
        print("[+] SSH connection successful!")
        
        # Get creation dates
        print("\n--- Process Creation Dates ---")
        cmd = (
            'powershell -Command "'
            'Get-CimInstance Win32_Process -Filter \\"ProcessId in (86328, 93148, 77152, 90944, 88308)\\" | '
            'Select-Object ProcessId, Name, CreationDate, CommandLine | Format-List'
            '"'
        )
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode('utf-8', errors='replace'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
