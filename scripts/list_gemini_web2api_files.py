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
        
        # Check files in C:\V-Fit\gemini-web2api
        print("\n--- C:\\V-Fit\\gemini-web2api Files ---")
        stdin, stdout, stderr = ssh.exec_command("dir C:\\V-Fit\\gemini-web2api")
        print(stdout.read().decode('utf-8'))
        
        # Print gemini-web2api config.json
        print("\n--- config.json content ---")
        stdin, stdout, stderr = ssh.exec_command("type C:\\V-Fit\\gemini-web2api\\config.json")
        print(stdout.read().decode('utf-8'))
        
        # Check files in C:\V-Fit\AI-VFIT\V-Fit\RecommendationSystem
        print("\n--- C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem Files ---")
        stdin, stdout, stderr = ssh.exec_command("dir C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem")
        print(stdout.read().decode('utf-8'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
