@echo off
title Contrôle du stockage USB
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
            echo Vous avez annulé la demande d'autorisation administrateur.
        ) else (
            echo Impossible de relancer le script avec les droits administrateur.
        )
        pause
        exit /b 1
    )
    exit /b
)

if not defined USB_CONTROL_PASSWORD (
    echo.
    echo La variable USB_CONTROL_PASSWORD n'est pas définie dans votre environnement Windows.
    pause
    exit /b 1
)

set "USB_CONTROL_SCRIPT_DIR=%~dp0"

rem Lit l'état actuel du service USBSTOR dans le registre.
set "USB_CURRENT="
for /f "tokens=3" %%A in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start 2^>nul ^| findstr /i "Start"') do set "USB_CURRENT=%%A"

rem Compte les disques USB actuellement connectés.
set "USB_CONNECTED_COUNT="
for /f %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_DiskDrive | Where-Object InterfaceType -eq USB | Measure-Object).Count" 2^>nul') do set "USB_CONNECTED_COUNT=%%A"

echo ==========================
echo      CONTRÔLE DU STOCKAGE USB
echo ==========================
echo.
if /i "%USB_CURRENT%"=="0x4" (
    echo État actuel : VERROUILLÉ
) else if /i "%USB_CURRENT%"=="0x3" (
    echo État actuel : DÉVERROUILLÉ
) else if defined USB_CURRENT (
    echo État actuel : INCONNU ^(%USB_CURRENT%^)
) else (
    echo État actuel : INDISPONIBLE
)
if defined USB_CONNECTED_COUNT (
    if %USB_CONNECTED_COUNT% GTR 0 (
        echo Attention : des disques de stockage USB sont actuellement connectés.
        echo Nombre détecté : %USB_CONNECTED_COUNT%.
        echo Ils peuvent rester accessibles après le verrouillage.
        echo Déconnectez-les puis reconnectez-les après l'opération.
    ) else (
        echo Aucun disque USB connecté détecté.
    )
) else (
    echo Impossible de vérifier les disques USB connectés.
)
echo.
echo 1. Verrouiller le stockage USB
echo 2. Déverrouiller le stockage USB
echo 3. Quitter
echo.
set /p ACTION=Choisissez une option (1, 2 ou 3) :

if "%ACTION%"=="3" exit /b 0
if "%ACTION%"=="1" (
    rem La valeur 4 désactive le service USBSTOR.
    set "USB_START=4"
    set "ACTION_NAME=VERROUILLÉ"
) else if "%ACTION%"=="2" (
    rem La valeur 3 réactive le service USBSTOR.
    set "USB_START=3"
    set "ACTION_NAME=DÉVERROUILLÉ"
) else (
    echo.
    echo Option invalide.
    call :LOG "INCONNUE" "OPTION_INVALIDE"
    pause
    exit /b 1
)

echo.
powershell -NoProfile -Command "$secure = Read-Host 'Saisissez le mot de passe' -AsSecureString; $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure); try { $entered = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer); if ($entered -cne $env:USB_CONTROL_PASSWORD) { exit 1 } } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }"
if errorlevel 1 (
    echo.
    echo Mot de passe incorrect.
    call :LOG "%ACTION_NAME%" "MOT_DE_PASSE_INCORRECT"
    pause
    exit /b 1
)

echo.
set /p CONFIRM=Confirmez-vous la modification ? Tapez OUI :
if /i not "%CONFIRM%"=="OUI" (
    echo.
    echo Modification annulée.
    call :LOG "%ACTION_NAME%" "ANNULATION"
    pause
    exit /b 0
)

rem Modifie la valeur USBSTOR dans le registre Windows.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d %USB_START% /f >nul
if errorlevel 1 (
    echo.
    echo Échec de l'écriture dans le Registre Windows.
    call :LOG "%ACTION_NAME%" "ECHEC_ECRITURE_REGISTRE"
    pause
    exit /b 1
)

rem Vérifie que la valeur demandée a bien été écrite.
set "USB_VERIFY="
for /f "tokens=3" %%A in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start 2^>nul ^| findstr /i "Start"') do set "USB_VERIFY=%%A"
if /i not "%USB_VERIFY%"=="0x%USB_START%" (
    echo.
    echo Vérification échouée. Valeur attendue : 0x%USB_START% ; valeur lue : %USB_VERIFY%.
    call :LOG "%ACTION_NAME%" "ECHEC_VERIFICATION"
    pause
    exit /b 1
)

echo.
echo Stockage USB %ACTION_NAME% avec succès.
call :LOG "%ACTION_NAME%" "SUCCES"
echo.
pause
exit /b 0

:LOG
set "USB_LOG_ACTION=%~1"
set "USB_LOG_RESULT=%~2"
powershell -NoProfile -Command "$line = '{0}; action={1}; resultat={2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $env:USB_LOG_ACTION, $env:USB_LOG_RESULT; Add-Content -LiteralPath (Join-Path $env:USB_CONTROL_SCRIPT_DIR 'usb_control.log') -Value $line -Encoding utf8"
if errorlevel 1 (
    echo Impossible d'ecrire dans le journal usb_control.log.
    exit /b 1
)
exit /b 0
