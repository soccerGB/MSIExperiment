
$ProxyContainerLabel="MSIProxyContainer"
function locateProxyIpAddress {
	$proxyAddress=$null

	$proxyCotnainerName = docker ps --filter "label=$ProxyContainerLabel" --format '{{.Names}}'

	if (! $proxyCotnainerName) {
		return $null
	}

	Write-Host "proxyCotnainerName is [$proxyCotnainerName]"

	$proxyAddress = docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $proxyCotnainerName
	Write-Host "proxyAddress is [$proxyAddress]"
	return $proxyAddress
}


$VariableScope = "Machine"
$IpAddressEnvName = "IMSProxyIpAddress"

Write-Host "Searching for the proxy container and set the $IpAddressEnvName to its ip address if found"

$existingProxyAddress =[Environment]::GetEnvironmentVariable($IpAddressEnvName, $VariableScope)

[Environment]::SetEnvironmentVariable($IpAddressEnvName, $null)
$existingProxyAddress = $null

if (! $existingProxyAddress) {
	Write-Host "$IpAddressEnvName is null"

	$proxyaddress = locateProxyIpAddress
	Write-Host "proxyaddress found is [$proxyaddress]"
	[Environment]::SetEnvironmentVariable($IpAddressEnvName, $proxyaddress, $VariableScope)
}
else {
	Write-Host "$IpAddressEnvName was set to [$proxyaddress]"
}
[Environment]::GetEnvironmentVariable($IpAddressEnvName, $VariableScope)


