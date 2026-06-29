import sys
import paramiko

def run_remote_command(cmd):
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"

    print(f"[*] Executing remote command: {cmd}")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Read outputs
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')
        
        term_enc = sys.stdout.encoding or 'utf-8'
        print("\n=== VPS COMMAND OUTPUT ===")
        if out:
            safe_out = out.encode(term_enc, errors='replace').decode(term_enc)
            print(safe_out)
        if err:
            safe_err = err.encode(term_enc, errors='replace').decode(term_enc)
            print(f"[ERROR OUTPUT]:\n{safe_err}")
        print("==========================\n")
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed to run command: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_vps_command.py \"<command>\"")
        sys.exit(1)
    run_remote_command(sys.argv[1])
