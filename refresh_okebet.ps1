# Navigate to script directory and set location
Set-Location $PSScriptRoot

# Execute Python script from virtual environment
try {
    .\.venv\Scripts\python.exe refresh.py
}
catch {
    Write-Error $_.Exception.Message
}
finally {
    Read-Host -Prompt "Press Enter to exit"
}