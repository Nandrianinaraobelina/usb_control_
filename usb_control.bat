@echo off
title USB Lock Security
color 0A

fltmc >nul 2>&1
if errorlevel 1 (
    set "USB_CONTROL_SCRIPT=%~f0"
    powershell -NoProfile -Command "Start-Process -FilePath $env:USB_CONTROL_SCRIPT -Verb RunAs"
    if errorlevel 1 (
        echo.
        echo Administrator access was not granted.
        pause
        exit /b 1
    )
    exit /b
)

if not defined USB_CONTROL_PASSWORD (
    echo.
    echo USB_CONTROL_PASSWORD is not set. Configure it in your Windows user environment.
    pause
    exit /b 1
)

echo ==========================
echo      USB PORT CONTROL
echo ==========================
echo.
echo 1. Lock USB storage
echo 2. Unlock USB storage
echo.
set /p ACTION=Choose an option (1 or 2): 

if "%ACTION%"=="1" (
    set "USB_START=4"
    set "ACTION_NAME=MIHIDY"
) else if "%ACTION%"=="2" (
    set "USB_START=3"
    set "ACTION_NAME=MISOKATRA"
) else (
    echo.
    echo Invalid option.
    pause
    exit /b 1
)

echo.
set /p INPUT=Enter Password: 

if not "%INPUT%"=="%USB_CONTROL_PASSWORD%" (
    echo.
    echo Wrong Password!
    pause
    exit /b 1
)

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d %USB_START% /f >nul
if errorlevel 1 (
    echo.
    echo Failed to update USB storage settings.
    pause
    exit /b 1
)

echo.
echo USB Storage Devices %ACTION_NAME% Successfully!
echo.
pause
