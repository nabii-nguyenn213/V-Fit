import pymongo
from datetime import datetime, timedelta
import csv

# VPS MongoDB Connection details (from .env.production)
MONGODB_URI = "mongodb://vfit_app:VFITAa123%40mongo_app@127.0.0.1:27017/vfit?authSource=vfit&maxPoolSize=100&minPoolSize=10&maxIdleTimeMS=60000&serverSelectionTimeoutMS=5000"

vip_users_data = [
    {"stt": 1, "name": "Hùng nè", "email": "hungbx4869@gmail.com", "amount": 150000, "sepay_id": "68472263", "ref": "5bb9432a-e784-4c57-b10c-d826e6220dc7", "desc": "VFIT20260525172117877", "time": "26/05/2026 00:34:10"},
    {"stt": 2, "name": "ngovthanhh", "email": "ngovthanh0404@gmail.com", "amount": 150000, "sepay_id": "64882464", "ref": "de14df28-821f-4c2b-bff6-497cd2424208", "desc": "VFIT20260629093912415", "time": "20/06/2026 21:57:02"},
    {"stt": 3, "name": "Đăng Ngo", "email": "danglehainguyen@gmail.com", "amount": 150000, "sepay_id": "65619993", "ref": "2aac06ef-96de-4503-b498-66b050c2f54a", "desc": "VFIT20260629064101113", "time": "22/06/2026 13:44:22"},
    {"stt": 4, "name": "Mai Linh", "email": "meilingg2085@gmail.com", "amount": 150000, "sepay_id": "65644683", "ref": "ce7ea8f8-710a-4772-aea2-aea2217af510", "desc": "VFIT20260624145522388", "time": "24/06/2026 21:57:02"},
    {"stt": 5, "name": "bmi cute 2", "email": "ducanh2005hd@gmail.com", "amount": 150000, "sepay_id": "65622374", "ref": "2317c6c9-a40b-46c0-8dd1-7860d0e7e26b", "desc": "VFIT20260629064156428", "time": "25/06/2026 14:03:24"},
    {"stt": 6, "name": "pham nguyen", "email": "nguyenphe182242@fpt.edu.vn", "amount": 150000, "sepay_id": "65642539", "ref": "278a766f-1106-4887-9dda-0295348f263f", "desc": "VFIT20260629092443913", "time": "26/06/2026 16:26:27"},
    {"stt": 7, "name": "Quang Nguyễn", "email": "nguyen.quang6633@gmail.com", "amount": 150000, "sepay_id": "65644918", "ref": "caf5d40c-d92d-4cd3-845f-770eef0ad330", "desc": "VFIT20260629094035989", "time": "27/06/2026 16:41:23"},
    {"stt": 8, "name": "Hieu toa sang", "email": "quyenhieutron@gmail.com", "amount": 150000, "sepay_id": "65645121", "ref": "e637c9ba-1ee8-433f-addd-2ecdb6b1d78e", "desc": "VFIT20260629094207861", "time": "29/06/2026 16:42:36"},
    {"stt": 9, "name": "halo", "email": "hieuhehe0615@gmail.com", "amount": 150000, "sepay_id": "65649527", "ref": "2dbdf913-b738-4568-98f6-56cdd8d20f57", "desc": "VFIT20260629170438318", "time": "29/06/2026 17:05:18"},
    {"stt": 10, "name": "Dũng Dương", "email": "dg.hungdung@gmail.com", "amount": 150000, "sepay_id": "67400859", "ref": "FT26191407312439", "desc": "Qakifp0546 SEPAY18858 1 VFIT20260709170354801", "time": "10/07/2026 00:04:24"},
    {"stt": 11, "name": "Tùng Nguyễn", "email": "tungnguyen27082005@gmail.com", "amount": 150000, "sepay_id": "67664799", "ref": "FT26192123059045", "desc": "Qakifp0546 SEPAY18858 1 137187468665-VFIT20260711073121325", "time": "11/07/2026 14:32:19"},
    {"stt": 12, "name": "Hà Văn Ta", "email": "havanta20111978@gmail.com", "amount": 150000, "sepay_id": "67852864", "ref": "FT26194743473584", "desc": "Qakifp0546 SEPAY18858 1 VFIT20260712095215342", "time": "12/07/2026 16:53:01"},
    {"stt": 13, "name": "Tú Phạm", "email": "phamthitu19833@gmail.com", "amount": 150000, "sepay_id": "67876089", "ref": "FT26194193790121", "desc": "Qakifp0546 SEPAY18858 1 VFIT20260712120517910", "time": "12/07/2026 19:06:39"}
]

