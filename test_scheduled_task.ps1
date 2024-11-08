# test_scheduled_task.ps1
try {
    Start-ScheduledTask -TaskName "OkeBet Refresh"
    Write-Host "Task started. Check for a new PowerShell window." -ForegroundColor Green
}
catch {
    Write-Host "Error starting task: $_" -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"