@echo off
title USB Lock Security
color 0A

set "PASSWORD=Nandrianina26"

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
    set "ACTION_NAME=Locked"
) else if "%ACTION%"=="2" (
    set "USB_START=3"
    set "ACTION_NAME=Unlocked"
) else (
    echo.
    echo Invalid option.
    pause
    exit /b 1
)

echo.
set /p INPUT=Enter Password: 

if not "%INPUT%"=="%PASSWORD%" (
    echo.
    echo Wrong Password!
    pause
    exit /b 1
)

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d %USB_START% /f >nul
if errorlevel 1 (
    echo.
    echo Failed to update USB storage settings. Run this file as administrator.
    pause
    exit /b 1
)

echo.
echo USB Storage Devices %ACTION_NAME% Successfully!
echo.
pause
