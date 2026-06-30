import paramiko

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=15)
        
        # Python command to execute on the VPS
        py_cmd = (
            "python -c \""
            "import os; "
            "log_path = 'C:/V-Fit/VFIT_Backend/stdout.log'; "
            "lines = open(log_path, 'r', errors='ignore').readlines()[-1000:] if os.path.exists(log_path) else []; "
            "[print(l.strip()) for l in lines if '01:32:' in l]"
            "\""
        )
        
        stdin, stdout, stderr = ssh.exec_command(py_cmd)
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')
        
        print("=== Remote WebSocket Logs ===")
        print(out)
        if err:
            print(f"=== Error Output ===\n{err}")
            
        ssh.close()
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    main()
