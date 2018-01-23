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
      - a new feature only available on Windows RS4 or later
      - currently limited to L2Bridge netowork mode
      
   
