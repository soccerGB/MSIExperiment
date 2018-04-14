function Get-PreferredInterfaceIndex {

    $interfacesOutput = netsh interface ipv4 show interfaces | findstr "Ethernet"
    #write-output $interfacesOutput
    $interfaceDataItems = $interfacesOutput.split([Environment]::NewLine)

    if ($interfaceDataItems.count -ne 1) {
            write-output "interfaceDataItems = $($interfaceDataItems.count)" | out-host
            write-output "Warning: more than one either net found, need to double check which one is the target interface to set" | out-host
            write-output "Not a fatal error, continue..." | out-host
    }
    <#
    foreach ($dataitem in $interfaceDataItems) {
        write-output "---"

        $dataitem = $dataitem -replace '\s+', ' '
        $dataitem = $dataitem.trim()
        $datafields = $dataitem.split(" ").trim()
        foreach ($field in $datafields) {
            write-output "*$field*"
        }
        write-output "---"
    }
    #>

    $test = $interfaceDataItems[0] -replace '\s+', ' '
    $interfaceDataItems[0] = $test.trim()

    $datafields = $interfaceDataItems[0].split(" ").trim()
    $Idx = $datafields[0]
 
 return $Idx
}


Write-Host "Adding 169.254.169.254 to network interface"

# Get-netadapter and New-NetIPAddress  are not available on nanoserver sku
# We would have to use netsh utility instead for adding new ip address 

<# 
$ifIndex = get-netadapter | select -expand ifIndex
New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254
#>

$ifIndex = Get-PreferredInterfaceIndex
Write-output "Interface index is $ifIndex"

#route add 169.254.169.254 mask 255.255.255.255 0.0.0.0 IF $ifIndex

netsh interface ipv4 add address $ifIndex address=169.254.169.254
#netsh interface ipv4 add address $ifIndex static 169.254.169.254 255.255.255.255


ipconfig /all

# Need to wait for sometime for the IP address to get added into network interface
# the following delay was added, for testing purose.
Write-host "wait for the network setting to be ready for use..."
Start-Sleep -s 4