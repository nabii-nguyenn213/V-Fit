import os
import json
import csv
import datetime

def parse_logs(raw_log_path, output_csv_path):
    print(f"Reading raw Caddy logs from: {raw_log_path}")
    
    logs = []
    if not os.path.exists(raw_log_path):
        print(f"Error: Raw log file not found at {raw_log_path}")
        return
        
    with open(raw_log_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
                
                # Extract request details
                req = data.get("request", {})
                uri = req.get("uri", "/")
                
                # Filter out asset files and API calls
                # Keep only page loads and main routes
                is_asset = any(ext in uri.lower() for ext in [
                    ".js", ".css", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".woff", ".ttf"
                ])
                is_api = "/api/" in uri.lower()
                
                if is_asset or is_api:
                    continue # Skip asset loads to reduce noise
                    
                ip = req.get("remote_ip", "127.0.0.1")
                ts = data.get("ts", 0) # Epoch timestamp
                
                # Convert epoch timestamp to GMT+7 local datetime
                dt = datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc)
                local_dt = dt + datetime.timedelta(hours=7)
                time_str = local_dt.strftime("%d/%m/%Y %H:%M:%S")
                
                # Extract OS and Browser from User-Agent
                headers = req.get("headers", {})
                ua_list = headers.get("User-Agent", [""])
                ua = ua_list[0] if ua_list else ""
                
                os_name = "Unknown OS"
                browser_name = "Unknown Browser"
                
                # Simple parser for OS
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
                    
                # Simple parser for Browser
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
                if uri == "/#/login":
                    action = "Xem trang đăng nhập"
                elif uri == "/":
                    action = "Landed / Tải trang chủ"
                elif "register" in uri:
                    action = "Đăng ký tài khoản"
                    
                logs.append({
                    "ip": ip,
                    "time": time_str,
                    "os": os_name,
                    "browser": browser_name,
                    "path": uri,
                    "action": action,
                    "dt_obj": local_dt # For sorting
                })
                
            except Exception as e:
                print(f"Error parsing line {line_num}: {e}")
                
    # Sort logs chronologically
    logs.sort(key=lambda x: x["dt_obj"])
    
    # Write to CSV
    os.makedirs(os.path.dirname(output_csv_path), exist_ok=True)
    with open(output_csv_path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(["STT", "Địa chỉ IP", "Thời gian truy cập", "Hệ điều hành", "Trình duyệt", "Đường dẫn", "Hành động"])
        for idx, l in enumerate(logs, 1):
            writer.writerow([
                idx,
                l["ip"],
                l["time"],
                l["os"],
                l["browser"],
                l["path"],
                l["action"]
            ])
            
    print(f"Successfully processed and written {len(logs)} page views to {output_csv_path}")

if __name__ == "__main__":
    # Paths relative to project root
    raw_log = os.path.join("scripts", "caddy_access.log")
    output_csv = os.path.join("docs", "vfit_visitors_log.csv")
    parse_logs(raw_log, output_csv)
