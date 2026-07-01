import os
import json
import csv
import datetime

def parse_logs(raw_log_path, output_csv_path):
    print(f"Reading raw Caddy logs from: {raw_log_path}")
    print(f"Target output CSV: {output_csv_path}")
    
    existing_records = []
    seen_keys = set() # Set of (ip, time) to avoid duplicates
    
    # 1. Load existing records if CSV already exists
    if os.path.exists(output_csv_path):
        try:
            with open(output_csv_path, "r", encoding="utf-8-sig") as f:
                reader = csv.reader(f)
                header = next(reader, None)
                if header:
                    for row in reader:
                        if len(row) >= 6:
                            # row: [STT, IP, Time, OS, Browser, Action]
                            ip = row[1].strip()
                            time_str = row[2].strip()
                            os_name = row[3].strip()
                            browser = row[4].strip()
                            action = row[5].strip()
                            
                            # Parse dt_obj for sorting
                            try:
                                dt_obj = datetime.datetime.strptime(time_str, "%d/%m/%Y %H:%M:%S")
                            except ValueError:
                                dt_obj = datetime.datetime.min
                                
                            seen_keys.add((ip, time_str))
                            existing_records.append({
                                "ip": ip,
                                "time": time_str,
                                "os": os_name,
                                "browser": browser,
                                "action": action,
                                "dt_obj": dt_obj
                            })
            print(f"Loaded {len(existing_records)} existing records from CSV.")
        except Exception as e:
            print(f"Warning: Could not load existing CSV: {e}")
            
    # 2. Parse new raw Caddy logs
    new_count = 0
    if os.path.exists(raw_log_path):
        with open(raw_log_path, "r", encoding="utf-8") as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)
                    req = data.get("request", {})
                    uri = req.get("uri", "/")
                    
                    # Filter out asset files and API calls
                    is_asset = any(ext in uri.lower() for ext in [
                        ".js", ".css", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".woff", ".ttf"
                    ])
                    is_api = "/api/" in uri.lower()
                    
                    if is_asset or is_api:
                        continue
                        
                    ip = req.get("remote_ip", "127.0.0.1")
                    ts = data.get("ts", 0) # Epoch timestamp
                    
                    # Convert to local GMT+7 datetime (offset-naive for sorting comparison)
                    dt = datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc)
                    local_dt = (dt + datetime.timedelta(hours=7)).replace(tzinfo=None)
                    time_str = local_dt.strftime("%d/%m/%Y %H:%M:%S")
                    
                    # Check if already seen
                    if (ip, time_str) in seen_keys:
                        continue
                        
                    # Extract OS & Browser from User-Agent
                    headers = req.get("headers", {})
                    ua_list = headers.get("User-Agent", [""])
                    ua = ua_list[0] if ua_list else ""
                    
                    os_name = "Unknown OS"
                    browser_name = "Unknown Browser"
                    
                    if "iPhone" in ua or "iPad" in ua:
                        os_name = "iOS"
                    elif "Android" in ua:
                        os_name = "Android"
                    elif "Windows" in ua:
                        os_name = "Windows"
                    elif "Macintosh" in ua:
                        os_name = "macOS"
                    elif "Linux" in ua:
                        os_name = "Linux"
                        
                    if "Chrome" in ua and "Mobile" in ua:
                        browser_name = "Chrome (Mobile)"
                    elif "Chrome" in ua:
                        browser_name = "Chrome (Desktop)"
                    elif "Safari" in ua and "Mobile" in ua:
                        browser_name = "Safari (Mobile)"
                    elif "Safari" in ua:
                        browser_name = "Safari (Desktop)"
                    elif "Firefox" in ua:
                        browser_name = "Firefox"
                    elif "Edge" in ua:
                        browser_name = "Edge"
                        
                    # Determine action based on URI
                    action = "Xem giới thiệu"
                    if uri == "/#/register":
                        action = "Đăng ký tài khoản"
                    elif uri == "/#/login":
                        if ip == "113.161.163.92" and local_dt.date() == datetime.date(2026, 5, 26):
                            action = "Xem trang đăng nhập (Test IP)"
                        else:
                            action = "Xem trang đăng nhập"
                            
                    seen_keys.add((ip, time_str))
                    existing_records.append({
                        "ip": ip,
                        "time": time_str,
                        "os": os_name,
                        "browser": browser_name,
                        "action": action,
                        "dt_obj": local_dt
                    })
                    new_count += 1
                    
                except Exception as e:
                    pass # Ignore malformed log lines silently
    else:
        print(f"Notice: Caddy log file not found or empty: {raw_log_path}")
        
    print(f"Processed {new_count} new unique visits from Caddy logs.")
    
    # 3. Sort chronologically
    existing_records.sort(key=lambda x: x["dt_obj"])
    
    # 4. Write back to CSV
    os.makedirs(os.path.dirname(output_csv_path), exist_ok=True)
    try:
        with open(output_csv_path, "w", newline="", encoding="utf-8-sig") as f:
            writer = csv.writer(f)
            writer.writerow(["STT", "Địa chỉ IP", "Thời gian truy cập", "Hệ điều hành", "Trình duyệt", "Hành động"])
            for idx, l in enumerate(existing_records, 1):
                writer.writerow([
                    idx,
                    l["ip"],
                    l["time"],
                    l["os"],
                    l["browser"],
                    l["action"]
                ])
        print(f"Successfully wrote {len(existing_records)} total records to {output_csv_path}")
    except PermissionError:
        print(f"Error: Permission denied writing to {output_csv_path}. Please close the file if it is open.")

if __name__ == "__main__":
    # Paths relative to project root
    raw_log = os.path.join("scripts", "caddy_access.log")
    output_csv = os.path.join("docs", "vfit_visitors_log.csv")
    parse_logs(raw_log, output_csv)
