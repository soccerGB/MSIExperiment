param (
    [Parameter(Mandatory=$true)]
    [string]$ContainerLabel
)

write-output "Locating the IP address for the contaienr with --lable=$ContainerLabel"

function locateClientIpAddress {
	$Address=$null
	$ContainerName = docker ps --filter "label=$ContainerLabel" --format '{{.Names}}'
	if (! $ContainerName) {
		return $null
	}
	Write-Host "Client cotnainer name is [$ContainerName]"
	$Address = docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $ContainerName
	Write-Host "IPAddress is [$Address]"
	return $proxyAddress, $ContainerName
}

$ClientIpAddress, $ContainerName = locateClientIpAddress 
Write-Host "Client cotnainer name is [$ContainerName]"


write-output "Removing  port forwarding"
$portForwardingCommand = "docker exec $ContainerName Netsh interface portproxy delete v4tov4 listenaddress=169.254.169.254 listenport=80 protocol=tcp"
Invoke-Expression $portForwardingCommand

#write-output "Removing 169.254.169.254 ip address from the container net interface"
#$getInterfaceIndexCommand = "docker exec $ContainerName powershell  `"get-netadapter | select -expand ifIndex`""
#$interfaceIndex = Invoke-Expression $getInterfaceIndexCommand 
#write-output "interfaceIndex  = $interfaceIndex"
#$removeIpAddressCommand = "docker exec $ContainerName powershell `"Remove-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress 169.254.169.254`""
#Invoke-Expression $removeIpAddressCommand

write-output "Done!"

