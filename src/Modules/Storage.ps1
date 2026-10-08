function Write-OperationLog {
    param(
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Result
    )

    $entry = '{0}; action={1}; resultat={2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Action, $Result
    Add-Content -LiteralPath $script:LogPath -Value $entry -Encoding UTF8 -ErrorAction Stop
}

function Get-OperationLogEntries {
    if (-not (Test-Path -LiteralPath $script:LogPath -PathType Leaf)) {
        return @()
    }

    $entries = New-Object 'System.Collections.Generic.List[object]'
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $script:LogPath -Encoding UTF8 -ErrorAction Stop) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -notmatch '^(?<Date>[^;]+);\s*action=(?<Action>[^;]*);\s*resultat=(?<Result>.*)$') {
            throw "Ligne $lineNumber invalide dans le journal des opérations."
        }

        $entries.Add([pscustomobject]@{
                Date   = $Matches.Date.Trim()
                Action = $Matches.Action.Trim()
                Result = $Matches.Result.Trim()
            })
    }

    return $entries.ToArray()
}

function Export-OperationLogCsv {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $entries = @(Get-OperationLogEntries)
    if ($entries.Count -gt 0) {
        $csv = $entries | ConvertTo-Csv -NoTypeInformation
    } else {
        $csv = '"Date","Action","Result"'
    }

    Set-Content -LiteralPath $Path -Value $csv -Encoding UTF8 -ErrorAction Stop
}

function Get-UsbState {
    $value = [uint32](Get-ItemPropertyValue -LiteralPath $script:RegistryPath -Name Start -ErrorAction Stop)
    [pscustomobject]@{
        Value = $value
        Hex   = '0x{0:X}' -f $value
        Text  = switch ($value) {
            4 { 'VERROUILLÉ' }
            3 { 'DÉVERROUILLÉ' }
            default { 'ÉTAT INCONNU' }
        }
    }
}

function Get-ConnectedUsbDisks {
    try {
        $disks = @(Get-CimInstance -ClassName Win32_DiskDrive -Filter "InterfaceType = 'USB'" -ErrorAction Stop)
        $inventory = New-Object 'System.Collections.Generic.List[object]'
        foreach ($disk in $disks) {
            $driveLetters = @(
                foreach ($partition in @(Get-CimAssociatedInstance -InputObject $disk -Association Win32_DiskDriveToDiskPartition -ErrorAction Stop)) {
                    foreach ($logicalDisk in @(Get-CimAssociatedInstance -InputObject $partition -Association Win32_LogicalDiskToPartition -ErrorAction Stop)) {
                        $logicalDisk.DeviceID
                    }
                }
            )

            $inventory.Add([pscustomobject]@{
                    Model       = if ([string]::IsNullOrWhiteSpace($disk.Model)) { 'Modèle inconnu' } else { $disk.Model.Trim() }
                    Capacity    = if ($disk.Size) { '{0:N1} Go' -f ($disk.Size / 1GB) } else { 'Inconnue' }
                    DriveLetter = if ($driveLetters.Count -gt 0) { $driveLetters -join ', ' } else { 'Aucune lettre' }
                })
        }

        return ,$inventory.ToArray()
    } catch {
        return $null
    }
}
