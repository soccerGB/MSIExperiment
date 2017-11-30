
Write-Host "Adding 169.254.169.254 to network interface"
$ifIndex = get-netadapter | select -expand ifIndex
New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254

Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4
ipconfig

#reading IMSProxyIpAddress

$x = "IMSProxyIpAddress"
$IMSProxyIpAddress = (get-item env:$x).Value

Write-Host "IMSProxyIpAddress is $IMSProxyIpAddress"

# search for a running proxy container, if not found, exit

if ($IMSProxyIpAddress) {
	Write-Host "Setting up port fordwaring for 169.254.169.254:80 to $IMSProxyIpAddress:80"
	Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp
} else {
	Write-Host "No IP address found -> no running proxy container found"
}


