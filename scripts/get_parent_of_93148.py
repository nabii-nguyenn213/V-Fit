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
        
        # Get ParentProcessId of 93148
        print("\n--- Parent Process of 93148 ---")
        cmd = (
            'powershell -Command "'
            '$pid_child = 93148; '
            '$parent_id = (Get-CimInstance Win32_Process -Filter \\"ProcessId = $pid_child\\").ParentProcessId; '
            'Write-Host \\"Parent Process ID: $parent_id\\"; '
            'if ($parent_id) {{ '
            '  Get-CimInstance Win32_Process -Filter \\"ProcessId = $parent_id\\" | Select-Object Name, CommandLine | Format-List '
            '}}'
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
