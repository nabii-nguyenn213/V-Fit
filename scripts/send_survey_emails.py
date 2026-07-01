import os
import sys
import time
import argparse
import smtplib
import re
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pymongo import MongoClient

# Regular expression for simple email validation
EMAIL_REGEX = re.compile(r'^[\w\.-]+@[\w\.-]+\.\w+$')

def parse_arguments():
    parser = argparse.ArgumentParser(description="Tool gui email khao sat (Google Form) mot lan cho User V-Fit.")
    parser.add_argument(
        "--form-url",
        type=str,
        required=True,
        help="Duong dan Google Form khao sat (bat buoc)."
    )
    parser.add_argument(
        "--test-email",
        type=str,
        default=None,
        help="Chi gui thu nghiem den email nay (khong gui cho toan bo DB)."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Chay thu nghiem: Chi in ra danh sach email nhan tin tu DB chu khong gui that."
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Tu dong dong y gui email ma khong can hoi xac nhan (dung cho chay tu dong/SSH)."
    )
    parser.add_argument(
        "--env-path",
        type=str,
        default=None,
        help="Duong dan den file .env hoac .env.production."
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=1.5,
        help="Thoi gian cho giua cac lan gui email (giay) de tranh bi Gmail chan (mac dinh: 1.5 giay)."
    )
    return parser.parse_args()

def manual_load_dotenv(env_path):
    """
    Doc file .env thu cong de khong can phu thuoc vao thu vien python-dotenv
    """
    if not os.path.exists(env_path):
        return False
    
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, val = line.split("=", 1)
                # Remove quotes if present
                val_clean = val.strip()
                if (val_clean.startswith('"') and val_clean.endswith('"')) or \
                   (val_clean.startswith("'") and val_clean.endswith("'")):
                    val_clean = val_clean[1:-1]
                os.environ[key.strip()] = val_clean
    return True

