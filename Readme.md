
# Experiments on proxying MSI requests proxying in a Windows agent node on a DC/OS cluster deployed on Azure 

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from client containers through a dedicated proxy container. My experiment belows show this can be done with appropriate port fordwarding and routing setup on a DC/OS Windows agent node running WindowsServerCore:1709 build. 

![Block diagram for Proxying Instance Metadata Service request](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/InstanceMetadata.png "Proxying Instance Metadata Service request")


Note: This ProxyContainer plays similiar role like [iam-docker](https://github.com/swipely/iam-docker) used in an EC2 instance. This experiment only focuses on the Windows specific setup needed in an Windows VM under Azure environment for the MSI proxying to work, that is, the addional setup discussed here needed to add on top of a component with similiar functinoality like iam-docker for the whole end-to-end scenario to work in production.

## How it works

![Detailed interaction diagramt](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/DetailedMSIPortforwardingComponents.png "Proxying Instance Metadata Service request")

Here is the operation sequence:

   1.	Build the proxycontainer image with adding the following new route into its routing table 
      as part of the container startup sequence

      New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP

      Launch the proxycontainer

   2.	In a gloab task, outside the proxycontainer, find the ip address of the proxycontainer and assign it to a global 
      environment variable “IMSProxyIpAddress”

   3.	Build a client container that sets up port forwarding from 169.254.169.254 to the proxycontainer 
      IpAddress  (IMSProxyIpAddress)

         Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 
                        connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp

   	Launch a clientcontainer with IMSProxyIpAddress passed in via environment variable option (-e). 

         docker run -it -e IMSProxyIpAddress msitest/test:clientcontainer
         
   4.	MSI requests were triggered from inside a clientcontainer 
   
   5. MSI requests got forwarded to the ProxyContainer, which in turn send them through the MSI VM Extension
      for getting the actual MSI metadata before returning the result back to the requesting clientcontainer

   - Pros:
      - Supported by WindowsServer:1709 and later
      - Support NAT (bridge) network mode
      - Fits well into DC/OS Mesos’s Docker Containerizer model 
   - Cons:
      - This approach requires additional logics added for into the client container code
      - Some setup operations  (step c above) outside of container payload
      - NAT is not as performing as Transparent or L2Bridge networking modes


## How to run this test 

   [Here is a test run of the current prototype](https://github.com/soccerGB/MSIExperiment/blob/master/pf2/docs/TestRun.md)

