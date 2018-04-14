

# Download/expand Powershell Core 6.0 to the build machine 
# for adding PowershellCore support into RS4 NanoServer
# , which does not include PowershellCore in it

$PowershellCoreName = "PowershellCore.zip"
$url = "https://github.com/PowerShell/PowerShell/releases/download/v6.0.0/PowerShell-6.0.0-win-x64.zip"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
Invoke-WebRequest -Uri $url -OutFile $PowershellCoreName

Write-Host "Expanding $PowershellCoreName ..."
Expand-Archive $PowershellCoreName -DestinationPath .\PowershellCore

# build a rs4 nanoserver docker image with Powershell support

Write-output "Generating microsoft/nanoserver-insider-ps docker image"
docker build -t  microsoft/nanoserver-insider-ps . 

# Cleaup 
Write-Host 'Removing ...'
Remove-Item $PowershellCoreName -Force
Remove-Item -Recurse -Force .\PowershellCore
