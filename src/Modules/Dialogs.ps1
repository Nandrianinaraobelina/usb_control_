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

function Show-OperationLogDialog {
    try {
        $entries = @(Get-OperationLogEntries)
    } catch {
        Show-Message -Text "Impossible de lire le journal : $($_.Exception.Message)" -Icon Error
        return
    }

    $dialog = New-Object Windows.Forms.Form
    $dialog.Text = 'Historique des opérations'
    $dialog.StartPosition = 'CenterParent'
    $dialog.ClientSize = New-Object Drawing.Size(860, 460)
    $dialog.MinimumSize = New-Object Drawing.Size(700, 360)
    $dialog.BackColor = [Drawing.Color]::FromArgb(17, 24, 39)
    $dialog.ForeColor = [Drawing.Color]::White
    $dialog.Font = New-Object Drawing.Font('Segoe UI', 10)

    $layout = New-Object Windows.Forms.TableLayoutPanel
    $layout.Dock = [Windows.Forms.DockStyle]::Fill
    $layout.BackColor = [Drawing.Color]::Transparent
    $layout.ColumnCount = 1
    $layout.RowCount = 2
    [void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent, 100)))
    [void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute, 58)))

    $list = New-Object Windows.Forms.ListView
    $list.Dock = [Windows.Forms.DockStyle]::Fill
    $list.View = [Windows.Forms.View]::Details
    $list.FullRowSelect = $true
    $list.GridLines = $true
    $list.BackColor = [Drawing.Color]::FromArgb(25, 34, 49)
    $list.ForeColor = [Drawing.Color]::White
    [void]$list.Columns.Add('Date', 180)
    [void]$list.Columns.Add('Action', 220)
    [void]$list.Columns.Add('Résultat', 400)

    if ($entries.Count -eq 0) {
        [void]$list.Items.Add('Aucune opération enregistrée.')
    } else {
        foreach ($entry in $entries) {
            $item = New-Object Windows.Forms.ListViewItem($entry.Date)
            [void]$item.SubItems.Add($entry.Action)
            [void]$item.SubItems.Add($entry.Result)
            [void]$list.Items.Add($item)
        }
    }

    $buttons = New-Object Windows.Forms.FlowLayoutPanel
    $buttons.Dock = [Windows.Forms.DockStyle]::Fill
    $buttons.FlowDirection = [Windows.Forms.FlowDirection]::RightToLeft
    $buttons.BackColor = [Drawing.Color]::Transparent
    $buttons.Padding = New-Object Windows.Forms.Padding(0, 8, 0, 0)

    $closeButton = New-Object Windows.Forms.Button
    $closeButton.Text = 'Fermer'
    $closeButton.Size = New-Object Drawing.Size(110, 38)
    $closeButton.DialogResult = [Windows.Forms.DialogResult]::Cancel

    $exportButton = New-Object Windows.Forms.Button
    $exportButton.Text = 'Exporter en CSV'
    $exportButton.Size = New-Object Drawing.Size(140, 38)
    $exportButton.Add_Click({
            $saveDialog = New-Object Windows.Forms.SaveFileDialog
            $saveDialog.Title = 'Exporter le journal des opérations'
            $saveDialog.Filter = 'Fichier CSV (*.csv)|*.csv'
            $saveDialog.FileName = 'journal_operations.csv'
            if ($saveDialog.ShowDialog($dialog) -eq [Windows.Forms.DialogResult]::OK) {
                try {
                    Export-OperationLogCsv -Path $saveDialog.FileName
                    [void][Windows.Forms.MessageBox]::Show(
                        $dialog,
                        'Le journal a été exporté avec succès.',
                        'Export terminé',
                        [Windows.Forms.MessageBoxButtons]::OK,
                        [Windows.Forms.MessageBoxIcon]::Information
                    )
                } catch {
                    [void][Windows.Forms.MessageBox]::Show(
                        $dialog,
                        "Impossible d’exporter le journal : $($_.Exception.Message)",
                        "Échec de l’export",
                        [Windows.Forms.MessageBoxButtons]::OK,
                        [Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }

            $saveDialog.Dispose()
        })

    $buttons.Controls.AddRange(@($closeButton, $exportButton))
    $layout.Controls.Add($list, 0, 0)
    $layout.Controls.Add($buttons, 0, 1)
    $dialog.Controls.Add($layout)
    $dialog.CancelButton = $closeButton
    [void]$dialog.ShowDialog($script:MainForm)
    $dialog.Dispose()
}
