import paramiko
import sys
import json

def execute_remote_cmd(ssh, cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    return exit_status, out, err

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # 1. Check listening ports
        print("\n--- Listening Ports (looking for 8080, 8081, 8082, 8085, 8000, 8002) ---")
        status, out, err = execute_remote_cmd(ssh, "netstat -ano | findstr LISTENING")
        print(out)
        
        # 2. Check running python processes
        print("\n--- Running Python Processes ---")
        status, out, err = execute_remote_cmd(ssh, "tasklist /FI \"IMAGENAME eq python.exe\"")
        print(out)
        
        # 3. Check C:\V-Fit directory
        print("\n--- C:\\V-Fit contents ---")
        status, out, err = execute_remote_cmd(ssh, "dir C:\\V-Fit")
        print(out)
        
        # 4. Check pm2 / pm2 list or docker ps
        print("\n--- Docker Containers ---")
        status, out, err = execute_remote_cmd(ssh, "docker ps -a")
        print(out)
        
        print("\n--- PM2 status ---")
        status, out, err = execute_remote_cmd(ssh, "pm2 status")
        print(out)
        
        # 5. Let's see if we can do a curl to web2api locally on the VPS
        print("\n--- Curl Local Web2API endpoints ---")
        # Try both 8082 and 8085, or whatever ports we find
        status, out, err = execute_remote_cmd(ssh, "powershell -Command \"Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8082/v1/models | Select-Object -ExpandProperty Content\"")
        print(f"Port 8082: Status={status}")
        if status == 0:
            print(out)
        else:
            print(f"Error: {err}")
            
        status, out, err = execute_remote_cmd(ssh, "powershell -Command \"Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8085/v1/models | Select-Object -ExpandProperty Content\"")
        print(f"Port 8085: Status={status}")
        if status == 0:
            print(out)
        else:
            print(f"Error: {err}")

        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
