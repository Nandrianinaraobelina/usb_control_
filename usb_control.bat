@echo off
setlocal
chcp 65001 >nul

set "USB_CONTROL_SCRIPT=%~dp0usb_control.ps1"
fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -Command "try { $arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ' + [char]34 + $env:USB_CONTROL_SCRIPT + [char]34; Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }"
    if errorlevel 1 (
        echo Impossible de lancer le controle USB avec les droits administrateur.
        echo La demande UAC a peut-etre ete annulee.
        pause
    )
    exit
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USB_CONTROL_SCRIPT%"
exit
