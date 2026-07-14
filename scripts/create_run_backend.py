import paramiko

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"

    print("[*] Connecting to VPS...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=username, password=password, timeout=15)
    
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
java -Xms256m -Xmx512m -jar target\\vfit-backend-0.1.0.jar
"""

    print("[*] Creating run_backend.ps1 on VPS...")
    sftp = ssh.open_sftp()
    with sftp.file(r"C:\V-Fit\VFIT_Backend\run_backend.ps1", "w") as f:
        f.write(ps_content)
    sftp.close()
    print("[+] Successfully created C:\\V-Fit\\VFIT_Backend\\run_backend.ps1")
    
    # Try starting the service
    print("[*] Starting vfit-backend service...")
    stdin, stdout, stderr = ssh.exec_command("powershell Start-Service vfit-backend")
    exit_status = stdout.channel.recv_exit_status()
    print(f"Start-Service exit status: {exit_status}")
    print(stdout.read().decode('utf-8', errors='ignore'))
    print(stderr.read().decode('utf-8', errors='ignore'))
    
    ssh.close()

if __name__ == "__main__":
    main()
