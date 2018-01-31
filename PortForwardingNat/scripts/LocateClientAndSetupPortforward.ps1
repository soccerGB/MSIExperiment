param (
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

$VariableScope = "Machine"
$IpAddressEnvName = "IMSProxyIpAddress"


$existingProxyAddress =[Environment]::GetEnvironmentVariable($IpAddressEnvName, $VariableScope)
write-output "IMSProxyIpAddress = [$existingProxyAddress]"

write-output "Adding 169.254.169.254 ip address to the container net interface"

$getInterfaceIndexCommand = "docker exec $ContainerName powershell  `"get-netadapter | select -expand ifIndex`""
$interfaceIndex = Invoke-Expression $getInterfaceIndexCommand 
write-output "interfaceIndex  = $interfaceIndex"

$addIpAddressCommand = "docker exec $ContainerName powershell `"New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress 169.254.169.254`""
Invoke-Expression $addIpAddressCommand

$printRouteCommand = "docker exec $ContainerName route print -4"
Invoke-Expression $printRouteCommand 

Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4

write-output "Setup port forwarding"

$portForwardingCommand = "docker exec $ContainerName Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=$existingProxyAddress connectport=80  protocol=tcp"
Invoke-Expression $portForwardingCommand

#write-output "Try out first MSI access from inside the client container"
#$testFirstMSICommand = "docker exec $ContainerName powershell `" `$headers=`@{}; `$headers[`"Metadata`"] = `"True`";  
#		   Invoke-WebRequest -Uri `"http://169.254.169.254`" -Method GET -Headers `$headers -UseBasicParsing`""
#Invoke-Expression $testFirstMSICommand


write-output "Done!"


write-output "Inside the client contianer ($ContainerName), you can exercise the following command to get MSI data"
write-output "`$headers=`@{}"
write-output "`$headers[`"Metadata`"] = `"True`""
write-output "Invoke-WebRequest -Uri `"http://169.254.169.254`" -Method GET -Headers `$headers -UseBasicParsing"