def main():
    client = pymongo.MongoClient(MONGODB_URI)
    db = client.vfit
    
    vip_emails = [u["email"].lower().strip() for u in vip_users_data]
    
    print("[*] STEP 1: Updating target 13 users to VIP status...")
    # 1. Update 13 VIP users
    for user_info in vip_users_data:
        email = user_info["email"].lower().strip()
        user = db.users.find_one({"email": email})
        
        premium_until = datetime.utcnow() + timedelta(days=30)
        sub_snapshot = {
            "status": "ACTIVE",
            "planCode": "VIP_1M",
            "premiumUntil": premium_until
        }
        
        if user:
            db.users.update_one(
                {"_id": user["_id"]},
                {"$set": {
                    "subscription": sub_snapshot,
                    "fullName": user_info["name"]
                }}
            )
            print(f"  [+] Updated user {email} to VIP.")
        else:
            new_user = {
                "email": email,
                "fullName": user_info["name"],
                "role": "CUSTOMER",
                "active": True,
                "subscription": sub_snapshot,
                "onboardingStatus": "COMPLETED",
                "createdAt": datetime.utcnow(),
                "updatedAt": datetime.utcnow()
            }
            db.users.insert_one(new_user)
            print(f"  [+] User {email} not found in DB. Created new user and set as VIP.")
            
    print("[*] STEP 2: Downgrading all other non-ADMIN users to FREE...")
    # 2. Downgrade other non-admin users
    db.users.update_many(
        {
            "email": {"$nin": vip_emails},
            "role": {"$ne": "ADMIN"}
        },
        {"$set": {
            "subscription": {
                "status": "FREE",
                "planCode": None,
                "premiumUntil": None
            }
        }}
    )
    print("  [+] All other non-admin accounts successfully updated to FREE status.")
    
    print("[*] STEP 3: Ensuring matching Payment Transactions exist in database...")
    # 3. Create successful payment transactions if they do not exist
    for user_info in vip_users_data:
        email = user_info["email"].lower().strip()
        user = db.users.find_one({"email": email})
        if not user:
            continue
            
        paid_at_dt = datetime.strptime(user_info["time"], "%d/%m/%Y %H:%M:%S")
        
        existing_tx = db.payment_transactions.find_one({
            "$or": [
                {"sepayTransactionId": user_info["sepay_id"]},
                {"paymentCode": user_info["desc"]}
            ]
        })
        
        tx_doc = {
            "userId": str(user["_id"]),
            "plan": "VIP_1M",
            "baseAmount": user_info["amount"],
            "discountAmount": 0,
            "finalAmount": user_info["amount"],
            "amount": user_info["amount"],
            "currency": "VND",
            "paymentCode": user_info["desc"],
            "paymentStatus": "SUCCESS",
            "sepayTransactionId": user_info["sepay_id"],
            "paidAt": paid_at_dt,
            "createdAt": paid_at_dt,
            "updatedAt": paid_at_dt
        }
        
        if existing_tx:
            db.payment_transactions.update_one(
                {"_id": existing_tx["_id"]},
                {"$set": tx_doc}
            )
            print(f"  [+] Updated transaction record for {email}.")
        else:
            db.payment_transactions.insert_one(tx_doc)
            print(f"  [+] Inserted new transaction record for {email}.")

    print("[*] STEP 4: Exporting VIP User spreadsheet...")
    export_filename = "vfit_vip_export.csv"
    headers = [
        "STT", "Tên khách hàng", "Email", "Số tiền", 
        "Mã GD SePay", "Mã tham chiếu", "Nội dung chuyển khoản", "Thời gian thanh toán"
    ]
    
    with open(export_filename, mode='w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        
        for u in vip_users_data:
            formatted_amount = f"{u['amount']:,} đ".replace(",", ".")
            writer.writerow([
                u["stt"],
                u["name"],
                u["email"],
                formatted_amount,
                u["sepay_id"],
                u["ref"],
                u["desc"],
                u["time"]
            ])
            
    print(f"[+] SUCCESS! File exported to: {export_filename}")
    
if __name__ == "__main__":
    main()
