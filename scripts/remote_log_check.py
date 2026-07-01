import paramiko
import sys
import os

def check_log(ssh, name, path, keywords, out_file):
    out_file.write(f"\n==========================================\n")
    out_file.write(f"Checking Log: {name} ({path})\n")
    out_file.write(f"==========================================\n")
    
    script_content = f"""
import os
path = r'{path}'
keywords = {keywords}
if not os.path.exists(path):
    print('[Log file does not exist]')
    exit(0)

lines = []
for enc in ['utf-8', 'utf-16', 'utf-16-le', 'latin-1']:
    try:
        with open(path, 'r', encoding=enc, errors='ignore') as f:
            test_lines = f.readlines()[-400:]
            if test_lines and any(len(line.strip()) > 0 for line in test_lines):
                lines = test_lines
                break
    except Exception:
        continue

try:
    matched = []
    for line in lines:
        line_lower = line.lower()
        if any(k.lower() in line_lower for k in keywords):
            matched.append(line.strip())
    if matched:
        for m in matched[-50:]:
            print(m)
    else:
        print('[No matching lines found]')
except Exception as e:
    print(f'[Error searching file: {{e}}]')
"""
    
    stdin, stdout, stderr = ssh.exec_command("python")
    stdin.write(script_content)
    stdin.close()
    
    out = stdout.read().decode('utf-8', errors='ignore')
    err = stderr.read().decode('utf-8', errors='ignore')
    
    if out.strip():
        out_file.write(out + "\n")
    else:
        out_file.write("[No matching lines found]\n")
        
    if err.strip():
        out_file.write(f"Error executing python script: {err}\n")

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    # Ensure artifacts folder exists
    os.makedirs("d:\\EXE_PRM\\artifacts", exist_ok=True)
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=15)
        
        with open("d:\\EXE_PRM\\artifacts\\remote_logs.txt", "w", encoding="utf-8") as out_file:
            # Check Caddy logs
            check_log(
                ssh, 
                "Caddy Access Log", 
                "C:\\V-Fit\\caddy_access_real.log", 
                ["/ws/"],
                out_file
            )
            
            # Check backend logs
            check_log(
                ssh, 
                "Backend Stdout", 
                "C:\\V-Fit\\VFIT_Backend\\stdout.log", 
                ["websocket", "ws/ai", "FormCheckWebSocketHandler", "error", "exception", "failed", "handshake", "unauthorized", "jwt"],
                out_file
            )
            
        print("[*] Log collection complete. Results written to artifacts/remote_logs.txt")
        ssh.close()
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    main()


