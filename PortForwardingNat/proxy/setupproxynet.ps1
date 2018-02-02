Import-Module NetAdapter
Import-Module Microsoft.PowerShell.Utility

# Collect networking information for adding a new route to the proxycontainer's route table
$ifIndex = get-netadapter | select -expand ifIndex 
$gatewayIP = get-netroute -DestinationPrefix '0.0.0.0/0' | select -ExpandProperty NextHop
Write-Host "gatewayIP = $gatewayIP"
New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP | Write-Host


#New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254

<#
Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4


$ProxyContainerLabel="ProxyContainer"
$proxyCotnainerName = docker ps --filter "label=$ProxyContainerLabel" --format '{{.Names}}'
Write-Host "proxyCotnainerName is [$proxyCotnainerName]"
$proxyAddress = docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $proxyCotnainerName

Write-Host "proxyAddress = $proxyAddress"


$containIP = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IpV4
$IPAddress = $containIP.IPAddress
Write-Host "IPAddress  = $IPAddress"

write-output "Setup port forwarding"
$portForwardingCommand = "Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=$IPAddress connectport=80  protocol=tcp"
Invoke-Expression $portForwardingCommand
#>

# for debugging, print out the routing table contents
route print -4

# testing the access to the MSI

$headers = @{}                                                                                        
$headers["Metadata"] = "`"True`""
Write-Host "Testing access to the  Instance Metadata Service" from the proxy container"
Invoke-WebRequest -Uri "http://169.254.169.254/metadata/instance?api-version=2017-04-02" -Method GET  -Headers $headers -UseBasicParsing" | Write-Host
