$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$script:RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR'
$script:RegistryKey = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR'
$script:ScriptDirectory = $PSScriptRoot
$script:LogPath = Join-Path $PSScriptRoot 'usb_control.log'
$script:BackupPath = Join-Path $PSScriptRoot 'usb_control.previous'
$script:Password = [Environment]::GetEnvironmentVariable('USB_CONTROL_PASSWORD')
$script:MainForm = $null
$script:BackgroundImage = $null
$script:StateLabel = $null
$script:DiskWarningLabel = $null
$script:MessageLabel = $null

function Write-OperationLog {
    param(
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Result
    )

    $entry = '{0}; action={1}; resultat={2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Action, $Result
    Add-Content -LiteralPath $script:LogPath -Value $entry -Encoding UTF8 -ErrorAction Stop
}

function Get-UsbState {
    $value = [uint32](Get-ItemPropertyValue -LiteralPath $script:RegistryPath -Name Start -ErrorAction Stop)
    [pscustomobject]@{
        Value = $value
        Hex = '0x{0:X}' -f $value
        Text = switch ($value) {
            4 { 'VERROUILLÉ' }
            3 { 'DÉVERROUILLÉ' }
            default { 'ÉTAT INCONNU' }
        }
    }
}

function Get-ConnectedUsbDiskCount {
    try {
        return [int](@(Get-CimInstance -ClassName Win32_DiskDrive -Filter "InterfaceType = 'USB'" -ErrorAction Stop).Count)
    } catch {
        return $null
    }
}

function Update-Status {
    try {
        $state = Get-UsbState
        $script:StateLabel.Text = "État actuel : $($state.Text)  ($($state.Hex))"
        $script:StateLabel.ForeColor = if ($state.Value -eq 4) {
            [Drawing.Color]::FromArgb(255, 190, 92)
        } elseif ($state.Value -eq 3) {
            [Drawing.Color]::FromArgb(91, 220, 160)
        } else {
            [Drawing.Color]::FromArgb(255, 210, 100)
        }
    } catch {
        $state = $null
        $script:StateLabel.Text = 'État actuel : indisponible'
        $script:StateLabel.ForeColor = [Drawing.Color]::Tomato
    }

    $diskCount = Get-ConnectedUsbDiskCount
    if ($null -eq $diskCount) {
        $script:DiskWarningLabel.Text = 'Détection des disques USB indisponible.'
        $script:DiskWarningLabel.ForeColor = [Drawing.Color]::LightGray
    } elseif ($diskCount -gt 0) {
        $script:DiskWarningLabel.Text = "Attention : $diskCount disque(s) USB connecté(s). Ils peuvent rester accessibles après le verrouillage."
        $script:DiskWarningLabel.ForeColor = [Drawing.Color]::FromArgb(255, 190, 92)
    } else {
        $script:DiskWarningLabel.Text = 'Aucun disque USB connecté détecté.'
        $script:DiskWarningLabel.ForeColor = [Drawing.Color]::FromArgb(91, 220, 160)
    }

    return $state
}

function Show-Message {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string]$Caption = 'Contrôle du stockage USB',
        [Windows.Forms.MessageBoxIcon]$Icon = [Windows.Forms.MessageBoxIcon]::Information
    )

    [void][Windows.Forms.MessageBox]::Show(
        $script:MainForm,
        $Text,
        $Caption,
        [Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    )
}

function Read-UsbPassword {
    $dialog = New-Object Windows.Forms.Form
    $dialog.Text = 'Authentification'
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.ClientSize = New-Object Drawing.Size(440, 165)
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = [Drawing.Color]::FromArgb(25, 34, 49)
    $dialog.ForeColor = [Drawing.Color]::White
    $dialog.Font = New-Object Drawing.Font('Segoe UI', 11)

    $label = New-Object Windows.Forms.Label
    $label.Text = 'Saisissez le mot de passe configuré :'
    $label.AutoSize = $true
    $label.Location = New-Object Drawing.Point(20, 20)

    $passwordInput = New-Object Windows.Forms.TextBox
    $passwordInput.Location = New-Object Drawing.Point(20, 55)
    $passwordInput.Size = New-Object Drawing.Size(395, 32)
    $passwordInput.Font = New-Object Drawing.Font('Segoe UI', 13)
    $passwordInput.UseSystemPasswordChar = $true

    $ok = New-Object Windows.Forms.Button
    $ok.Text = 'Valider'
    $ok.Location = New-Object Drawing.Point(220, 105)
    $ok.Size = New-Object Drawing.Size(95, 38)
    $ok.DialogResult = [Windows.Forms.DialogResult]::OK

    $cancel = New-Object Windows.Forms.Button
    $cancel.Text = 'Annuler'
    $cancel.Location = New-Object Drawing.Point(320, 105)
    $cancel.Size = New-Object Drawing.Size(95, 38)
    $cancel.DialogResult = [Windows.Forms.DialogResult]::Cancel

    $dialog.Controls.AddRange(@($label, $passwordInput, $ok, $cancel))
    $dialog.AcceptButton = $ok
    $dialog.CancelButton = $cancel
    $dialog.Add_Shown({ $passwordInput.Focus() })

    if ($dialog.ShowDialog($script:MainForm) -eq [Windows.Forms.DialogResult]::OK) {
        return $passwordInput.Text
    }

    return $null
}

