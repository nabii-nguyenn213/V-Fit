import paramiko
import sys
import time
import traceback

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connected to VPS.")
        
        # Start redis-server in background redirecting to log
        print("\n--- Running redis-server.exe in background ---")
        cmd1 = "cmd.exe /c \"C:\\Redis\\redis-server.exe --maxmemory 200mb > C:\\Redis\\temp_redis.log 2>&1\""
        # Run it asynchronously by not waiting for it
        transport = ssh.get_transport()
        channel = transport.open_session()
        channel.exec_command(cmd1)
        
        time.sleep(3)
        
        # Kill it
        print("[*] Killing redis-server...")
        stdin, stdout, stderr = ssh.exec_command("taskkill /F /IM redis-server.exe")
        stdout.channel.recv_exit_status()
        
        # Read log file
        print("\n--- Redis Startup Output ---")
        stdin, stdout, stderr = ssh.exec_command("cmd.exe /c type C:\\Redis\\temp_redis.log")
        stdout.channel.recv_exit_status()
        print(stdout.read().decode('utf-8', errors='ignore').strip())
        
        # Delete log file
        stdin, stdout, stderr = ssh.exec_command("cmd.exe /c del C:\\Redis\\temp_redis.log")
        stdout.channel.recv_exit_status()
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")
        traceback.print_exc()

if __name__ == "__main__":
    main()
