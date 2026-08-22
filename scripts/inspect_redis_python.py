import paramiko
import sys
import os

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connected to VPS.")
        
        # Write python script to VPS
        remote_script_code = """
import os
import subprocess

def inspect_file(path):
    print(f"\\n--- Inspecting {path} ---")
    if not os.path.exists(path):
        print("File not found.")
        return
    try:
        # Try reading as UTF-16 first, then UTF-8
        try:
            with open(path, 'r', encoding='utf-16') as f:
                content = f.read()
        except Exception:
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
        lines = content.split('\\n')
        active_lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith('#')]
        for l in active_lines[:50]:
            print(l)
    except Exception as e:
        print(f"Error reading file: {e}")

inspect_file("C:\\\\Redis\\\\redis.windows-service.conf")
inspect_file("C:\\\\Redis\\\\redis.windows.conf")

# Try to run redis-server manually and capture its stderr
print("\\n--- Running redis-server.exe manually ---")
try:
    proc = subprocess.Popen(
        ["C:\\\\Redis\\\\redis-server.exe", "C:\\\\Redis\\\\redis.windows-service.conf"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd="C:\\\\Redis"
    )
    try:
        stdout, stderr = proc.communicate(timeout=4)
        print("STDOUT:")
        print(stdout)
        print("STDERR:")
        print(stderr)
    except subprocess.TimeoutExpired:
        proc.terminate()
        stdout, stderr = proc.communicate()
        print("STDOUT (Timeout):")
        print(stdout)
        print("STDERR (Timeout):")
        print(stderr)
except Exception as e:
    print(f"Error running redis: {e}")
"""
        sftp = ssh.open_sftp()
        with sftp.file("C:\\V-Fit\\inspect_redis_temp.py", "w") as f:
            f.write(remote_script_code)
        sftp.close()
        print("[+] Uploaded remote inspection script.")
        
        # Run remote script
        stdin, stdout, stderr = ssh.exec_command("python C:\\V-Fit\\inspect_redis_temp.py")
        print("\n=== REMOTE PYTHON DIAGNOSTIC OUTPUT ===")
        print(stdout.read().decode('utf-8', errors='ignore'))
        print(stderr.read().decode('utf-8', errors='ignore'))
        
        # Cleanup
        ssh.exec_command("del C:\\V-Fit\\inspect_redis_temp.py")
        print("[+] Cleaned up remote inspection script.")
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
