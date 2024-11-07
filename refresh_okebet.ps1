# Change directory to the location of your scripts
$scriptPath = $PSScriptRoot

# Execute the Python script using the virtual environment
$pythonPath = Join-Path $scriptPath ".venv\Scripts\python.exe"
$refreshScriptPath = Join-Path $scriptPath "refresh.py"

# Run the script
& "$pythonPath" "$refreshScriptPath"

# Prevent the PowerShell window from closing immediately
Read-Host -Prompt "Press Enter to exit"