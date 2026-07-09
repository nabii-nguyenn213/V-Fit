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
        # Check size of .venv directories
        cmd = (
            'powershell -Command "'
            'function Get-DirSize($path) { '
            '  if (Test-Path $path) { '
            '    $size = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; '
            '    return [Math]::Round($size / 1MB, 2); '
            '  } else { return 0 } '
            '}; '
            'Write-Host \\"AI Root .venv size: $(Get-DirSize C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv) MB\\"; '
            'Write-Host \\"RecommendationSystem .venv size: $(Get-DirSize C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\.venv) MB\\"; '
            '"'
        )
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode('utf-8'))
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
