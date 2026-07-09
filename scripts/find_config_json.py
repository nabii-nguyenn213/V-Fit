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
        
        # Search for config.json files in C:\V-Fit
        print("\n--- Searching for config.json ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-ChildItem -Path C:\\V-Fit -Filter config.json -Recurse -ErrorAction SilentlyContinue | Select-Object FullName"'
        )
        print(stdout.read().decode('utf-8'))
        
        # Let's also check the uvicorn logs to see if they show any errors
        print("\n--- RecommendationSystem logs (tail stdout.log) ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stdout.log -Tail 30"'
        )
        print(stdout.read().decode('utf-8'))
        
        print("\n--- RecommendationSystem logs (tail stderr.log) ---")
        stdin, stdout, stderr = ssh.exec_command(
            'powershell -Command "Get-Content C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem\\stderr.log -Tail 30"'
        )
        print(stdout.read().decode('utf-8'))

        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
