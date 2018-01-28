
# Experiments on proxying MSI requests proxying in a Windows agent node on a DC/OS cluster deployed on Azure 

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from client containers through a dedicated proxy container. My experiment below show this can be done with appropriate port fordwarding and routing setup on a DC/OS Windows agent node running WindowsServerCore:1709 build. 

![Block diagram for Proxying Instance Metadata Service request](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/InstanceMetadata.png "Proxying Instance Metadata Service request")


Note: 
- This ProxyContainer plays a similiar role like [iam-docker](https://github.com/swipely/iam-docker) used in an EC2 instance except both client containers and the proxycontainer are in the same subnet. 
- This experiment only focuses on the Windows specific setup needed in an Windows VM under Azure environment for the MSI proxying to work, that is, the additional setup discussed here needed to add on top of a component with similiar functinoality like iam-docker for the whole end-to-end scenario to work in production.

## How it works

![Detailed interaction diagramt](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/DetailedMSIPortforwardingComponents.png "Proxying Instance Metadata Service request")

ps.Only the color components need ne coding

Here is the operation sequence:

   1. Schedule a Container Monitor Task
   
         - This is a long running task, it jobs is to monitor the life cycle of each container with specific 
            labels ("MSIProxyContainer" or "MSIClientContainer")
         - When the ProxyContainer (container with MSIProxyContaienr label, was created, it records its ip address.
         - For each newly created MSI client container, it will setup its portforwarding configuration remotely 
           via "docker exec" command with proxy container ip address stored in above steps
         - This task should also handle the required reconfiguration scenarios in cases that the ProxyContainer died and restarted 
         
   
   2.	Build the proxycontainer image with the following new route added into its routing table 
      as part of the container startup sequence

      New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP

      Launch the proxycontainer with MSIProxyContainer as its label
      docker run -it --label MSIProxyContainer proxyImageName 

   3.	Launch a clientcontainer instances with MSIClientContainer as its label

         docker run -it --label MSIClientContainer clientImageName
         
   4.	MSI requests were triggered from inside a clientcontainer 
      The return metadata will be sent back the requesting client container once returned from the MSI service (in step 5)
   
   5. MSI requests got forwarded to the ProxyContainer, which in turn send them through the MSI VM Extension
      for getting the actual MSI metadata before returning the result back to the requesting clientcontainer

   Design considerations:
      
   - Pros:
      - Fits well into DC/OS Mesos’s Docker Containerizer model     
      - This approach requires no additional logics added for into the client container image code      
      - Both the client containers and the proxycontainer are in the same subnet (NAT).
      - Supported by WindowsServer:1709 and later
      
   - Cons:
      - Required configuration operations outside of containers:
        the additon of the "Container Monitor Task", which requires some work
        This was added to workaround the limitation that the existing Windows networking routing feature does NOT include 
        the Linux iptable routing feature (rerouting all traffics with specifc dest IP from a NAT to a specific net interface)
        in the context of the NAT networking mode 
      - In the future, once we move to Mesos' Univeral Container Runtime, we might use CNI plug and use L2Bridge mode instead
      - NAT might not be as performing as Transparent or L2Bridge networking modes


## How to run this test 

   [A look at this test run log here will get you better idea on how it actually works](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/TestRun.md)

