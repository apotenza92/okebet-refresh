# create_scheduled_task.ps1
param(
    [switch]$Test = $false
)

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $commandLine = "-NoExit -File `"$($MyInvocation.MyCommand.Path)`""
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $commandLine -Wait
    exit
}

# Get the current script's directory
$scriptPath = $PSScriptRoot
$refreshScript = Join-Path $scriptPath "refresh_okebet.ps1"
$pythonExe = Join-Path $scriptPath ".venv\Scripts\python.exe"
$refreshPy = Join-Path $scriptPath "refresh.py"

# Get current user for task
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Remove existing task if it exists
try {
    $existingTask = Get-ScheduledTask -TaskName "OkeBet Refresh" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName "OkeBet Refresh" -Confirm:$false
        Write-Host "Existing task removed." -ForegroundColor Green
    }
}
catch {
    Write-Host "Error removing existing task: $_" -ForegroundColor Red
}

# Create task configuration
$action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -Command `"Set-Location '$scriptPath'; & '$pythonExe' '$refreshPy'`"" `
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
    -UserId $currentUser `
    -LogonType Interactive `
    -RunLevel Highest

try {
    # Register the scheduled task
    Register-ScheduledTask `
        -TaskName "OkeBet Refresh" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Force

    Write-Host "Task created successfully!" -ForegroundColor Green

    if ($Test) {
        Write-Host "Testing task..." -ForegroundColor Yellow
        & "$PSScriptRoot\test_scheduled_task.ps1"
    }
}
catch {
    Write-Host "Error creating task: $_" -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"