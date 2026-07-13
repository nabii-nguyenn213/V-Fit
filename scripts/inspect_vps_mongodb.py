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
    
    print("[*] Connecting to VPS via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH Connection successful!")
        
        # Check mongosh or mongo availability
        run_ssh_command(ssh, "mongosh --version")
        run_ssh_command(ssh, "mongo --version")
        
        # Let's see what databases exist in mongodb
        # By default, V-Fit probably uses a db named 'vfit' or similar.
        # Let's find collections and counts.
        # Let's run a mongosh script to query user and transaction counts.
        js_query = (
            "show dbs;"
        )
        run_ssh_command(ssh, f'mongosh --eval "show dbs"')
        
        # Let's search inside the databases
        # We can run a script to inspect collections in the 'vfit' database (or whatever the db name is).
        # We will write a small js file on the VPS and run it with mongosh, or run eval command.
        # Let's check what database is used by Spring Boot.
        # Let's run a command to search application.properties or application.yml in C:\V-Fit\VFIT_Backend
        run_ssh_command(ssh, 'type C:\\V-Fit\\VFIT_Backend\\src\\main\\resources\\application.yml')
        run_ssh_command(ssh, 'type C:\\V-Fit\\VFIT_Backend\\src\\main\\resources\\application.properties')
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
