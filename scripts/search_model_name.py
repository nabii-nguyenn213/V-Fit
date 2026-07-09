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
        
        # Search script
        search_script = """
import os

paths_to_search = [
    r'C:\\V-Fit\\AI-VFIT\\V-Fit\\RecommendationSystem',
    r'C:\\V-Fit\\VFIT_Backend',
    r'C:\\V-Fit\\gemini-web2api',
    r'C:\\V-Fit'
]

allowed_extensions = {'.py', '.json', '.yaml', '.yml', '.env', '.properties', '.xml', '.txt', '.bat', '.ps1', '.conf', '.cfg', '.ini'}

found = False
for base_path in paths_to_search:
    if not os.path.exists(base_path):
        continue
    # Only search top levels or specific subdirs to keep it fast
    for root, dirs, files in os.walk(base_path):
        # Skip directories we don't care about
        if any(skip in root for skip in ['.git', '.venv', 'node_modules', '__pycache__', 'target', '.idea', 'GradleCache', 'AndroidUserHome', 'PubCache']):
            continue
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in allowed_extensions or file.startswith('.env'):
                fpath = os.path.join(root, file)
                try:
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                        for line_num, line in enumerate(f, 1):
                            if 'gemini-2.5-flash' in line:
                                print(f"Found in {fpath} on line {line_num}: {line.strip()}")
                                found = True
                except Exception as e:
                    pass

if not found:
    print("Pattern 'gemini-2.5-flash' not found in any text files.")
"""
        # Execute the python search script on the VPS
        stdin, stdout, stderr = ssh.exec_command("python")
        stdin.write(search_script)
        stdin.close()
        
        # Print output
        print("\n--- Search Results from VPS ---")
        print(stdout.read().decode('utf-8', errors='replace'))
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
