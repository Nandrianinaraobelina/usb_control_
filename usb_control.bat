@echo off
title Fifehezana ny USB
color 0A

rem Vérifie si le script est déjà exécuté en tant qu'administrateur.
fltmc >nul 2>&1
if errorlevel 1 (
    rem Relance le script avec l'élévation UAC si nécessaire.
    set "USB_CONTROL_SCRIPT=%~f0"
    powershell -NoProfile -Command "try { Start-Process -FilePath $env:USB_CONTROL_SCRIPT -Verb RunAs -ErrorAction Stop; exit 0 } catch { if ($_.Exception.NativeErrorCode -eq 1223) { exit 1223 }; exit 1 }"
    set "UAC_RESULT=%ERRORLEVEL%"
    if not "%UAC_RESULT%"=="0" (
        echo.
        if "%UAC_RESULT%"=="1223" (
            echo Nofoananao ny fangatahana alalana ho mpitantana.
        ) else (
            echo Tsy afaka nandefa ny script tamin'ny alalana ho mpitantana.
        )
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

rem Lit l'état actuel du service USBSTOR dans le registre.
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
    rem La valeur 4 désactive le service USBSTOR.
    set "USB_START=4"
    set "ACTION_NAME=MIHIDY"
) else if "%ACTION%"=="2" (
    rem La valeur 3 réactive le service USBSTOR.
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

rem Modifie la valeur USBSTOR dans le registre Windows.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d %USB_START% /f >nul
if errorlevel 1 (
    echo.
    echo Tsy nahomby ny fanoratana ny sanda ao amin'ny rejisitra Windows.
    pause
    exit /b 1
)

rem Vérifie que la valeur demandée a bien été écrite.
set "USB_VERIFY="
for /f "tokens=3" %%A in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start 2^>nul ^| findstr /i "Start"') do set "USB_VERIFY=%%A"
if /i not "%USB_VERIFY%"=="0x%USB_START%" (
    echo.
    echo Tsy voamarina ny fanovana. Sanda andrasana: 0x%USB_START%; sanda hita: %USB_VERIFY%.
    pause
    exit /b 1
)

echo.
echo Vita soa aman-tsara: %ACTION_NAME%  USB.
echo.
pause
