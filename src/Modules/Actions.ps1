function Update-Status {
    $script:RestoreButton.Enabled = Test-Path -LiteralPath $script:BackupPath -PathType Leaf
    $script:RestoreButton.Text = 'Restaurer la valeur initiale'
    if ($script:RestoreButton.Enabled) {
        try {
            $backupText = (Get-Content -LiteralPath $script:BackupPath -Raw -ErrorAction Stop).Trim()
            $backupValue = [uint32]0
            if ([uint32]::TryParse($backupText, [ref]$backupValue)) {
                $script:RestoreButton.Text = 'Restaurer la valeur initiale (0x{0:X})' -f $backupValue
            } else {
                $script:RestoreButton.Text = 'Restaurer la valeur initiale (sauvegarde invalide)'
            }
        } catch {
            $script:RestoreButton.Text = 'Restaurer la valeur initiale (lecture impossible)'
        }
    }

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

    $disks = Get-ConnectedUsbDisks
    $diskCount = if ($null -eq $disks) { $null } else { @($disks).Count }
    $script:UsbDiskList.Items.Clear()
    if ($null -eq $diskCount) {
        $script:DiskWarningLabel.Text = 'Détection des disques USB indisponible.'
        $script:DiskWarningLabel.ForeColor = [Drawing.Color]::LightGray
    } elseif ($diskCount -gt 0) {
        $script:DiskWarningLabel.Text = "Attention : $diskCount disque(s) USB connecté(s). Ils peuvent rester accessibles après le verrouillage."
        $script:DiskWarningLabel.ForeColor = [Drawing.Color]::FromArgb(255, 190, 92)
        foreach ($disk in $disks) {
            $item = New-Object Windows.Forms.ListViewItem($disk.Model)
            [void]$item.SubItems.Add($disk.Capacity)
            [void]$item.SubItems.Add($disk.DriveLetter)
            [void]$script:UsbDiskList.Items.Add($item)
        }
    } else {
        $script:DiskWarningLabel.Text = 'Aucun disque USB connecté détecté.'
        $script:DiskWarningLabel.ForeColor = [Drawing.Color]::FromArgb(91, 220, 160)
        $item = New-Object Windows.Forms.ListViewItem('Aucun disque USB connecté')
        [void]$script:UsbDiskList.Items.Add($item)
    }

    return $state
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
        $disks = Get-ConnectedUsbDisks
        $diskCount = if ($null -eq $disks) { $null } else { @($disks).Count }
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
