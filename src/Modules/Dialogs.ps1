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
