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
        
        # Install psutil synchronously
        print("[*] Installing psutil on system python...")
        stdin, stdout, stderr = ssh.exec_command("pip install psutil")
        exit_status = stdout.channel.recv_exit_status()
        print(f"[+] pip install status: {exit_status}")
        
        env_inspect_script = """
import os
import psutil

try:
    p = psutil.Process(86328)
    env = p.environ()
    print("=== Environment of process 86328 ===")
    for k, v in sorted(env.items()):
        if 'GEMINI' in k or 'MODEL' in k or 'URL' in k or 'PORT' in k:
            print(f"{k}={v}")
except Exception as e:
    print(f"Error inspecting process 86328: {e}")

try:
    p = psutil.Process(93148)
    env = p.environ()
    print("=== Environment of process 93148 ===")
    for k, v in sorted(env.items()):
        if 'GEMINI' in k or 'MODEL' in k or 'URL' in k or 'PORT' in k:
            print(f"{k}={v}")
except Exception as e:
    print(f"Error inspecting process 93148: {e}")
"""
        
        print("[*] Running environment variables inspection script...")
        stdin, stdout, stderr = ssh.exec_command("python")
        stdin.write(env_inspect_script)
        stdin.close()
        print(stdout.read().decode('utf-8', errors='replace'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
