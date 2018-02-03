
$MSIProxyContainerLabel = "MSIProxyContainer"
$MSIServiceContainerLabel = "MSIServiceContainer"

function LocateContainerIpAddressByLabel{
    Param(
    [parameter(Mandatory=$true)]
    [String]
    $Label
    )

    Write-Host "Searching for a cotnainer with [$Label] label"

    $Address=$null
    $containername = docker ps --filter "label=$Label" --format '{{.Names}}'
    if (! $containername) {
	Write-Host "Cannot find any containers with $Label label"
	return $null, $null
    }
    Write-Host "Found: [$containername]"
    $address = docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containername
    Write-Host "with ip address = [$address]"
    return $address, $containername
 }

$proxyContainerIpAddress, $proxyContainerName = LocateContainerIpAddressByLabel -Label  $MSIProxyContainerLabel
Write-Host "proxyContainer: name([$proxyContainerName]) ipaddress([$proxyContainerIpAddress])"

$msiServiceContainerIpAddress, $msiServiceContainerName = LocateContainerIpAddressByLabel -Label  $MSIServiceContainerLabel
Write-Host "MSIServiceContainer: name([$msiServiceContainerName]) ipaddress([$msiServiceContainerIpAddress])"

#$VariableScope = "Machine"
#$IpAddressEnvName = "IMSProxyIpAddress"
#$existingProxyAddress =[Environment]::GetEnvironmentVariable($IpAddressEnvName, $VariableScope)
#write-output "IMSProxyIpAddress = [$existingProxyAddress]"

# This is the key operation of this script: addig 169.254.169.254 IP address to
# the proxycontainer, which would cause all the MSI metadata requests (via 169.254.169.254)
# all go to the proxycontainer
#
write-output "Adding 169.254.169.254 ip address to the container net interface"
$getInterfaceIndexCommand = "docker exec $proxyContainerName powershell  `"get-netadapter | select -expand ifIndex`""
$interfaceIndex = Invoke-Expression $getInterfaceIndexCommand 
write-output "interfaceIndex  = $interfaceIndex"

$addIpAddressCommand = "docker exec $proxyContainerName powershell `"New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress 169.254.169.254`""
Invoke-Expression $addIpAddressCommand

$printRouteCommand = "docker exec $proxyContainerName route print -4"
Invoke-Expression $printRouteCommand 

Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4

write-output "Done!"

write-output "Inside the client contianer ($ContainerName), you can exercise the following command to get MSI data"
write-output "`$headers=`@{}"
write-output "`$headers[`"Metadata`"] = `"True`""
write-output "Invoke-WebRequest -Uri `"http://169.254.169.254`" -Method GET -Headers `$headers -UseBasicParsing"


