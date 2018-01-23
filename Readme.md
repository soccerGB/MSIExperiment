# Experiments on the redirecting Azure Instance Metadata Service requests from Docker containers to an external facing proxy Docker container  

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from inside client containers through a dedicated proxy container. 
   
   
   There are two possible approaches:
   
   1. [Port fordwaring](https://github.com/soccerGB/MSIExperiment/tree/master/PortForwardingNat) 

     Here is the operation sequence:
            a.	Build the proxycontainer image with adding the following new route into its routing table as part of the container startup sequence
            New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP
            b.	Launch the proxycontainer
            c.	Outside the proxycontainer, find the ip address of the proxycontainer  and assign it to a global environment variable “IMSProxyIpAddress”
            d.	Build a client container that sets up port forwarding from 169.254.169.254 to the proxycontainer IpAddress  (IMSProxyIpAddress)
            i.	Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp
            e.	Launch a clientcontainer with IMSProxyIpAddress passed in via environment variable option (-e). 
            i.	docker run -it -e IMSProxyIpAddress msitest/test:clientcontainer
            
            Pros:
            •	Supported by WindowsServer:1709 and later
            •	Support NAT (bridge) network mode, which is a mode that Adobe prefers at this moment.
            •	Fits well into DC/OS Mesos’s Docker Containerizer model 
            
            Cons:
            •	This approach requires additional logics added for into the client container code
            •	Some setup operations  (step c above) outside of container payload
            •	NAT is not as performing as Transparent or L2Bridge 

   2. [Proxy policy](https://github.com/soccerGB/MSIExperiment/tree/master/ProxyPolicyL2Bridge) feature
    
   
            Basically, this approach handles all the network setup outside of the Docker control.
         a.	Setup a L2Bridge hnsNetwork 
         i.	Create a hnsNetowork 
         ii.	Create a gateway hnsEndpoint off above L2bridge network and bind it into the host networking compartment (1) before enabling its ip forwarding
         b.	Launch the proxycontainer and create a hnsEndpoint before attaching it to the container instance’s corresponding compartment
         c.	Locate the ip address of the proxycontainer  (proxycontainer _ip)
         d.	Launch a clientcontainer and create a hnsEndpoint before attaching it to the container instance’s corresponding compartment
         e.	Setup a proxy policy on clientcontainer’s hsnEndpoint
         i.	Locate a clientcontainer’s hsnEndpoint id
         ii.	Create a proxy policy
         New-HnsProxyPolicy -Destination "proxycontainer _ip" -OutboundNat $true -DestinationPrefix 169.254.169.254 -DestinationPort 80  -Endpoints hsnEndpointId
         Pros:
         •	L2Bridge should be more efficient than Nat mode
         •	No need to add any logics into the client container
         •	This is the same mode used by the Kubernetes cluster
         •	With this CNI like approach (handling all the network outside of Docker), this could be a good solution when we move to DC/OS Mesos’ Universal Container Runtime model (we could hide all those details inside an isolation, or better yet we could wrap the CNI plug-in into it)
         Cons:
         •	Proxy policy does not support NAT mode 
         •	Still requires some operations  outside of container payload
         •	Only available on RS4 or later
         •	Does not fit well into DC/OS Mesos’s Docker Containerizer model, which is a thin wrapper around the native Docker CLI command

