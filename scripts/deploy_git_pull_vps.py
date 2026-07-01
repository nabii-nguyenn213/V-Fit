import paramiko
import sys

def execute_remote_cmd(ssh, cmd):
    print(f"[*] Running: {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    
    # Wait for the command to finish
    exit_status = stdout.channel.recv_exit_status()
    
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    
    return exit_status, out, err

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        # 1. Remove blocking files on the VPS
        print("[*] Removing blocking untracked files on the VPS...")
        cleanup_script = """
import os
import shutil
files = [
    r'C:\\V-Fit\\VFIT_Backend\\web\\googlec5a363f8efe4656c.html',
    r'C:\\V-Fit\\VFIT_Backend\\web\\sitemap.xml',
    r'C:\\V-Fit\\VFIT_Fontend\\web\\googlec5a363f8efe4656c.html',
    r'C:\\V-Fit\\VFIT_Fontend\\web\\robots.txt',
    r'C:\\V-Fit\\VFIT_Fontend\\web\\sitemap.xml',
    r'C:\\V-Fit\\scripts\\send_survey_emails.py'
]
for f in files:
    if os.path.exists(f):
        try:
            os.remove(f)
            print(f'Removed file: {f}')
        except Exception as e:
            print(f'Error removing file {f}: {e}')

folders = [
    r'C:\\V-Fit\\AI-VFIT',
    r'C:\\V-Fit\\gemini-web2api'
]
for folder in folders:
    if os.path.exists(folder):
        try:
            shutil.rmtree(folder, ignore_errors=True)
            print(f'Removed folder: {folder}')
        except Exception as e:
            print(f'Error removing folder {folder}: {e}')
"""
        stdin, stdout, stderr = ssh.exec_command("python")
        stdin.write(cleanup_script)
        stdin.close()
        print(stdout.read().decode('utf-8', errors='ignore'))
        
        # 2. Run git fetch and reset to origin/010-deploy-play-store
        print("[*] Resetting and cleaning working tree on VPS...")
        execute_remote_cmd(ssh, "git -C C:\\V-Fit reset --hard HEAD")
        execute_remote_cmd(ssh, "git -C C:\\V-Fit clean -xffd")
        print("[*] Performing git fetch and reset to origin branch on VPS...")
        execute_remote_cmd(ssh, "git -C C:\\V-Fit fetch origin")
        status, out, err = execute_remote_cmd(ssh, "git -C C:\\V-Fit reset --hard origin/010-deploy-play-store")
        print(f"Git fetch/reset status: {status}")
        print(f"Output:\n{out}")
        if err:
            print(f"Error output:\n{err}")
            
        if status != 0:
            print("[ERROR] Git fetch and reset failed!")
            sys.exit(1)
            
        # 3. Stop backend service
        print("[*] Stopping vfit-backend service...")
        status, out, err = execute_remote_cmd(ssh, "powershell Stop-Service vfit-backend")
        if status != 0:
            print(f"[WARNING] Failed to stop service or service already stopped: {err}")
        else:
            print("[+] Stopped vfit-backend service.")
            
        # 4. Build backend on VPS
        print("[*] Compiling and packaging backend on VPS (mvn clean package -DskipTests)...")
        cmd_build = "powershell -Command \"cd C:\\V-Fit\\VFIT_Backend; mvn clean package -DskipTests\""
        status, out, err = execute_remote_cmd(ssh, cmd_build)
        
        print("\n=== BUILD OUTPUT ===")
        print(out)
        if err:
            print(f"[BUILD ERROR/WARNING]:\n{err}")
        print("====================\n")
        
        if status != 0:
            print("[ERROR] Maven build failed! Re-starting the original service...")
            execute_remote_cmd(ssh, "powershell Start-Service vfit-backend")
            sys.exit(1)
            
        print("[+] Maven build succeeded!")
        
        # 5. Write run_backend.ps1 (since git clean deleted it)
        print("[*] Re-creating run_backend.ps1 on VPS...")
        ps_content = """$ErrorActionPreference = 'Stop'
$projectPath = "C:\\V-Fit\\VFIT_Backend"
cd $projectPath

# Load environment variables from .env.production
if (Test-Path .env.production) {
    Get-Content .env.production | Foreach-Object {
        if ($_ -match '^\\s*([^#=\\s]+)\\s*=\\s*(.*)$') {
            $name = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            # Set for the current process
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Run the jar in the foreground (so nssm can monitor it)
java -jar target\\vfit-backend-0.1.0.jar
"""
        sftp = ssh.open_sftp()
        with sftp.file(r"C:\V-Fit\VFIT_Backend\run_backend.ps1", "w") as f:
            f.write(ps_content)
        sftp.close()
        print("[+] Successfully recreated C:\\V-Fit\\VFIT_Backend\\run_backend.ps1")
        
        # 6. Start backend service
        print("[*] Starting vfit-backend service...")
        status, out, err = execute_remote_cmd(ssh, "powershell Start-Service vfit-backend")
        if status != 0:
            print(f"[ERROR] Failed to start service: {err}")
            sys.exit(1)
        print("[+] Started vfit-backend service successfully.")
        
        ssh.close()
        print("[+] Finished deployment.")
        
    except Exception as e:
        print(f"[ERROR] Deployment script failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
