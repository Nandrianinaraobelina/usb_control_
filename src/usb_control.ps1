$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$script:RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR'
$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:DataDirectory = Join-Path $script:ProjectRoot 'data'
if (-not (Test-Path -LiteralPath $script:DataDirectory -PathType Container)) {
    New-Item -Path $script:DataDirectory -ItemType Directory -ErrorAction Stop | Out-Null
}
$script:LogPath = Join-Path $script:DataDirectory 'usb_control.log'
$script:BackupPath = Join-Path $script:DataDirectory 'usb_control.previous'
$script:Password = [Environment]::GetEnvironmentVariable('USB_CONTROL_PASSWORD')
$script:MainForm = $null
$script:BackgroundImage = $null
$script:StateLabel = $null
$script:DiskWarningLabel = $null
$script:MessageLabel = $null
$script:UsbDiskList = $null
$script:RestoreButton = $null

. (Join-Path $PSScriptRoot 'Modules\Storage.ps1')
. (Join-Path $PSScriptRoot 'Modules\Dialogs.ps1')
. (Join-Path $PSScriptRoot 'Modules\Actions.ps1')

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
$script:MainForm.ClientSize = New-Object Drawing.Size(900, 780)
$script:MainForm.MinimumSize = New-Object Drawing.Size(800, 700)
$script:MainForm.BackColor = [Drawing.Color]::FromArgb(17, 24, 39)
$script:BackgroundImage = [Drawing.Image]::FromFile((Join-Path $script:ProjectRoot 'assets\usb-control-background.jpg'))
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
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 58)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 64)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 52)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 138)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent, 100)))
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

$script:UsbDiskList = New-Object Windows.Forms.ListView
$script:UsbDiskList.Dock = [Windows.Forms.DockStyle]::Fill
$script:UsbDiskList.View = [Windows.Forms.View]::Details
$script:UsbDiskList.FullRowSelect = $true
$script:UsbDiskList.GridLines = $true
$script:UsbDiskList.BackColor = [Drawing.Color]::FromArgb(25, 34, 49)
$script:UsbDiskList.ForeColor = [Drawing.Color]::White
[void]$script:UsbDiskList.Columns.Add('Modèle', 420)
[void]$script:UsbDiskList.Columns.Add('Capacité', 140)
[void]$script:UsbDiskList.Columns.Add('Lettre de lecteur', 180)

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
$script:RestoreButton = New-ActionButton 'Restaurer la valeur initiale' ([Drawing.Color]::FromArgb(80, 95, 125)) { Invoke-UsbAction -Action Restore }
$script:RestoreButton.Enabled = $false
$buttons.Controls.Add($script:RestoreButton, 0, 1)
$buttons.Controls.Add((New-ActionButton 'Ouvrir le journal des opérations' ([Drawing.Color]::FromArgb(55, 105, 170)) {
            Show-OperationLogDialog
        }), 1, 1)
$buttons.Controls.Add((New-ActionButton 'Actualiser' ([Drawing.Color]::FromArgb(55, 105, 170)) {
            $state = Update-Status
            if ($null -ne $state) {
                $script:MessageLabel.Text = 'État et liste des disques actualisés.'
                $script:MessageLabel.ForeColor = [Drawing.Color]::FromArgb(91, 220, 160)
            }
        }), 0, 2)
$buttons.Controls.Add((New-ActionButton 'Quitter' ([Drawing.Color]::FromArgb(75, 82, 96)) { $script:MainForm.Close() }), 1, 2)

$script:MessageLabel = New-Object Windows.Forms.Label
$script:MessageLabel.Dock = [Windows.Forms.DockStyle]::Fill
$script:MessageLabel.BackColor = [Drawing.Color]::Transparent
$script:MessageLabel.Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
$script:MessageLabel.TextAlign = [Drawing.ContentAlignment]::MiddleLeft
$script:MessageLabel.Text = 'Choisissez une action. Les opérations sensibles demandent confirmation.'
$script:MessageLabel.ForeColor = [Drawing.Color]::LightGray

$footer = New-Object Windows.Forms.TableLayoutPanel
$footer.Dock = [Windows.Forms.DockStyle]::Fill
$footer.BackColor = [Drawing.Color]::Transparent
$footer.ColumnCount = 2
$footer.RowCount = 1
[void]$footer.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent, 58)))
[void]$footer.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent, 42)))

$privacyNote = New-Object Windows.Forms.Label
$privacyNote.Dock = [Windows.Forms.DockStyle]::Fill
$privacyNote.BackColor = [Drawing.Color]::Transparent
$privacyNote.Font = New-Object Drawing.Font('Segoe UI', 9)
$privacyNote.TextAlign = [Drawing.ContentAlignment]::MiddleLeft
$privacyNote.ForeColor = [Drawing.Color]::FromArgb(155, 165, 180)
$privacyNote.Text = "Le mot de passe n’est jamais écrit dans le journal."

$authorLink = New-Object Windows.Forms.LinkLabel
$authorLink.Dock = [Windows.Forms.DockStyle]::Fill
$authorLink.BackColor = [Drawing.Color]::Transparent
$authorLink.Font = New-Object Drawing.Font('Segoe UI', 9)
$authorLink.TextAlign = [Drawing.ContentAlignment]::MiddleRight
$authorLink.LinkColor = [Drawing.Color]::FromArgb(115, 170, 255)
$authorLink.ActiveLinkColor = [Drawing.Color]::White
$authorLink.VisitedLinkColor = [Drawing.Color]::FromArgb(115, 170, 255)
$authorLink.LinkBehavior = [Windows.Forms.LinkBehavior]::HoverUnderline
$authorLink.Text = 'Développé par Hery Nandrianina'
$authorLink.Add_LinkClicked({
        Start-Process -FilePath 'https://herynandrianina-portfolio.onrender.com/'
    })
$footer.Controls.Add($privacyNote, 0, 0)
$footer.Controls.Add($authorLink, 1, 0)

$layout.Controls.Add($header, 0, 0)
$layout.Controls.Add($script:StateLabel, 0, 1)
$layout.Controls.Add($script:DiskWarningLabel, 0, 2)
$layout.Controls.Add($script:UsbDiskList, 0, 3)
$layout.Controls.Add($buttons, 0, 4)
$layout.Controls.Add($script:MessageLabel, 0, 5)
$layout.Controls.Add($footer, 0, 6)
$script:MainForm.Controls.Add($layout)

$script:MainForm.Add_Shown({ [void](Update-Status) })
$script:MainForm.Add_FormClosed({
        if ($script:BackgroundImage) {
            $script:MainForm.BackgroundImage = $null
            $script:BackgroundImage.Dispose()
        }
    })
[void][Windows.Forms.Application]::Run($script:MainForm)
