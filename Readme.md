# Experiments on the redirecting Azure Instance Metadata Service requests from Docker containers to an external facing proxy Docker container  

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from inside client containers through a dedicated proxy container. 
   
   
   There are two possible approaches:
   
   1. [Port fordwaring](https://github.com/soccerGB/MSIExperiment/tree/master/PortForwardingNat) 
      - available on Windows 1709 
      - support NAT (bridge) network mode 
         
   2. [Proxy policy](https://github.com/soccerGB/MSIExperiment/tree/master/ProxyPolicyL2Bridge) feature
      - a new feature only available on Windows RS4 or later
      - currently limited to L2Bridge netowork mode
      
   
