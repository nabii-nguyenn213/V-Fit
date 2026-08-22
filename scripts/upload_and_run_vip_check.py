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
        
        # Upload check_user_vip_status.py to VPS C:\V-Fit\scripts\check_user_vip_status.py
        sftp = ssh.open_sftp()
        sftp.put("d:\\EXE_PRM\\scripts\\check_user_vip_status.py", "C:\\V-Fit\\scripts\\check_user_vip_status.py")
        sftp.close()
        print("[+] Script uploaded to VPS.")
        
        # Run script on VPS
        print("[*] Running script on VPS...")
        stdin, stdout, stderr = ssh.exec_command("python C:\\V-Fit\\scripts\\check_user_vip_status.py")
        print(stdout.read().decode('utf-8'))
        print(stderr.read().decode('utf-8'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")

if __name__ == "__main__":
    main()