function Invoke-UsbAction {
    param(
        [Parameter(Mandatory)][ValidateSet('Lock', 'Unlock', 'Restore')][string]$Action
    )

    $state = Update-Status
    if ($null -eq $state) {
        Show-Message -Text 'Impossible de lire la valeur USBSTOR dans le Registre.' -Icon Error
        return
    }

    $actionName = switch ($Action) {
        Lock { 'VERROUILLAGE' }
        Unlock { 'DÉVERROUILLAGE' }
        Restore { 'RESTAURATION' }
    }

    if ($Action -eq 'Restore') {
        if (-not (Test-Path -LiteralPath $script:BackupPath -PathType Leaf)) {
            Show-Message -Text 'Aucune valeur initiale sauvegardée. La restauration est impossible.' -Icon Warning
            try { Write-OperationLog -Action $actionName -Result 'VALEUR_INITIALE_ABSENTE' } catch {
                Show-Message -Text "Impossible d'écrire dans le journal : $($_.Exception.Message)" -Icon Error
            }
            return
        }

        try {
            $backupText = (Get-Content -LiteralPath $script:BackupPath -Raw -ErrorAction Stop).Trim()
            $savedValue = [uint32]0
            if (-not [uint32]::TryParse($backupText, [ref]$savedValue)) {
                throw "Le contenu de la sauvegarde n’est pas un entier DWORD valide."
            }
        } catch {
            Show-Message -Text "La sauvegarde est invalide : $($_.Exception.Message)" -Icon Error
            try { Write-OperationLog -Action $actionName -Result 'SAUVEGARDE_INVALIDE' } catch {}
            return
        }
    } elseif ($Action -eq 'Lock') {
        $savedValue = [uint32]4
    } else {
        $savedValue = [uint32]3
    }

    $expectedHex = '0x{0:X}' -f $savedValue
    if ($state.Value -eq $savedValue) {
        Show-Message -Text "Le stockage USB est déjà dans l’état demandé. Aucune modification du Registre n’est nécessaire."
        try { Write-OperationLog -Action $actionName -Result 'DEJA_CONFIGURE' } catch {
            Show-Message -Text "L’état USB est inchangé, mais le journal n’a pas pu être écrit : $($_.Exception.Message)" -Icon Error
        }
        return
    }

    if ($Action -eq 'Lock') {
        $diskCount = Get-ConnectedUsbDiskCount
        if ($null -eq $diskCount) {
            $choice = [Windows.Forms.MessageBox]::Show(
                $script:MainForm,
                "La présence de disques USB n’a pas pu être vérifiée. Voulez-vous quand même continuer ?",
                'Vérification USB indisponible',
                [Windows.Forms.MessageBoxButtons]::YesNo,
                [Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($choice -ne [Windows.Forms.DialogResult]::Yes) {
                try { Write-OperationLog -Action $actionName -Result 'ANNULATION_DETECTION_INDISPONIBLE' } catch {}
                return
            }
        } elseif ($diskCount -gt 0) {
            $choice = [Windows.Forms.MessageBox]::Show(
                $script:MainForm,
                "$diskCount disque(s) USB sont connecté(s) et peuvent rester accessibles après le verrouillage.`r`n`r`nDéconnectez-les avant de continuer si vous souhaitez bloquer leur accès. Continuer malgré tout ?",
                'Disque(s) USB connecté(s)',
                [Windows.Forms.MessageBoxButtons]::YesNo,
                [Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($choice -ne [Windows.Forms.DialogResult]::Yes) {
                try { Write-OperationLog -Action $actionName -Result 'ANNULATION_DISQUE_CONNECTE' } catch {}
                return
            }
        }
    }

    $enteredPassword = Read-UsbPassword
    if ($null -eq $enteredPassword) {
        try { Write-OperationLog -Action $actionName -Result 'ANNULATION_AUTHENTIFICATION' } catch {}
        return
    }
    if ($enteredPassword -cne $script:Password) {
        Show-Message -Text 'Mot de passe incorrect.' -Icon Error
        try { Write-OperationLog -Action $actionName -Result 'MOT_DE_PASSE_INCORRECT' } catch {
            Show-Message -Text "Impossible d’écrire dans le journal : $($_.Exception.Message)" -Icon Error
        }
        return
    }

    $summary = "État actuel : $($state.Text) ($($state.Hex))`r`nAction demandée : $actionName`r`nValeur Start demandée : $expectedHex`r`n`r`nConfirmer cette modification du Registre ?"
    $confirmation = [Windows.Forms.MessageBox]::Show(
        $script:MainForm,
        $summary,
        'Confirmer la modification',
        [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirmation -ne [Windows.Forms.DialogResult]::Yes) {
        try { Write-OperationLog -Action $actionName -Result 'ANNULATION' } catch {}
        return
    }

    if ($Action -ne 'Restore' -and -not (Test-Path -LiteralPath $script:BackupPath -PathType Leaf)) {
        try {
            $state.Value.ToString() | Set-Content -LiteralPath $script:BackupPath -Encoding ASCII -ErrorAction Stop
            (Get-Item -LiteralPath $script:BackupPath -ErrorAction Stop).IsReadOnly = $true
        } catch {
            Show-Message -Text "Impossible de créer et protéger la sauvegarde initiale : $($_.Exception.Message)" -Icon Error
            try { Write-OperationLog -Action $actionName -Result 'ECHEC_SAUVEGARDE' } catch {}
            return
        }
    }

    try {
        Set-ItemProperty -LiteralPath $script:RegistryPath -Name Start -Value $savedValue -ErrorAction Stop
        $verifiedState = Get-UsbState
        if ($verifiedState.Value -ne $savedValue) {
            throw "Valeur attendue : $expectedHex ; valeur lue : $($verifiedState.Hex)."
        }
    } catch {
        Show-Message -Text "Échec de la modification ou de sa vérification : $($_.Exception.Message)" -Icon Error
        try { Write-OperationLog -Action $actionName -Result 'ECHEC_VERIFICATION' } catch {}
        [void](Update-Status)
        return
    }

    try {
        Write-OperationLog -Action $actionName -Result 'SUCCES'
        $script:MessageLabel.Text = "Opération réussie : $actionName."
        $script:MessageLabel.ForeColor = [Drawing.Color]::FromArgb(91, 220, 160)
    } catch {
        Show-Message -Text "La modification a réussi, mais le journal n’a pas pu être écrit : $($_.Exception.Message)" -Icon Error
    }

    [void](Update-Status)
}

function New-ActionButton {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][Drawing.Color]$BackColor,
        [Parameter(Mandatory)][scriptblock]$OnClick
    )

    $button = New-Object Windows.Forms.Button
    $button.Text = $Text
    $button.Dock = [Windows.Forms.DockStyle]::Fill
    $button.Height = 58
    $button.Margin = New-Object Windows.Forms.Padding(8)
    $button.FlatStyle = [Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $BackColor
    $button.ForeColor = [Drawing.Color]::White
    $button.Font = New-Object Drawing.Font('Segoe UI Semibold', 12)
    $button.Cursor = [Windows.Forms.Cursors]::Hand
    $button.Add_Click($OnClick)
    return $button
}

if ([string]::IsNullOrWhiteSpace($script:Password)) {
    [void][Windows.Forms.MessageBox]::Show(
        "La variable d’environnement USB_CONTROL_PASSWORD n’est pas définie pour votre compte Windows.",
        'Configuration requise',
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

$script:MainForm = New-Object Windows.Forms.Form
$script:MainForm.Text = 'Contrôle du stockage USB'
$script:MainForm.StartPosition = 'CenterScreen'
$script:MainForm.ClientSize = New-Object Drawing.Size(850, 660)
$script:MainForm.MinimumSize = New-Object Drawing.Size(760, 620)
$script:MainForm.BackColor = [Drawing.Color]::FromArgb(17, 24, 39)
$script:BackgroundImage = [Drawing.Image]::FromFile((Join-Path $PSScriptRoot 'usb-control-background.jpg'))
$script:MainForm.BackgroundImage = $script:BackgroundImage
$script:MainForm.BackgroundImageLayout = [Windows.Forms.ImageLayout]::Zoom
$script:MainForm.ForeColor = [Drawing.Color]::White
$script:MainForm.Font = New-Object Drawing.Font('Segoe UI', 12)
$script:MainForm.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi

$layout = New-Object Windows.Forms.TableLayoutPanel
$layout.Dock = [Windows.Forms.DockStyle]::Fill
$layout.BackColor = [Drawing.Color]::Transparent
$layout.Padding = New-Object Windows.Forms.Padding(28, 22, 28, 22)
$layout.ColumnCount = 1
$layout.RowCount = 7
$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent, 100)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 62)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 72)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 84)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent, 100)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 64)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 54)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 36)))

