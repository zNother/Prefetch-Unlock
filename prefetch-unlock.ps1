$prefetchPath = "C:\Windows\Prefetch"
$sidUsers = "S-1-5-32-545"
$sidAdmins = "S-1-5-32-544"

Write-Host "--- DESBLOQUEANDO PREFETCH ---" -ForegroundColor Cyan

Write-Host "[1/3] Forzando activación en el Registro..." -ForegroundColor Yellow
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"

if (-not (Test-Path $regPath)) { 
    New-Item -Path $regPath -Force | Out-Null 
}

Set-ItemProperty -Path $regPath -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regPath -Name "EnableSuperfetch" -Value 3 -ErrorAction SilentlyContinue
Write-Host "✔ Políticas de optimización habilitadas." -ForegroundColor Green

Write-Host "[2/3] Restaurando acceso a la carpeta..." -ForegroundColor Yellow

try { 
    $process = Start-Process takeown -ArgumentList "/f $prefetchPath /r /d y" -NoNewWindow -PassThru -ErrorAction Stop
    $process.WaitForExit()
} catch { 
    $process = Start-Process takeown -ArgumentList "/f $prefetchPath /r /d s" -NoNewWindow -PassThru
    $process.WaitForExit()
}

icacls $prefetchPath /grant "*${sidAdmins}:(OI)(CI)(F)" /t /q
icacls $prefetchPath /grant "*${sidUsers}:(OI)(CI)(RX)" /t /q
Write-Host "✔ Permisos NTFS desbloqueados." -ForegroundColor Green

Write-Host "[3/3] Iniciando servicio SysMain..." -ForegroundColor Yellow
Set-Service -Name "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
Get-Service -Name "SysMain" | Start-Service -ErrorAction SilentlyContinue
Write-Host "✔ Servicio SysMain activado." -ForegroundColor Green

Write-Host "`n--- PROCESO COMPLETADO ---" -ForegroundColor Cyan
Write-Host "Prueba ahora Win + R > 'prefetch'." -ForegroundColor Green