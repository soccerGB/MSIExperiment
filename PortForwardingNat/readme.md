
# Port forwarding  

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from client containers through a dedicated proxy container. My experiment belows show, with appropriate port fordwarding and routing setup,  it's possible to achieve above scenario inside a Azure VM running a WindowsServerCore:1709 (`RS3`) build. 

![Block diagram for Proxying Instance Metadata Service request](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/InstanceMetadata.png "Proxying Instance Metadata Service request")


## How it works

Here is the operation sequence:

   1.	Build the proxycontainer image with adding the following new route into its routing table 
      as part of the container startup sequence

      New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP

   2.	Launch the proxycontainer

   3.	Outside the proxycontainer, find the ip address of the proxycontainer  and assign it to a global 
      environment variable “IMSProxyIpAddress”

   4.	Build a client container that sets up port forwarding from 169.254.169.254 to the proxycontainer 
      IpAddress  (IMSProxyIpAddress)

         Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 
                        connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp

   5.	Launch a clientcontainer with IMSProxyIpAddress passed in via environment variable option (-e). 

         docker run -it -e IMSProxyIpAddress msitest/test:clientcontainer

   - Pros:
      - Supported by WindowsServer:1709 and later
      - Support NAT (bridge) network mode
      - Fits well into DC/OS Mesos’s Docker Containerizer model 
   - Cons:
      - This approach requires additional logics added for into the client container code
      - Some setup operations  (step c above) outside of container payload
      - NAT is not as performing as Transparent or L2Bridge 


## How to run this test 

   [Here is a test run of the current prototype](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/TestRun.md)

