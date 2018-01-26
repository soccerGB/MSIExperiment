# Manual steps for setting up the ProxyPolxy on L2bridge in an Azure VM


## Setup L2bridge network and create a custom gateway hnsEndpoint 

0. Import hns powershell module, which could be found [here](https://github.com/soccerGB/MSIExperiment/blob/master/ProxyPolicyL2Bridge/scripts/hns.psm1)
 
    impo .\hns.psm1

1.  Create a HnsNetwork with L2Bridge type
 
    $network = New-HnsNetwork -Name winl2bridge -Type L2Bridge -AddressPrefix 10.0.1.0/24 -Gateway 10.0.1.1

2. Create a default gateway on the host for the container to use (.2 of the subnet as .1 is reserved)
 
    $hnsEndpoint = New-HnsEndpoint -NetworkId $network.ID -Name cbr0 -IPAddress 10.0.1.2 -Gateway "0.0.0.0" -Verbose
    Attach-HnsHostEndpoint -EndpointID $hnsEndpoint.Id -CompartmentID 1
    netsh int ipv4 set int "vEthernet (cbr0)" for=en


## Launch the proxy container and attach a newly created hnsendpoint to its container instance's network compartment

      PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy> docker run -it --network none  proxy cmd
      Microsoft Windows [Version 10.0.17076.1000]
      (c) 2017 Microsoft Corporation. All rights reserved.

      C:\app>ipconfig /allcompartments

      Windows IP Configuration

      ==============================================================================
      Network Information for Compartment 4 (ACTIVE)
      ==============================================================================
      C:\app>
    
    PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy>  $endpoint = new-hnsendpoint -NetworkId 9d2043fc-21e4-4a6f-8149-10429cc534d3
-EnableOutboundNat -Gateway "10.0.1.2" -DNSServerList "168.63.129.16" -Verbose


    PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy>  $endpoint

     ActivityId                : 36980714-a82d-4031-952e-b3714e8e984f
     CreateProcessingStartTime : 131614056248287200
     DNSServerList             : 168.63.129.16
     GatewayAddress            : 10.0.1.2
     ID                        : 32b8db4d-3ff7-4c0e-be59-30315e22cb84
     IPAddress                 : 10.0.1.136
     MacAddress                : 00-15-5D-8F-87-4C
     Name                      : Ethernet
     Policies                  : {@{Type=OutBoundNAT}, @{Type=L2Driver}}
     PrefixLength              : 24
     Resources                 : @{AllocationOrder=0; ID=36980714-a82d-4031-952e-b3714e8e984f; PortOperationTime=0; State=1;
                                 SwitchOperationTime=0; VfpOperationTime=0; parentId=6ff143bd-6b0a-4357-987a-e36f6aa706f6}
     SharedContainers          : {}
     State                     : 1
     Type                      : L2Bridge
     Version                   : 21474836481
     VirtualNetwork            : 9d2043fc-21e4-4a6f-8149-10429cc534d3
     VirtualNetworkName        : winl2bridge


     PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy> Attach-HNSHostEndpoint -EndpointID 36980714-a82d-4031-952e-b3714e8e984f -Comp
     artmentID 4

## Launch a client container and attach a newly created hnsendpoint to its container instance's network compartment

3. Create your container through docker:
 
     PS C:\Users\azureuser> docker run -it --network none client cmd
     Microsoft Windows [Version 10.0.17076.1000]
     (c) 2017 Microsoft Corporation. All rights reserved.

     C:\app>
     C:\app>ipconfig /allcompartments
     Windows IP Configuration
     ==============================================================================
     Network Information for Compartment 5 (ACTIVE)
     ==============================================================================
     C:\app>

     PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy>  $endpoint2 = new-hnsendpoint -NetworkId 9d2043fc-21e4-4a6f-8149-10429cc534d3
     -EnableOutboundNat -Gateway "10.0.1.2" -DNSServerList "168.63.129.16" -Verbose
     
     PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy> $endpoint2
     ActivityId                : 7afbc9bf-9a81-4372-9155-a11a089e2934
     CreateProcessingStartTime : 131614058534044378
     DNSServerList             : 168.63.129.16
     GatewayAddress            : 10.0.1.2
     ID                        : 1526575d-ef24-442f-8334-98149ebcb07d
     IPAddress                 : 10.0.1.248
     MacAddress                : 00-15-5D-8F-86-FB
     Name                      : Ethernet
     Policies                  : {@{Type=OutBoundNAT}, @{Type=L2Driver}}
     PrefixLength              : 24
     Resources                 : @{AllocationOrder=0; ID=7afbc9bf-9a81-4372-9155-a11a089e2934; PortOperationTime=0; State=1;
                                 SwitchOperationTime=0; VfpOperationTime=0; parentId=6ff143bd-6b0a-4357-987a-e36f6aa706f6}
     SharedContainers          : {}
     State                     : 1
     Type                      : L2Bridge
     Version                   : 21474836481
     VirtualNetwork            : 9d2043fc-21e4-4a6f-8149-10429cc534d3
     VirtualNetworkName        : winl2bridge 

    PS C:\> Attach-HNSHostEndpoint -EndpointID 1526575d-ef24-442f-8334-98149ebcb07d -CompartmentID 5

    Note: Obtaining container id + network compartment id:
      $containerId = docker ps -aqf "name=proxyclient1"
      $compartmentId = docker exec $containerId powershell.exe "Get-NetCompartment | Select -ExpandProperty CompartmentId"

    ====================
    5. Create a HNS network endpoint for the container and attach the endpoint to the compartment

        $endpoint = new-hnsendpoint -NetworkId $network.ID -EnableOutboundNat -Gateway "10.0.1.2" -DNSServerList "168.63.129.16" -Verbose
        Attach-HNSHostEndpoint -EndpointID $endpoint.ID -CompartmentID $compartmentId
    =======================

## Setup proxy policy 

    PS C:\github\MSIRS4\scripts> Get-HNSEndpoint | ? {$_.IPAddress -eq "10.0.1.248"; }  | % {$_.ID}
    1526575d-ef24-442f-8334-98149ebcb07d
    
    PS C:\github\MSIExperiment\ProxyPolicyL2Bridge\proxy> New-HnsProxyPolicy -Destination "10.0.1.2:80" -OutboundNat $true -Destination
    Prefix 169.254.169.254 -DestinationPort 80  -Endpoints 1526575d-ef24-442f-8334-98149ebcb07d

    ActivityId                : 7afbc9bf-9a81-4372-9155-a11a089e2934
    CreateProcessingStartTime : 131614058534044378
    DNSServerList             : 168.63.129.16
    GatewayAddress            : 10.0.1.2
    ID                        : 1526575d-ef24-442f-8334-98149ebcb07d
    IPAddress                 : 10.0.1.248
    MacAddress                : 00-15-5D-8F-86-FB
    Name                      : Ethernet
    Policies                  : {@{Type=OutBoundNAT}, @{Type=L2Driver}, @{Destination=10.0.1.2:80; IP=169.254.169.254;
                                OutboundNat=True; Port=80; Type=PROXY}}
    PrefixLength              : 24
    Resources                 : @{AllocationOrder=5; Allocators=System.Object[]; ID=7afbc9bf-9a81-4372-9155-a11a089e2934;
                                PortOperationTime=0; State=1; SwitchOperationTime=0; VfpOperationTime=0;
                                parentId=6ff143bd-6b0a-4357-987a-e36f6aa706f6}
    SharedContainers          : {}
    StartTime                 : 131614059830560691
    State                     : 2
    Type                      : L2Bridge
    Version                   : 21474836481
    VirtualNetwork            : 9d2043fc-21e4-4a6f-8149-10429cc534d3
    VirtualNetworkName        : winl2bridge


  
# You should now be connected and will have access to the metadata server etc. For example, this should succeed:
 
curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02"
 
 
# Clean up
  When you are done with this container, you should clean up the HNS endpoint using something like 
  the following (docker won’t do this for you as it’s not aware of the endpoint):

  $endpoint | Remove-HnsEndpoint
                  <exit container>
