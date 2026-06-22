# ==============================
# Uptime Reboot Reminder
# ==============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Round corner type once
if (-not ("Win32Round" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32Round {
    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateRoundRectRgn(
        int nLeftRect,
        int nTopRect,
        int nRightRect,
        int nBottomRect,
        int nWidthEllipse,
        int nHeightEllipse
    );
}
"@
}

function Restart-Now {
    Start-Process shutdown.exe -ArgumentList "/r /f /t 0" -WindowStyle Hidden
}

function Show-Popup {
    param(
            [int]$Count
        )

    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
    $form.Size = New-Object System.Drawing.Size(500,250)
    $form.ControlBox = $false
    $form.KeyPreview = $true
    $form.ShowInTaskbar = $false

    $form.Region = [System.Drawing.Region]::FromHrgn(
        [Win32Round]::CreateRoundRectRgn(0,0,$form.Width,$form.Height,20,20)
    )

    $form.Add_KeyDown({
        if ($_.KeyCode -eq "Escape") {
            $_.SuppressKeyPress = $true
        }
    })

    $form.Add_FormClosing({
        if ($form.Tag -ne "postpone" -and $form.Tag -ne "reboot") {
            $_.Cancel = $true
        }
    })

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Bilgisayarın Yeniden Başlatılması Gerekiyor"
    $title.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::White
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(20,20)
    $form.Controls.Add($title)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Sistem çalışma süresi 48 saati aştı. Lütfen bilgisayarınızı yeniden başlatın.`r`n`r`nKalan Erteleme Hakkı: $($Count)"
    $label.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $label.ForeColor = [System.Drawing.Color]::Gainsboro
    $label.Size = New-Object System.Drawing.Size(450,60)
    $label.Location = New-Object System.Drawing.Point(20,65)
    $form.Controls.Add($label)

    $btnReboot = New-Object System.Windows.Forms.Button
    $btnReboot.Text = "Şimdi Yeniden Başlat"
    $btnReboot.Size = New-Object System.Drawing.Size(180,40)
    $btnReboot.Location = New-Object System.Drawing.Point(20,160)
    $btnReboot.FlatStyle = 'Flat'
    $btnReboot.FlatAppearance.BorderSize = 0
    $btnReboot.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
    $btnReboot.ForeColor = [System.Drawing.Color]::White
    $btnReboot.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $btnReboot.Add_Click({
        $form.Tag = "reboot"
        $form.Close()
    })
    $form.Controls.Add($btnReboot)

    $btnPostpone = New-Object System.Windows.Forms.Button
    $btnPostpone.Text = "1 Saat Ertele"
    $btnPostpone.Size = New-Object System.Drawing.Size(140,40)
    $btnPostpone.Location = New-Object System.Drawing.Point(220,160)
    $btnPostpone.FlatStyle = 'Flat'
    $btnPostpone.FlatAppearance.BorderSize = 1
    $btnPostpone.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btnPostpone.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $btnPostpone.ForeColor = [System.Drawing.Color]::White
    $btnPostpone.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $btnPostpone.Add_Click({
        $form.Tag = "postpone"
        $form.Close()
    })
    $form.Controls.Add($btnPostpone)

    [void]$form.ShowDialog()

    return $form.Tag
}

function Show-TimerPopup {
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'Manual'
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
    $form.Size = New-Object System.Drawing.Size(340,150)
    $form.ControlBox = $false
    $form.ShowInTaskbar = $false

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Left = $screen.Width - $form.Width - 20
    $form.Top  = $screen.Height - $form.Height - 20

    $form.Region = [System.Drawing.Region]::FromHrgn(
        [Win32Round]::CreateRoundRectRgn(0,0,$form.Width,$form.Height,18,18)
    )

    $script:allowClose = $false

    $form.Add_FormClosing({
        if (-not $script:allowClose) {
            $_.Cancel = $true
        }
    })

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Sistem Bildirimi"
    $title.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::White
    $title.Location = New-Object System.Drawing.Point(15,10)
    $title.AutoSize = $true
    $form.Controls.Add($title)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Bilgisayarınız 15 dakika içinde yeniden başlatılacaktır. Lütfen dosyalarınızı kaydediniz."
    $label.Font = New-Object System.Drawing.Font("Segoe UI",9)
    $label.ForeColor = [System.Drawing.Color]::Gainsboro
    $label.Size = New-Object System.Drawing.Size(305,45)
    $label.Location = New-Object System.Drawing.Point(15,35)
    $form.Controls.Add($label)

    $timerLabel = New-Object System.Windows.Forms.Label
    $timerLabel.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $timerLabel.ForeColor = [System.Drawing.Color]::FromArgb(0,120,215)
    $timerLabel.Location = New-Object System.Drawing.Point(15,88)
    $timerLabel.AutoSize = $true
    $form.Controls.Add($timerLabel)

    $script:remaining = 15 * 60

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000

    $timerLabel.Text = "Kalan süre: 15:00"

    $timer.Add_Tick({
        $script:remaining--

        $min = [int][math]::Floor($script:remaining / 60)
        $sec = [int]($script:remaining % 60)

        $timerLabel.Text = "Kalan süre: {0:00}:{1:00}" -f $min, $sec

        if ($script:remaining -le 0) {
            $timer.Stop()
            $script:allowClose = $true
            $form.Close()
        }
    })

    $timer.Start()
    [void]$form.ShowDialog()
}

function CreateSCTask {
    $dir      = "C:\ProgramData\Microsoft\Scripts"
    $vbs      = "$dir\UptimeChecker.vbs"
    $taskName = "UptimeChecker - Process"
    $time = (Get-Date).AddHours(1)


    $action = New-ScheduledTaskAction `
        -Execute "wscript.exe" `
        -Argument "`"$vbs`""

    $trigger = New-ScheduledTaskTrigger -Once -At $time

    $principal = New-ScheduledTaskPrincipal `
        -UserId "$env:USERDOMAIN\$env:USERNAME"
        -LogonType Interactive

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)


    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force | Out-Null  
}

