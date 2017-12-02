PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\net.ps1'"

echo "Import-Module Microsoft.PowerShell.Utility"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& Import-Module Microsoft.PowerShell.Utility"

echo "Testing the access to http://169.254.169.254"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -UseBasicParsing"

"You can start making Instance Metadata Service request via powershell: Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -UseBasicParsing"
cmd