@echo off
title Fifehezana ny USB
color 0A

rem Jereo raha efa mandeha amin'ny maha-mpitantana ity rakitra ity.
fltmc >nul 2>&1
if errorlevel 1 (
    rem Avereno alefa amin'ny alalan'ny UAC raha mbola tsy manana alalana.
    set "USB_CONTROL_SCRIPT=%~f0"
    powershell -NoProfile -Command "Start-Process -FilePath $env:USB_CONTROL_SCRIPT -Verb RunAs"
    if errorlevel 1 (
        echo.
        echo Tsy nahazo alalana ho mpitantana.
        pause
        exit /b 1
    )
    exit /b
)

if not defined USB_CONTROL_PASSWORD (
    echo.
    echo Tsy voafaritra ny USB_CONTROL_PASSWORD. Apetraho ao amin'ny environment an'ny Windows-nao.
    pause
    exit /b 1
)

echo ==========================
echo      FIFEHEZANA NY USB
echo ==========================
echo.
echo 1. RAHA HIDINA ILAY USB
echo 2. RAHA HO SOKAFANA ILAY USB
echo.
set /p ACTION=Misafidiana (1 na 2):

if "%ACTION%"=="1" (
    rem Ny sanda 4 dia manakana ny USBSTOR.
    set "USB_START=4"
    set "ACTION_NAME=MIHIDY"
) else if "%ACTION%"=="2" (
    rem Ny sanda 3 dia mamerina ny USBSTOR.
    set "USB_START=3"
    set "ACTION_NAME=MISOKATRA"
) else (
    echo.
    echo Safidy tsy mety.
    pause
    exit /b 1
)

echo.
set /p INPUT=Ampidiro ny tenimiafina:

if not "%INPUT%"=="%USB_CONTROL_PASSWORD%" (
    echo.
    echo Diso ny tenimiafina!
    pause
    exit /b 1
)

rem Ovay ny fikirakirana USBSTOR ao amin'ny rejisitra Windows.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d %USB_START% /f >nul
if errorlevel 1 (
    echo.
    echo Pups .. hamarino tsara lou ee.
    pause
    exit /b 1
)

echo.
echo Vita soa aman-tsara: %ACTION_NAME%  USB.
echo.
pause
