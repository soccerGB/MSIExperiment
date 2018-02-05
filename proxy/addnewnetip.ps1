Write-Host "Adding 169.254.169.254 to network interface"
$ifIndex = get-netadapter | select -expand ifIndex
New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254

ipconfig

# Need to wait for sometime for the IP address to get added into network interface
# the following delay was added, for testing purose.
Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4