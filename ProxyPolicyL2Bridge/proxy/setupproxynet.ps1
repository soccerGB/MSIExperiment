
Write-Host "Install necessary utilties"

#Write-Host "Import-Module NetAdapter..."
#Import-Module NetAdapter
#Write-Host "Import-Module Microsoft.PowerShell.Utility..."
#Import-Module Microsoft.PowerShell.Utility


Write-Host "Find the container ip address and gateway address"
# get container ip addres
$ifPartialAlias = "vEthernet (Ethernet)"
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4
write-host $ipAddresses

$count = $ipAddresses.Count

$containerIpAddress = "NotFound"

write-host "ipAddresses.count = $count"

foreach ($ip in $ipAddresses) {

    $ipx = $ip.IPAddress
    $ipAlias= $ip.InterfaceAlias
    write-output "IPAddress = $ipx"
    write-output "InterfaceAlias = $ipAlias"

    if (($ipx.IPAddress -ne "127.0.0.1") -And $ipAlias.Contains($ifPartialAlias)) {
        write-output "Found!"
	    $containerIpAddress = $ipx
	    break
    }
 }

Write-Host "contaienrIpAddress = $containerIpAddress"

#
# get the network interface and find its gateway ip
#

$ifIndex = Find-NetRoute -RemoteIPAddress $containerIpAddress | select -first 1  -expandproperty interfaceindex
$gatewayIP = get-netroute -DestinationPrefix '0.0.0.0/0' | select -ExpandProperty NextHop
Write-Host "ifIndex = $ifIndex"
Write-Host "gatewayIP = $gatewayIP"

Write-Host "Settig up a new route for the Instance Metadata Service endpoint 169.254.169.254"


New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP | Write-Host

route print -4
Write-Host "Testing access to the  Instance Metadata Service" from the proxy container"
Invoke-WebRequest -Uri "http://169.254.169.254/metadata/instance?api-version=2017-04-02" -Method GET  -Headers {"Metadata"="True"} -UseBasicParsing | Write-Host



