import paramiko
import sys

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    print(f"[*] Connecting to {hostname} via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] SSH connection successful!")
        
        mongo_script = """
import pymongo
uri = "mongodb://vfit_app:VFITAa123%40mongo_app@127.0.0.1:27017/vfit?authSource=vfit"
client = pymongo.MongoClient(uri)
db = client.vfit
res = db.users.update_one(
    {"email": "tranduytrung251105@gmail.com"},
    {"$set": {"subscription.planCode": "VIP_MONTHLY"}}
)
print("Modified count:", res.modified_count)
"""
        stdin, stdout, stderr = ssh.exec_command("python")
        stdin.write(mongo_script)
        stdin.close()
        print(stdout.read().decode('utf-8', errors='ignore'))
        ssh.close()
        
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
