To create the network and prepare the host:
 
#   Create the L2Bridge Network
 
    $network = New-HnsNetwork -Name winl2bridge -Type L2Bridge -AddressPrefix 10.0.1.0/24 -Gateway 10.0.1.1

# Create a default gateway on the host for the container to use (.2 of the subnet as .1 is reserved)
 
    $hnsEndpoint = New-HnsEndpoint -NetworkId $network.ID -Name cbr0 -IPAddress 10.0.1.2 -Gateway "0.0.0.0" -Verbose
    Attach-HnsHostEndpoint -EndpointID $hnsEndpoint.Id -CompartmentID 1
    netsh int ipv4 set int "vEthernet (cbr0)" for=en

# Create your container through docker:
 
       docker run -it --rm --name proxyclient1 --network none proxyrs4 cmd
 
# To connect the container to the network:
 
    - Obtain container id + network compartment id
 
      $containerId = docker ps -aqf "name=proxyclient1"
      $compartmentId = docker exec $containerId powershell.exe "Get-NetCompartment | Select -ExpandProperty CompartmentId"

# Create a HNS network endpoint for the container and attach the endpoint to the compartment
 
$endpoint = new-hnsendpoint -NetworkId $network.ID -EnableOutboundNat -Gateway "10.0.1.2" -DNSServerList "168.63.129.16" -Verbose
Attach-HNSHostEndpoint -EndpointID $endpoint.ID -CompartmentID $compartmentId
 
 
# You should now be connected and will have access to the metadata server etc. For example, this should succeed:
 
curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02"
 
 
# Clean up
  When you are done with this container, you should clean up the HNS endpoint using something like 
  the following (docker won’t do this for you as it’s not aware of the endpoint):

  $endpoint | Remove-HnsEndpoint
                  <exit container>
