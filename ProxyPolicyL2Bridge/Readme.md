

# Proxy policy solution

# How it works
Basically, this approach handles all the network setup outside of the Docker control.
1.	Setup a L2Bridge hnsNetwork 
  - Create a hnsNetowork 
  - Create a gateway hnsEndpoint off above L2bridge network and bind it into the host networking compartment (1) before enabling its ip forwarding
2.	Launch the proxycontainer and create a hnsEndpoint before attaching it to the container instance’s corresponding compartment
3.	Locate the ip address of the proxycontainer  (proxycontainer _ip)
4.	Launch a clientcontainer and create a hnsEndpoint before attaching it to the container instance’s corresponding compartment
5.	Setup a proxy policy on clientcontainer’s hsnEndpoint
i.	Locate a clientcontainer’s hsnEndpoint id
ii.	Create a proxy policy
New-HnsProxyPolicy -Destination "proxycontainer _ip" -OutboundNat $true -DestinationPrefix 169.254.169.254 -DestinationPort 80  -Endpoints hsnEndpointId

- Pros:
  -	L2Bridge should be more efficient than Nat mode
  -	No need to add any logics into the client container
  -	This is the same mode used by the Kubernetes cluster
  -	With this CNI like approach (handling all the network outside of Docker), this could be a good solution when we move to DC/OS Mesos’ Universal Container Runtime model (we could hide all those details inside an isolation, or better yet we could wrap the CNI plug-in into it)
  
- Cons:
  -	Proxy policy does not support NAT mode 
  -	Still requires some operations  outside of container payload
  -	Only available on RS4 or later
  -	Does not fit well into DC/OS Mesos’s Docker Containerizer model, which is a thin wrapper around the native Docker CLI command




git@github.com:soccerGB/MSIRS4.git

- You just need to build a VM from \\winbuilds\release\RS_onecore_stack_sdn_dev1

- Import a RS4 compatiable servercore OS container image
  
      eg: 
      copy \\winbuilds\release\RS_ONECORE_STACK_SDN_DEV1\17069.1006.180101-1700\amd64fre\containerbaseospkgs\cbaseospkg_serverdatacentercore_en-us\*.gz c:\temp\ServerCore.gz

      docker import c:\temp\ServerCore.gz microsoft/servercore:rs4
      
      PS C:\WINDOWS\system32> docker images
          REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
          microsoft/servercore   rs4                 edfd4431c954        6 seconds ago       3.6GB


- After that use \\skyshare\scratch\Users\sabansal\Tools\Powershell\hns.psm1 to put a policy on endpoint to redirect traffic. A sample is as follows:

https://github.com/soccerGB/MSIRS4/tree/master/scripts

-  
Get-HNSEndpoint | ? {$_.IPAddress -eq "10.0.0.3"; }  | % {$_.ID} | %{New-HnsProxyPolicy -Destination "10.137.198.118:8080" -OutbountNat $true -Endpoints $_}

This intercepts any traffic to go to 10.137.198.118:8080. You can put a destinationport and destination address filter. Have a look at the commmandlet for other parameters. I use it to redirect traffic to my host from a container with ip 10.0.0.3. 
