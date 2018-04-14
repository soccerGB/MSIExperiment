echo "Start running setupproxynet.ps1"

# Powershell core
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"

REM the followign lines are debugging prupose
ipconfig 
echo " Run the following commands into each client
echo "curl -H Metadata:true "http://169.254.169.254"


REM launch python service for service any MSI metadata request
python .\app.py