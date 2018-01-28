
Write-Host "Adding 169.254.169.254 to network interface"
$ifIndex = get-netadapter | select -expand ifIndex
New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254

# Need to wait for sometime for the IP address to get added into network interface
# the following delay was added, for testing purose.
Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4

# dump output ipconfig for debugging purpose
ipconfig

# Reading IMSProxyIpAddress
# IMSProxyIpAddress is a global environment, it contains the ProxyContainer's IP address
# and it needs to be set outside the container after ProxyContainer's IP becomes available

$x = "IMSProxyIpAddress"
$IMSProxyIpAddress = (get-item env:$x).Value
Write-Host "IMSProxyIpAddress is $IMSProxyIpAddress"

# search for a running proxy container, if not found, exit
if ($IMSProxyIpAddress) {
	Write-Host "Setting up port forwarding for 169.254.169.254:80 to $IMSProxyIpAddress:80"
	Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp
} else {
	Write-Host "No IP address found -> no running proxy container found"
}

# Testing the accessibility of the MSI service from inside the container

Import-Module Microsoft.PowerShell.Utility
$val = 1
while($val -ne 0)
{
	Write-Host "Lets call 169.254.169.254 for fun"
	Write-Host "Receiving result from 169.254.169.254:"
       	Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -UseBasicParsing | Write-Host
	Start-Sleep -s 5
}

