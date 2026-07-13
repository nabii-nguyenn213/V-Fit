import paramiko

def run_ssh_command(ssh, cmd):
    print(f"[*] Running command: {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore')
    err = stderr.read().decode('utf-8', errors='ignore')
    if out:
        print("[STDOUT]")
        print(out)
    if err:
        print("[STDERR]")
        print(err)
    return out, err

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH Connection successful!")
        
        # 1. Print environment variables
        run_ssh_command(ssh, "set")
        
        # 2. Get Java process command line
        run_ssh_command(ssh, "wmic process where \"name='java.exe'\" get commandline")
        
        # 3. Check for any environment files (.env) in V-Fit directories
        run_ssh_command(ssh, "dir C:\\V-Fit /s /b | findstr /i \".env\"")
        
        # 4. Check for startup scripts (bat, cmd, ps1)
        run_ssh_command(ssh, "dir C:\\V-Fit\\*.bat C:\\V-Fit\\*.ps1 C:\\V-Fit\\*.cmd /s /b")
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
