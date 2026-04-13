$prefetchPath = "C:\Windows\Prefetch"
$sidUsers = "S-1-5-32-545"
$sidAdmins = "S-1-5-32-544"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"

Write-Host "--- VERIFICACIÓN Y ACTIVACIÓN DE PREFETCH ---" -ForegroundColor Cyan

# --- 1. VERIFICACIÓN DEL ESTADO ACTUAL ---
$needsFix = $false

if (Test-Path $regPath) {
    $currentVal = (Get-ItemProperty -Path $regPath -Name "EnablePrefetcher" -ErrorAction SilentlyContinue).EnablePrefetcher
    
    Write-Host "[*] Valor actual de EnablePrefetcher: " -NoNewline
    switch ($currentVal) {
        0 { Write-Host "0 (Desactivado)" -ForegroundColor Red; $needsFix = $true }
        1 { Write-Host "1 (Solo Apps)" -ForegroundColor Yellow; $needsFix = $true }
        2 { Write-Host "2 (Solo Arranque)" -ForegroundColor Yellow; $needsFix = $true }
        3 { Write-Host "3 (Optimizado)" -ForegroundColor Green }
        Default { Write-Host "Desconocido/Inexistente"; $needsFix = $true }
    }
} else {
    Write-Host "[!] La clave de registro no existe." -ForegroundColor Red
    $needsFix = $true
}

# --- 2. ACCIÓN DE REPARACIÓN (Solo si es necesario o para asegurar) ---
if ($needsFix) {
    Write-Host "[1/3] Corrigiendo registro a modo 3 (Full)..." -ForegroundColor Yellow
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "EnablePrefetcher" -Value 3 -Force
    Set-ItemProperty -Path $regPath -Name "EnableSuperfetch" -Value 3 -Force
    Write-Host "✔ Registro actualizado correctamente." -ForegroundColor Green
} else {
    Write-Host "[1/3] El registro ya está optimizado. Asegurando valores..." -ForegroundColor Gray
    Set-ItemProperty -Path $regPath -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
}

# --- 3. PERMISOS DE CARPETA ---
Write-Host "[2/3] Desbloqueando carpeta Prefetch..." -ForegroundColor Yellow
try { 
    $process = Start-Process takeown -ArgumentList "/f $prefetchPath /r /d y" -NoNewWindow -PassThru -ErrorAction Stop
    $process.WaitForExit()
} catch { 
    $process = Start-Process takeown -ArgumentList "/f $prefetchPath /r /d s" -NoNewWindow -PassThru
    $process.WaitForExit()
}

icacls $prefetchPath /grant "*${sidAdmins}:(OI)(CI)(F)" /t /q
icacls $prefetchPath /grant "*${sidUsers}:(OI)(CI)(RX)" /t /q
Write-Host "✔ Permisos NTFS aplicados." -ForegroundColor Green

# --- 4. SERVICIO SYSMAIN ---
Write-Host "[3/3] Activando servicio SysMain..." -ForegroundColor Yellow
Set-Service -Name "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
$service = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if ($service.Status -ne 'Running') {
    Start-Service -Name "SysMain" -ErrorAction SilentlyContinue
}
Write-Host "✔ Servicio SysMain en ejecución." -ForegroundColor Green

Write-Host "`n--- TODO LISTO ---" -ForegroundColor Cyan
Write-Host "El sistema ahora tiene el Prefetch configurado en el modo recomendado (3)." -ForegroundColor White
Write-Host "Prueba ejecutar: Win + R > 'prefetch'" -ForegroundColor Green