def get_html_template(full_name, form_url):
    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Khảo sát ý kiến đóng góp V-Fit</title>
  <style>
    body {{
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: #f3f4f6;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }}
    .container {{
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }}
    .header {{
      background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
      padding: 30px 20px;
      text-align: center;
      color: #ffffff;
    }}
    .header h1 {{
      margin: 0;
      font-size: 28px;
      font-weight: 700;
      letter-spacing: -0.5px;
    }}
    .content {{
      padding: 40px 30px;
      color: #374151;
      line-height: 1.6;
    }}
    .content h2 {{
      font-size: 20px;
      color: #111827;
      margin-top: 0;
    }}
    .btn-container {{
      text-align: center;
      margin: 35px 0;
    }}
    .btn {{
      background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
      color: #ffffff !important;
      text-decoration: none;
      padding: 14px 30px;
      font-size: 16px;
      font-weight: bold;
      border-radius: 8px;
      display: inline-block;
      box-shadow: 0 4px 10px rgba(79, 70, 229, 0.3);
    }}
    .footer {{
      background-color: #f9fafb;
      padding: 24px 30px;
      text-align: center;
      font-size: 12px;
      color: #9ca3af;
      border-top: 1px solid #f3f4f6;
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>V-FIT</h1>
    </div>
    <div class="content">
      <h2>Xin chào {full_name},</h2>
      <p>Cảm ơn bạn đã lựa chọn và đồng hành cùng ứng dụng <strong>V-Fit</strong> trong hành trình cải thiện sức khỏe và vóc dáng.</p>
      <p>Để không ngừng nâng cao chất lượng dịch vụ và mang lại trải nghiệm tốt nhất, chúng tôi rất mong nhận được những phản hồi quý báu của bạn thông qua một bài khảo sát ngắn dưới đây (chỉ mất khoảng 2-3 phút).</p>
      <p>Mỗi ý kiến đóng góp của bạn đều là nguồn động lực và tư liệu quý giá giúp đội ngũ phát triển cải tiến V-Fit tốt hơn mỗi ngày.</p>
      
      <div class="btn-container">
        <a href="{form_url}" class="btn" target="_blank">Tham gia khảo sát V-Fit</a>
      </div>
      
      <p>Trân trọng,<br><strong>Đội ngũ phát triển V-Fit</strong></p>
    </div>
    <div class="footer">
      <p>Email này được gửi tự động đến người dùng đã đăng ký tài khoản trên ứng dụng V-Fit.</p>
      <p>&copy; 2026 V-Fit App. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
"""

def main():
    if hasattr(sys.stdout, 'reconfigure'):
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except:
            pass

    args = parse_arguments()

    # Xac dinh file env
    env_file = args.env_path
    if not env_file:
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        prod_path = os.path.join(base_dir, "VFIT_Backend", ".env.production")
        dev_path = os.path.join(base_dir, "VFIT_Backend", ".env")
        
        if os.path.exists(prod_path):
            env_file = prod_path
        elif os.path.exists(dev_path):
            env_file = dev_path
        else:
            print("[ERROR] Khong tim thay file .env hoac .env.production tu dong.")
            print("Vui long chi dinh duong dan bang tham so --env-path.")
            sys.exit(1)

    print(f"[*] Dang doc file cau hinh tai: {env_file}...")
    if not manual_load_dotenv(env_file):
        print(f"[ERROR] Khong the doc file env tai: {env_file}")
        sys.exit(1)

    # Lay cac cau hinh Mail va MongoDB
    db_uri = os.getenv("MONGODB_URI")
    smtp_host = os.getenv("SPRING_MAIL_HOST")
    smtp_port = os.getenv("SPRING_MAIL_PORT")
    smtp_user = os.getenv("SPRING_MAIL_USERNAME")
    smtp_pass = os.getenv("SPRING_MAIL_PASSWORD")

    if not db_uri:
        print("[ERROR] Khong tim thay cau hinh MONGODB_URI!")
        sys.exit(1)
    if not all([smtp_host, smtp_port, smtp_user, smtp_pass]):
        print("[ERROR] Thieu cau hinh email SMTP trong file env!")
        sys.exit(1)

    smtp_port = int(smtp_port)

    # 2. Ket noi database MongoDB
    print("[*] Dang ket noi den database MongoDB...")
    try:
        client = MongoClient(db_uri, serverSelectionTimeoutMS=5000)
        client.admin.command('ping')
        
        # Parse db_name tu URI
        db_name = "vfit"
        if '/' in db_uri:
            temp = db_uri.split('/')[-1]
            if '?' in temp:
                temp = temp.split('?')[0]
            if temp:
                db_name = temp
                
        db = client[db_name]
        users_collection = db["users"]
        print(f"[+] Ket noi MongoDB thanh cong! Database: {db_name}")
    except Exception as e:
        print(f"[ERROR] Khong the ket noi den MongoDB: {e}")
        sys.exit(1)

    # 3. Lay danh sach users de gui mail
    users_to_send = []
    
    if args.test_email:
        print(f"[*] Che do thu nghiem: Gui den duy nhat email '{args.test_email}'")
        if not EMAIL_REGEX.match(args.test_email):
            print(f"[ERROR] Email thu nghiem '{args.test_email}' khong hop le!")
            sys.exit(1)
        users_to_send = [{"email": args.test_email, "fullName": "Tester V-Fit"}]
    else:
        print("[*] Dang tai danh sach user tu collection 'users'...")
        try:
            all_users = users_collection.find({}, {"email": 1, "fullName": 1})
            for user in all_users:
                email = user.get("email")
                full_name = user.get("fullName") or "Ban"
                
                if email and EMAIL_REGEX.match(email):
                    if not email.endswith("@vfit.com"):
                        users_to_send.append({
                            "email": email,
                            "fullName": full_name
                        })
            print(f"[+] Tim thay tong cong {len(users_to_send)} users hop le trong database.")
        except Exception as e:
            print(f"[ERROR] Khong the doc danh sach users: {e}")
            sys.exit(1)

    if not users_to_send:
        print("[!] Khong tim thay user nao de gui email. Ket thuc.")
        sys.exit(0)

    # Neu chay Dry Run
    if args.dry_run:
        print("\n=== CHE DO DRY-RUN: DANH SACH EMAIL SE NHAN KHAO SAT ===")
        for idx, u in enumerate(users_to_send, 1):
            try:
                print(f"{idx}. {u['fullName']} <{u['email']}>")
            except:
                print(f"{idx}. User <{u['email']}>")
        print("=========================================================")
        print(f"[+] Tong cong: {len(users_to_send)} email(s). Khong co email nao duoc gui.")
        sys.exit(0)

    # 4. Kiem tra ket noi SMTP
    print(f"[*] Dang kiem tra ket noi SMTP den {smtp_host}:{smtp_port}...")
    try:
        server = smtplib.SMTP(smtp_host, smtp_port, timeout=10)
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.quit()
        print("[+] Ket noi va dang nhap SMTP thanh cong!")
    except Exception as e:
        print(f"[ERROR] Khong the ket noi den SMTP Server: {e}")
        sys.exit(1)

    # 5. Xac nhan gui thuc te
    if not args.test_email and not args.yes:
        try:
            confirm = input(f"[WARNING] Ban chuan bi gui email thuc te den {len(users_to_send)} users. Xac nhan gui? (y/N): ")
        except Exception as e:
            print(f"[WARNING] Khong the doc input tu terminal ({e}).")
            print("[HINT] Vui long chay voi tham so --yes de tu dong xac nhan gui.")
            sys.exit(1)
        
        if confirm.strip().lower() != 'y':
            print("[-] Da huy thao tac gui email.")
            sys.exit(0)

    # 6. Bat dau gui email
    success_count = 0
    failed_count = 0
    
    print("\n[*] Bat dau qua trinh gui email...")
    
    try:
        server = smtplib.SMTP(smtp_host, smtp_port, timeout=15)
        server.starttls()
        server.login(smtp_user, smtp_pass)
    except Exception as e:
        print(f"[ERROR] Loi khi ket noi lai SMTP: {e}")
        sys.exit(1)

    log_filename = f"email_survey_log_{int(time.time())}.txt"
    log_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), log_filename)
    
    with open(log_path, "w", encoding="utf-8") as log_file:
        log_file.write(f"BAO CAO GUI EMAIL KHAO SAT V-FIT\n")
        log_file.write(f"Thoi gian: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        log_file.write(f"Google Form URL: {args.form_url}\n")
        log_file.write(f"--------------------------------------------------\n")

        for idx, user in enumerate(users_to_send, 1):
            email = user["email"]
            name = user["fullName"]
            
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "[V-Fit] Khao sat y kien dong gop phat trien ung dung"
            msg['From'] = f"V-Fit Team <{smtp_user}>"
            msg['To'] = email
            
            text_content = f"Xin chào {name},\n\nCảm ơn bạn đã lựa chọn và đồng hành cùng V-Fit.\n\nHãy dành ra 2-3 phút tham gia bài khảo sát ngắn tại link sau để giúp chúng tôi hoàn thiện ứng dụng tốt hơn nhé:\n{args.form_url}\n\nTrân trọng,\nĐội ngũ phát triển V-Fit"
            html_content = get_html_template(name, args.form_url)
            
            msg.attach(MIMEText(text_content, 'plain', 'utf-8'))
            msg.attach(MIMEText(html_content, 'html', 'utf-8'))
            
            try:
                server.sendmail(smtp_user, [email], msg.as_string())
                success_count += 1
                status_str = f"[SUCCESS] [{idx}/{len(users_to_send)}] Da gui den: {email}"
                print(status_str)
                log_file.write(f"{status_str} (Name: {name})\n")
            except Exception as e:
                failed_count += 1
                status_str = f"[FAILED] [{idx}/{len(users_to_send)}] Loi gui den {email}: {e}"
                print(status_str)
                log_file.write(f"{status_str}\n")
                
                try:
                    server.quit()
                except:
                    pass
                
                print("[*] Thu ket noi lai SMTP Server...")
                try:
                    server = smtplib.SMTP(smtp_host, smtp_port, timeout=15)
                    server.starttls()
                    server.login(smtp_user, smtp_pass)
                    print("[+] Reconnect thanh cong!")
                except Exception as reconnect_err:
                    print(f"[ERROR] Khong the ket noi lai SMTP: {reconnect_err}. Dung qua trinh gui.")
                    log_file.write(f"[CRITICAL] Dung gui do mat ket noi SMTP: {reconnect_err}\n")
                    break
            
            time.sleep(args.delay)

        try:
            server.quit()
        except:
            pass

        summary_str = f"\n=== KET QUA ===\n- Success: {success_count}\n- Failed: {failed_count}\n- Total: {len(users_to_send)}\n- Log file: {log_path}\n============="
        print(summary_str)
        log_file.write(summary_str + "\n")

if __name__ == "__main__":
    main()
