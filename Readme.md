
# Proxying MSI requests inside a DC/OS's Windows agent node on Azure 

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from app containers through a dedicated proxy container. The experiment below shows this can be done with appropriate request forwading and routing setup on a DC/OS Windows agent node running WindowsServerCore:1709 build. 

![Block diagram for Proxying Instance Metadata Service request](https://github.com/soccerGB/MSIRequestProxy/blob/master/docs/InstanceMetadata.png "Proxying Instance Metadata Service request")


Note: 
- The ProxyContainer handles all the MSI requests on behalf app containers 
- The MSIServiceClient container plays a similiar role like [iam-docker](https://github.com/swipely/iam-docker) used in an EC2 instance except both client containers and the proxycontainer are in the same subnet, except it's a simplified version , it only focuses on the Windows specific setup needed in an Windows VM under Azure environment for the MSI proxying to work, that is, the additional setup discussed here needed to be added add on top of a component with similiar functinoality like iam-docker for the whole end-to-end scenario to work in production.

## How it works

![Detailed interaction diagramt](https://github.com/soccerGB/MSIRequestProxy/blob/master/docs/DetailedMSIPortforwardingComponents.png "Proxying Instance Metadata Service request")

ps.Color blocks are new components

Here is the operation sequence:

   
   1.	Launch an MSIServiceClient container instance with MSIServiceClient as its label
   
            docker run -it --label  MSIServiceClient msiserviceclient
            
            Note:  Inside the msiserviceclient container image, the following new route added into its routing table 
                   as part of the container startup sequence. This is needed for enabling accessing MSI from
                   inside the MSIServiceClient container
                   New-NetRoute –DestinationPrefix "169.254.169.254/32" –InterfaceIndex $ifIndex –NextHop $gatewayIP
             
   2.	Launch the Proxy container instance with MSIProxyContainer as its label

            docker run -it --label MSIProxyContainer proxy
         
   3. Schedule a gloabl task to setup the MSI request forwarding 
   
            This is a long running task, it jobs is to locate the MSIServiceClient container's ip addess before 
            using it to set up the MSI request forwarding configuration. This configuration is done remotely via 
            "docker exec" command into the ProxyContainer container instance 
         
  4.	Launch app containers
  
         Example:
         docker run -d microsoft/windowsservercore:1709 cmd     
     
  5.	MSI requests were sent from inside an app ontainer 
         
  6.  MSI requests got forwarded to the Proxy Container, which in turn sends them to the MSIServiceClient container for making 
      requests to through the MSI VM Extension to get the actual MSI metadata before returning the result back to the requesting
      clientcontainer
      
   Design considerations:
      
   Remark:
   
     1. All those MSI requests happen all behind the scene without the knowledge those app containers. That is, 
        there is no need to modify any participating app containers making MSI requests.
     2. The Proxy container needs to be aware of the IP address of and the MSIServiceClient container for it to
        forward those proxied MSI requests. In the case that the MSIServiceClient container crashes and restarted,
        we would need to reconfigure Proxy contaier's forwarding destination for the proxying to get back to working
        state. Once it's reconfigured, the MSI metadata will become avaiable to the app containers without the need 
        to restart them. 
     3. In the case, the Proxy container is crashed or lost, it would have to be relaunch and reconfiured 
        (like above case 2) for the proxying to be functioning again.
     4. It's likely to pick a fixed known ip address (such as x.x.x.2) inside a subnet, which would simplify the 
        confgure/reconfigure process. It might be tricky to channel this known ip address from a DC/OS service task
     5. In the case that, either the Proxy container or the MSIServiceClient container is unable to resume, the 
        MSI service will become unavailable to any app containers. This is the behavior in this prototype. 
      
   - Pros:
      - Fits well into DC/OS Mesos’s Docker Containerizer model     
      - This approach requires no additional logics added for into the app container image code      
      - Both the Proxy container and the MSIServiceClient are in the same subnet as all app containers requesting MSI 
        metadata
      - Does not depend particular version of Windows
      
   - Cons:
      - Required configuration operations outside of containers:
        the additon of the "Global task" for configuring the MSI request forwarding, which is needed to workaround the 
        existing Windows routing limitation - it does not support the Linux iptable routing feature used in [docker-iam project](https://github.com/swipely/iam-docker) : (rerouting all traffics with specifc dest IP from a NAT to a specific net interface)
      
## An example test run 

   [A look at this test run log here will get you better idea on how it actually works](https://github.com/soccerGB/MSIRequestProxy/blob/master/docs/TestRun.md)

