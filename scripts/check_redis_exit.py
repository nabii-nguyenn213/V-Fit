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
        print("[+] Connected to VPS.")
        
        # Run redis-server.exe --version
        print("\n--- Running redis-server.exe --version ---")
        stdin, stdout, stderr = ssh.exec_command("C:\\Redis\\redis-server.exe --version")
        exit_status = stdout.channel.recv_exit_status()
        print(f"Exit code: {exit_status}")
        print("STDOUT:")
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        print("STDERR:")
        print(stderr.read().decode('utf-8', errors='ignore').strip())
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
