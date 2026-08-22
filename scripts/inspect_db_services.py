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
        
        # Query services matching redis or mongo
        print("\n--- Service status for MongoDB / Redis ---")
        for service_name in ["redis", "MongoDB", "mongod", "Redis", "redis-server"]:
            print(f"\nQuerying: {service_name}")
            stdin, stdout, stderr = ssh.exec_command(f"sc.exe query {service_name}")
            print(stdout.read().decode('utf-8', errors='ignore').strip())
            
        ssh.close()
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