# ==============================
# CONFIG
# ==============================

$ThresholdHours = 48
$RegPath = "HKCU:\Software\UptimeChecker"
$StateValue = "State"   # 0 = first, 1 = second, 2 = final countdown

# ==============================
# GET UPTIME
# ==============================

$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeHours = $uptime.TotalHours

if ($uptimeHours -lt $ThresholdHours) {
    if (Test-Path $RegPath) {
        Set-ItemProperty $RegPath -Name $StateValue -Value 0 -Force
    }
    Unregister-ScheduledTask -TaskName "UptimeChecker - Process" -Confirm:$false -ErrorAction SilentlyContinue
    exit 0
}

# ==============================
# INIT STATE
# ==============================

if (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
    New-ItemProperty $RegPath -Name $StateValue -Value 0 -PropertyType DWord -Force | Out-Null
}

$state = (Get-ItemProperty $RegPath -Name $StateValue -ErrorAction SilentlyContinue).$StateValue

# ==============================
# STATE MACHINE
# ==============================

if ($state -eq 0) {
    $result = Show-Popup -Count 2

    if ($result -eq "postpone") {
        Set-ItemProperty $RegPath -Name $StateValue -Value 1 -Force
        CreateSCTask
        exit 0
    }

    Restart-Now
    exit 0
}

elseif ($state -eq 1) {
    $result = Show-Popup -Count 1

    if ($result -eq "postpone") {
        Set-ItemProperty $RegPath -Name $StateValue -Value 2 -Force
        CreateSCTask
        exit 0
    }

    Restart-Now
    exit 0
}

elseif ($state -eq 2) {
    Show-TimerPopup
    Restart-Now
    exit 0
}