$header = New-Object Windows.Forms.Label
$header.Text = 'CONTRÔLE DU STOCKAGE USB'
$header.Dock = [Windows.Forms.DockStyle]::Fill
$header.BackColor = [Drawing.Color]::Transparent
$header.Font = New-Object Drawing.Font('Segoe UI Semibold', 21)
$header.ForeColor = [Drawing.Color]::FromArgb(115, 170, 255)
$header.TextAlign = [Drawing.ContentAlignment]::MiddleLeft

$script:StateLabel = New-Object Windows.Forms.Label
$script:StateLabel.Dock = [Windows.Forms.DockStyle]::Fill
$script:StateLabel.BackColor = [Drawing.Color]::Transparent
$script:StateLabel.Font = New-Object Drawing.Font('Segoe UI Semibold', 16)
$script:StateLabel.TextAlign = [Drawing.ContentAlignment]::MiddleLeft

$script:DiskWarningLabel = New-Object Windows.Forms.Label
$script:DiskWarningLabel.Dock = [Windows.Forms.DockStyle]::Fill
$script:DiskWarningLabel.BackColor = [Drawing.Color]::Transparent
$script:DiskWarningLabel.Font = New-Object Drawing.Font('Segoe UI', 11)
$script:DiskWarningLabel.TextAlign = [Drawing.ContentAlignment]::MiddleLeft

