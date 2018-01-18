
function CreateL2BridgeNetwork {
 param( [string]$networkname)

    $alias="Ethernet"
    write-output "    Searching for NetIPConfiguration with alias = $alias"   
    $netconfig = Get-NetIPConfiguration -InterfaceAlias $alias

    if ($netconfig.Count -eq 0) {
        throw "    No spare newwork interface found for creating L2bridge"
    } elseif  (-NOT ($netconfig.Count -eq 1)) {
        throw "    More than one vEthernet (Ethernet) found, this is an unexpected condition, error out"
    }

    $ipAddress = $netconfig.IPv4Address.IPAddress
    $gateway = $netconfig.IPv4DefaultGateway.NextHop
    $prefixLength = (Get-NetIPAddress $ipAddress).PrefixLength

    write-output "    IPAddress = $ipAddress"
    write-output "    prefixLength = $prefixLength"
    write-output "    gateway = $gateway"

    # create network creation parameters
    $l2bridgeCreationCmd = "    docker network create -d l2bridge --subnet=$ipAddress/$prefixLength --gateway=$gateway -o com.docker.network.windowsshim.interface=`"Ethernet`" $networkname"

    Write-Host "running:  $l2bridgeCreationCmd"

    Invoke-Expression $l2bridgeCreationCmd
}

$l2bridgeNetworkName="winl2bridge"

write-host "*********************************************************"
write-host "\nList all the Docker networks before any operations:\n"
write-host "*********************************************************"
docker network ls

write-host "Search $l2bridgeNetworkName network"

$networks = docker network ls --format "{{.Name}}" --filter name=$l2bridgeNetworkName
write-host "Num of networks found: "  $networks.Count

#check to see if $l2bridgeNetworkName network exists, create one if not

if ($networks.Count -eq 0) {

    Write-Host "No L2bridge network found, need to create one here"
    write-output "Preparing l2bridge network creation parameters"
    CreateL2BridgeNetwork($l2bridgeNetworkName)

} elseif ($networks.Count -eq 1){

    Write-Host "L2bridge network found"

} else {

    Write-Host "More than one L2bridge network found : $networks found, this cannot be!"
    throw "This cannot be!"
}

write-host "*********************************************************"
write-host "List all the Docker networks after executing this script:"
write-host "*********************************************************"
docker network ls
docker network inspect $l2bridgeNetworkName




