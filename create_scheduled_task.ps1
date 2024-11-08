# Check if running as admin and self-elevate if needed
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    $arguments = "-File `"$($MyInvocation.MyCommand.Path)`""
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

# Get absolute paths
$scriptPath = $PSScriptRoot
$pythonExe = Join-Path $scriptPath ".venv\Scripts\python.exe"
$refreshPy = Join-Path $scriptPath "refresh.py"

try {
    # Remove existing task if it exists
    Get-ScheduledTask -TaskName "OkeBet Refresh" -ErrorAction SilentlyContinue | 
    Unregister-ScheduledTask -Confirm:$false

    # Create task configuration
    $action = New-ScheduledTaskAction `
        -Execute $pythonExe `
        -Argument "`"$refreshPy`"" `
        -WorkingDirectory $scriptPath

    $trigger = New-ScheduledTaskTrigger -Daily -At 6AM
    
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -WakeToRun `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest

    Register-ScheduledTask `
        -TaskName "OkeBet Refresh" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Force

    Write-Host "Task created successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating task: $_" -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"