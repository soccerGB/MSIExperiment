
# Experiments on proxying MSI requests proxying in a Windows agent node on a DC/OS cluster deployed on Azure 

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from client containers through a dedicated proxy container. The experiment below show this can be done with appropriate request forwading and routing setup on a DC/OS Windows agent node running WindowsServerCore:1709 build. 

![Block diagram for Proxying Instance Metadata Service request](https://github.com/soccerGB/MSIRequestProxy/blob/master/docs/InstanceMetadata.png "Proxying Instance Metadata Service request")


Note: 
- The ProxyContainer handles all the MSI requests on behalf app containers 
- The MSIServiceClient container plays a similiar role like [iam-docker](https://github.com/swipely/iam-docker) used in an EC2 instance except both client containers and the proxycontainer are in the same subnet. 
- This experiment only focuses on the Windows specific setup needed in an Windows VM under Azure environment for the MSI proxying to work, that is, the additional setup discussed here needed to be added add on top of a component with similiar functinoality like iam-docker for the whole end-to-end scenario to work in production.

## How it works

![Detailed interaction diagramt](https://github.com/soccerGB/MSIRequestProxy/blob/master/docs/DetailedMSIPortforwardingComponents.png "Proxying Instance Metadata Service request")

ps.Color blocks are new components

Here is the operation sequence:

   
   1.	Build and launch MSIServiceClient container image.
   
      MSIClientContainer\docker build -t MSIServiceContainer .
      
         Inside the image, the following new route added into its routing table as part of the container startup sequence. 
         This is needed for enabling accessing MSI from inside the MSIServiceClient container

         New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP

      Launch the proxycontainer with MSIServiceClient as its label
         docker run -it --label  MSIServiceClient MSIServiceClientImageName 
      
   2.	Build and launch the Proxycontainer with MSIProxyContainer as its label

         docker run -it --label MSIProxyContainer clientImageName
         
   3. Schedule a gloabl task to setup the MSI request forwarding 
   
         - This is a long running task, it jobs is to locate the MSIServiceClient container's ip addess before using it to set
           up the MSI request forwarding configuration. This configuration is done remotely via "docker exec" command into the 
           ProxyContainer container instance 
         
  4.	Launch app containers
  
         Example:
         docker run -d microsoft/windowsservercore:1709 cmd     
     
  5.	MSI requests were triggered from inside an app ontainer 
      The return metadata will be sent back the requesting client container once returned from the MSI service (in step 5)
   
  6. MSI requests got forwarded to the ProxyContainer, which in turn send them through the MSI VM Extension
      for getting the actual MSI metadata before returning the result back to the requesting clientcontainer

   Design considerations:
      
   - Pros:
      - Fits well into DC/OS Mesos’s Docker Containerizer model     
      - This approach requires no additional logics added for into the client container image code      
      - Both the ProxyContainer and the MSIServiceContaienr are in the same subnet as all app containers requesting MSI 
        metadata
      - Supported by WindowsServer:1709 and later
      
   - Cons:
      - Required configuration operations outside of containers:
        the additon of the "Container Monitor Task", which requires some work
        This was added to workaround the limitation that the existing Windows networking routing feature does NOT include 
        the Linux iptable routing feature (rerouting all traffics with specifc dest IP from a NAT to a specific net interface)
        in the context of the NAT networking mode 

## How to run this test 

   [A look at this test run log here will get you better idea on how it actually works](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/docs/TestRun.md)

