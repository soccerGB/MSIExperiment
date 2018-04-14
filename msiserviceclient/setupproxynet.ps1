
# The goal od this this script is to add a new route for 169.254.169.254/32
# inside the proxycontainer to make it possible to access MSI service running 
# on the Azure VM host.

function Get-PreferredInterfaceIndex {

    $interfacesOutput = netsh interface ipv4 show interfaces | findstr "Ethernet"
    #write-output $interfacesOutput
    $interfaceDataItems = $interfacesOutput.split([Environment]::NewLine)

    if ($interfaceDataItems.count -ne 1) {
            write-output "interfaceDataItems = $($interfaceDataItems.count)" | out-host
            write-output "Warning: more than one either net found, need to double check which one is the target interface to set" | out-host
            write-output "Not a fatal error, continue..." | out-host
    }

    $test = $interfaceDataItems[0] -replace '\s+', ' '
    $interfaceDataItems[0] = $test.trim()

    $datafields = $interfaceDataItems[0].split(" ").trim()
    $Idx = $datafields[0]
 
 return $Idx
}

function Get-GatewayIP {
    $routesOutput = route print -4 | findstr 0.0.0.0
    write-output $routesOutput | write-host 
    $routeDataItems = $routesOutput.split([Environment]::NewLine)
    $test = $routeDataItems[0] -replace '\s+', ' '
    $test = $test.trim()
    $datafields = $test.split(" ").trim()
    $ip = $datafields[2]
    return $ip
}

Import-Module Microsoft.PowerShell.Utility

# Collect networking information for adding a new route to the proxycontainer's route table
$ifIndex = Get-PreferredInterfaceIndex

# get-netroute is not available in PowershellCore so replace it with Get-GatewayIP netsh script
#$gatewayIP = get-netroute -DestinationPrefix '0.0.0.0/0' | select -ExpandProperty NextHop
$gatewayIP = Get-GatewayIP
Write-Host "gatewayIP = $gatewayIP"


# New-NetRoute is not available in PowershellCore so replace it with route utility
# New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP | Write-Host
route add 169.254.169.254 mask 255.255.255.255 $gatewayIP IF $ifIndex

# Any scripts below this line for testing and debugging only 

# Print out the routing table contents
# The following block is for the MSI access testing 
route print -4

# The following block is for the MSI access testing 
$headers = @{}                                                                                        
$headers["Metadata"] = "`"True`""
Write-Host "Testing access to the  Instance Metadata Service" from the proxy container"
Invoke-WebRequest -Uri "http://169.254.169.254/metadata/instance?api-version=2017-04-02" -Method GET  -Headers $headers -UseBasicParsing" | Write-Host
