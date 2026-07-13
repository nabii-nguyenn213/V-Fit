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
        
        # Look for MONGODB_URI in both .env and .env.production
        run_ssh_command(ssh, "findstr /i \"MONGODB_URI\" C:\\V-Fit\\VFIT_Backend\\.env")
        run_ssh_command(ssh, "findstr /i \"MONGODB_URI\" C:\\V-Fit\\VFIT_Backend\\.env.production")
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