$buttons = New-Object Windows.Forms.TableLayoutPanel
$buttons.Dock = [Windows.Forms.DockStyle]::Fill
$buttons.BackColor = [Drawing.Color]::Transparent
$buttons.ColumnCount = 2
$buttons.RowCount = 3
[void]$buttons.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent, 50)))
[void]$buttons.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent, 50)))
[void]$buttons.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent, 33.33)))
[void]$buttons.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent, 33.33)))
[void]$buttons.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent, 33.34)))
$buttons.Controls.Add((New-ActionButton 'Verrouiller le stockage USB' ([Drawing.Color]::FromArgb(190, 70, 68)) { Invoke-UsbAction -Action Lock }), 0, 0)
$buttons.Controls.Add((New-ActionButton 'Déverrouiller le stockage USB' ([Drawing.Color]::FromArgb(35, 135, 100)) { Invoke-UsbAction -Action Unlock }), 1, 0)
$buttons.Controls.Add((New-ActionButton 'Restaurer la valeur initiale' ([Drawing.Color]::FromArgb(80, 95, 125)) { Invoke-UsbAction -Action Restore }), 0, 1)
$buttons.Controls.Add((New-ActionButton 'Ouvrir le journal des opérations' ([Drawing.Color]::FromArgb(55, 105, 170)) {
    if (Test-Path -LiteralPath $script:LogPath -PathType Leaf) {
        Start-Process -FilePath notepad.exe -ArgumentList ('"{0}"' -f $script:LogPath)
    } else {
        Show-Message -Text "Le journal des opérations n’existe pas encore." -Icon Warning
    }
}), 1, 1)
$buttons.Controls.Add((New-ActionButton 'Quitter' ([Drawing.Color]::FromArgb(75, 82, 96)) { $script:MainForm.Close() }), 0, 2)
$buttons.SetColumnSpan($buttons.GetControlFromPosition(0, 2), 2)

$script:MessageLabel = New-Object Windows.Forms.Label
$script:MessageLabel.Dock = [Windows.Forms.DockStyle]::Fill
$script:MessageLabel.BackColor = [Drawing.Color]::Transparent
$script:MessageLabel.Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
$script:MessageLabel.TextAlign = [Drawing.ContentAlignment]::MiddleLeft
$script:MessageLabel.Text = 'Choisissez une action. Les opérations sensibles demandent confirmation.'
$script:MessageLabel.ForeColor = [Drawing.Color]::LightGray

$footer = New-Object Windows.Forms.Label
$footer.Dock = [Windows.Forms.DockStyle]::Fill
$footer.BackColor = [Drawing.Color]::Transparent
$footer.Font = New-Object Drawing.Font('Segoe UI', 9)
$footer.TextAlign = [Drawing.ContentAlignment]::MiddleLeft
$footer.ForeColor = [Drawing.Color]::FromArgb(155, 165, 180)
$footer.Text = "Le mot de passe n’est jamais écrit dans le journal."

$layout.Controls.Add($header, 0, 0)
$layout.Controls.Add($script:StateLabel, 0, 1)
$layout.Controls.Add($script:DiskWarningLabel, 0, 2)
$layout.Controls.Add($buttons, 0, 3)
$layout.Controls.Add($script:MessageLabel, 0, 4)
$layout.Controls.Add($footer, 0, 5)
$script:MainForm.Controls.Add($layout)

$script:MainForm.Add_Shown({ [void](Update-Status) })
$script:MainForm.Add_FormClosed({
    if ($script:BackgroundImage) {
        $script:MainForm.BackgroundImage = $null
        $script:BackgroundImage.Dispose()
    }
})
[void][Windows.Forms.Application]::Run($script:MainForm)
