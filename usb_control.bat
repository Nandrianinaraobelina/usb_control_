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

rem Vakio ny sata USBSTOR ankehitriny ao amin'ny rejisitra.
set "USB_CURRENT="
for /f "tokens=3" %%A in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start 2^>nul ^| findstr /i "Start"') do set "USB_CURRENT=%%A"

echo ==========================
echo      FIFEHEZANA NY USB
echo ==========================
echo.
if /i "%USB_CURRENT%"=="0x4" (
    echo Sata ankehitriny: MIHIDY
) else if /i "%USB_CURRENT%"=="0x3" (
    echo Sata ankehitriny: MISOKATRA
) else if defined USB_CURRENT (
    echo Sata ankehitriny: TSY FANTATRA ^(%USB_CURRENT%^)
) else (
    echo Sata ankehitriny: TSY AZO
)
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
powershell -NoProfile -Command "$secure = Read-Host 'Ampidiro ny tenimiafina' -AsSecureString; $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure); try { $entered = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer); if ($entered -cne $env:USB_CONTROL_PASSWORD) { exit 1 } } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }"
if errorlevel 1 (
    echo.
    echo Diso ny tenimiafina!
    pause
    exit /b 1
)

echo.
set /p CONFIRM=Hanohy ve? Soraty ENY hanamafisana:
if /i not "%CONFIRM%"=="ENY" (
    echo.
    echo Nofoanana ny fanovana.
    pause
    exit /b 0
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
