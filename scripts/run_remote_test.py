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
        print("[+] SSH connection successful!")
        
        # Upload the script
        sftp = ssh.open_sftp()
        local_path = r"d:\EXE_PRM\scripts\test_remote_api.py"
        remote_path = r"C:\V-Fit\test_remote_api.py"
        print(f"[*] Uploading test script to VPS: {remote_path}")
        sftp.put(local_path, remote_path)
        sftp.close()
        
        # Execute the test script
        print("[*] Executing test script on VPS...")
        stdin, stdout, stderr = ssh.exec_command(f"python {remote_path}")
        exit_status = stdout.channel.recv_exit_status()
        out = stdout.read().decode('utf-8', errors='ignore').strip()
        err = stderr.read().decode('utf-8', errors='ignore').strip()
        
        print(f"\n--- Test Output (Exit Status: {exit_status}) ---")
        if out:
            print("[Out]:")
            print(out)
        if err:
            print("[Err]:")
            print(err)
            
        # Clean up
        print("\n[*] Cleaning up test script from VPS...")
        ssh.exec_command(f"del {remote_path}")
        ssh.close()
        print("[+] Done!")
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
