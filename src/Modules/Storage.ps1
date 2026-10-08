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
