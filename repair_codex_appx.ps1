$ErrorActionPreference = 'Stop'

$manifest = 'C:\Program Files\WindowsApps\OpenAI.Codex_26.527.3686.0_x64__2p2nqsd0c76g0\AppxManifest.xml'
$log = 'D:\EXE_PRM\repair_codex_appx.log'

"[$(Get-Date -Format o)] Starting Codex AppX repair" | Out-File -FilePath $log -Encoding UTF8
Start-Sleep -Seconds 5

Get-Process -Name Codex -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

Add-AppxPackage -DisableDevelopmentMode -Register $manifest
"[$(Get-Date -Format o)] Re-registered $manifest" | Out-File -FilePath $log -Append -Encoding UTF8

Start-Sleep -Seconds 1
Start-Process explorer.exe 'shell:AppsFolder\OpenAI.Codex_2p2nqsd0c76g0!App'
"[$(Get-Date -Format o)] Relaunched Codex" | Out-File -FilePath $log -Append -Encoding UTF8
