import os
import sys
import paramiko

def main():
    # Set terminal output encoding if possible
    if hasattr(sys.stdout, 'reconfigure'):
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except:
            pass

    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    local_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "send_survey_emails.py")
    remote_script = "C:\\V-Fit\\scripts\\send_survey_emails.py"
    
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=15)
        print("[+] SSH connection successful!")
        
        # Open SFTP client
        print(f"[*] Opening SFTP connection to upload script...")
        sftp = ssh.open_sftp()
        sftp.put(local_script, remote_script)
        sftp.close()
        print(f"[+] Successfully uploaded send_survey_emails.py to VPS at: {remote_script}")
        
        # Run a dry-run test on the VPS to verify MongoDB connection and list users
        print("[*] Running dry-run check on the VPS...")
        cmd = f"python {remote_script} --form-url \"https://forms.gle/test-survey\" --dry-run"
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Read outputs
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')
        
        term_enc = sys.stdout.encoding or 'utf-8'
        print("\n=== VPS DRY-RUN OUTPUT ===")
        if out:
            # Handle terminal encoding limitations by replacing unprintable characters
            safe_out = out.encode(term_enc, errors='replace').decode(term_enc)
            print(safe_out)
        if err:
            safe_err = err.encode(term_enc, errors='replace').decode(term_enc)
            print(f"[ERROR OUTPUT]:\n{safe_err}")
        print("==========================\n")
        
        ssh.close()
        print("[+] Finished deploy process.")
        
    except Exception as e:
        print(f"[ERROR] Failed to deploy or run script: {e}")

if __name__ == "__main__":
    main()
