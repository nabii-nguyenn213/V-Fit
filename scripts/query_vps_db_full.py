import paramiko
import os
import json

def main():
    hostname = "103.118.29.205"
    username = "Administrator"
    password = "VFITAa123@"
    
    # Define the remote query script content
    remote_script_content = """import pymongo
import json
import decimal
from datetime import datetime

class CustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        try:
            from bson import ObjectId
            if isinstance(obj, ObjectId):
                return str(obj)
        except ImportError:
            pass
        return super().default(obj)

def main():
    uri = "mongodb://vfit_app:vfit_app_dev_password@127.0.0.1:27017/vfit?authSource=vfit"
    client = pymongo.MongoClient(uri)
    db = client.vfit
    
    # User metrics
    total_users = db.users.count_documents({})
    roles = db.users.distinct("role")
    non_admin_users = db.users.count_documents({"role": {"$ne": "ADMIN"}})
    
    # Active VIP users
    vip_users = db.users.count_documents({
        "role": {"$ne": "ADMIN"},
        "subscription.status": "ACTIVE"
    })
    
    onboarding_completed = db.users.count_documents({
        "role": {"$ne": "ADMIN"},
        "onboardingStatus": "COMPLETED"
    })
    onboarding_pending = db.users.count_documents({
        "role": {"$ne": "ADMIN"},
        "onboardingStatus": "PENDING"
    })
    
    # Payment/Transaction metrics
    total_transactions = db.payment_transactions.count_documents({})
    # Check statuses
    statuses = db.payment_transactions.distinct("paymentStatus")
    
    # Sum up successful transactions
    # Spring Boot uses "SUCCESS" status
    success_status_matches = db.payment_transactions.find({"paymentStatus": "SUCCESS"})
    total_rev = 0.0
    tx_count = 0
    reconciled_count = 0
    sample_txs = []
    
    for tx in success_status_matches:
        tx_count += 1
        amt = tx.get("finalAmount") or tx.get("amount") or tx.get("baseAmount")
        if amt is not None:
            total_rev += float(str(amt))
        if tx.get("sepayTransactionId"):
            reconciled_count += 1
        if len(sample_txs) < 15:
            sample_txs.append({
                "id": str(tx.get("_id")),
                "userId": tx.get("userId"),
                "plan": str(tx.get("plan")),
                "finalAmount": str(tx.get("finalAmount")),
                "amount": str(tx.get("amount")),
                "paymentStatus": tx.get("paymentStatus"),
                "sepayTransactionId": tx.get("sepayTransactionId"),
                "paidAt": str(tx.get("paidAt"))
            })
            
    # Visitor Log metrics
    visitor_count = db.visitor_logs.count_documents({})
    
    result = {
        "roles": roles,
        "total_users_in_db": total_users,
        "non_admin_registered_users": non_admin_users,
        "active_vip_users": vip_users,
        "onboarding_completed": onboarding_completed,
        "onboarding_pending": onboarding_pending,
        "total_transactions_in_db": total_transactions,
        "successful_transactions_count": tx_count,
        "payment_statuses_found": statuses,
        "total_revenue": total_rev,
        "reconciled_transactions_count": reconciled_count,
        "visitor_count": visitor_count,
        "sample_transactions": sample_txs
    }
    
    print(json.dumps(result, indent=2, cls=CustomEncoder))

if __name__ == "__main__":
    main()
"""

    print("[*] Connecting to VPS via SSH...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(hostname, username=username, password=password, timeout=20)
        print("[+] Connection successful!")
        
        # Write query_db.py script on remote VPS using SFTP
        sftp = ssh.open_sftp()
        remote_file_path = "C:\\V-Fit\\query_db.py"
        print(f"[*] Uploading query script to {remote_file_path}...")
        with sftp.file(remote_file_path, 'w') as f:
            f.write(remote_script_content)
        sftp.close()
        print("[+] Upload successful!")
        
        # Run python script with Virtual Env python interpreter
        venv_python = "C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\\Scripts\\python.exe"
        run_cmd = f"{venv_python} C:\\V-Fit\\query_db.py"
        print(f"[*] Running command: {run_cmd}")
        stdin, stdout, stderr = ssh.exec_command(run_cmd)
        
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')
        
        if "ModuleNotFoundError" in err or "No module named 'pymongo'" in err:
            print("[*] pymongo not found on VPS. Installing via pip...")
            venv_pip = "C:\\V-Fit\\AI-VFIT\\V-Fit\\.venv\\Scripts\\pip.exe"
            pip_cmd = f"{venv_pip} install pymongo"
            print(f"[*] Running command: {pip_cmd}")
            p_in, p_out, p_err = ssh.exec_command(pip_cmd)
            p_out.read()  # Wait for install to complete
            
            # Retry executing query script
            print(f"[*] Retrying command: {run_cmd}")
            stdin, stdout, stderr = ssh.exec_command(run_cmd)
            out = stdout.read().decode('utf-8', errors='ignore')
            err = stderr.read().decode('utf-8', errors='ignore')
            
        print("\n=== LIVE VPS DATABASE METRICS ===")
        if out:
            print(out)
        if err:
            print("[STDERR]")
            print(err)
        print("================================")
        
        ssh.close()
    except Exception as e:
        print(f"[ERROR] Failed: {e}")

if __name__ == "__main__":
    main()
