from pymongo import MongoClient
from datetime import datetime

def main():
    client = MongoClient("mongodb://vfit_app:VFITAa123%40mongo_app@127.0.0.1:27017/vfit?authSource=vfit")
    db = client['vfit']
    
    email = "dg.hungdung@gmail.com"
    user = db.users.find_one({"email": email})
    
    if not user:
        print(f"[-] User {email} not found!")
        return
        
    print("=== USER DOCUMENT ===")
    print(f"ID: {user.get('_id')}")
    print(f"Email: {user.get('email')}")
    print(f"Role: {user.get('role')}")
    print(f"Onboarding Status: {user.get('onboardingStatus')}")
    print(f"Active: {user.get('active')}")
    
    sub_snapshot = user.get('subscription', {})
    print("\n=== USER SUBSCRIPTION SNAPSHOT ===")
    print(f"Status: {sub_snapshot.get('status')}")
    print(f"Plan Code: {sub_snapshot.get('planCode')}")
    print(f"Premium Until: {sub_snapshot.get('premiumUntil')}")
    
    print("\n=== SUBSCRIPTIONS COLLECTION ===")
    user_id = str(user.get('_id'))
    subscriptions = list(db.subscriptions.find({"userId": user_id}).sort("expiresAt", -1))
    print(f"Found {len(subscriptions)} subscription records:")
    for sub in subscriptions:
        print(f"  - ID: {sub.get('_id')}, Plan: {sub.get('planCode')}, Status: {sub.get('status')}, Expires: {sub.get('expiresAt')}")

if __name__ == "__main__":
    main()
