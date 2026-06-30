# Script tự động sửa cấu hình SePay và khởi động lại Backend V-FIT trên VPS
# Hướng dẫn: Copy file này lên VPS, click chuột phải chọn "Run with PowerShell" hoặc chạy trong PowerShell của VPS.

$ErrorActionPreference = 'Stop'
$projectPath = "C:\V-Fit\VFIT_Backend"

Write-Host "=============================================" -ForegroundColor Green
Write-Host "Bắt đầu sửa cấu hình SePay trên VPS..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

if (-not (Test-Path $projectPath)) {
    Write-Error "Không tìm thấy thư mục code tại: $projectPath. Vui lòng kiểm tra lại đường dẫn."
    exit
}

cd $projectPath

# 1. Dừng tiến trình Java cũ
Write-Host "1. Đang dừng các tiến trình Java cũ..." -ForegroundColor Yellow
Stop-Process -Name java -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. Sửa file .env.production và .env
Write-Host "2. Đang sửa số tài khoản trong các file cấu hình..." -ForegroundColor Yellow
if (Test-Path .env.production) {
    (Get-Content .env.production) -replace '96247VFITexercise_catalogs', '96247VFIT' | Set-Content .env.production
    Write-Host "   -> Đã sửa file .env.production" -ForegroundColor Cyan
}
if (Test-Path .env) {
    (Get-Content .env) -replace '96247VFITexercise_catalogs', '96247VFIT' | Set-Content .env
    Write-Host "   -> Đã sửa file .env" -ForegroundColor Cyan
}

# 3. Load cấu hình mới vào môi trường
Write-Host "3. Đang tải cấu hình mới..." -ForegroundColor Yellow
Get-Content .env.production | Foreach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*)$') {
        $name = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

# 4. Khởi chạy lại Backend
Write-Host "4. Đang khởi chạy lại Backend Java..." -ForegroundColor Yellow
Start-Process java -ArgumentList "-jar target\vfit-backend-0.1.0.jar" -RedirectStandardOutput "jar-run.out" -RedirectStandardError "jar-run.err" -NoNewWindow

Start-Sleep -Seconds 3

# 5. Kiểm tra kết quả
if (Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue) {
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "THÀNH CÔNG! Backend đã chạy và đang lắng nghe ở cổng 8080." -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "LỖI: Không thể khởi chạy Backend. Vui lòng kiểm tra file jar-run.err để xem chi tiết." -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
}

pause
