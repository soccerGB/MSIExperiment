
# Container images

# Test container images involved:
      
         C:\github\MSIRequestProxy\pythonOn1709>docker images
         REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
         proxy                         latest              d5db1ac1de23        5 minutes ago       6.57GB
         msiserviceclient              latest              d98b7f1a5331        12 minutes ago      6.29GB
         pythonon1709                  latest              bcf47de890e3        14 minutes ago      6.25GB
         golang                        latest              1002c7d901fc        12 days ago         6.53GB
         microsoft/windowsservercore   1709                0a41f8d5bbff        4 weeks ago         6.09GB
         microsoft/nanoserver          1709                c4f1aa3885f1        4 weeks ago         303MB
               
# How to build test container images:
   
   - msiserviceclient [Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/msiserviceclient/dockerfile)  

            C:\github\MSIRequestProxy\msiserviceclient>docker build -t msiserviceclient .

            All the actual MSI access is done through this container.
            The msiserviceclient container image depends on pythononwindows for setting up a simple http server.
            Inside the msiserviceclient container image, the following new route added into its routing table 
            as part of the container startup sequence. This is needed for enabling accessing MSI from inside the
            MSIServiceClient container             

   - proxy: [Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/proxy/dockerfile)  
   
            C:\github\MSIRequestProxy\proxy>docker build -t msiserviceclient .
         
            The proxy container proxies the MSI requests from all other app containers inside the same subnet.
            It forwards all the MSI request to the msiserviceclient for the actual MSi operation [Dockerfile]() 

   - pythonrs3:[Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/pythonOn1709/dockerfile) 
   
            C:\github\MSIRequestProxy\pythonOn1709> docker build -t pythonon1709 .

            This image is needed for testing purpose only, for helping creaste a simple server 
            inside the msiserviceclient.[Dockerfile]() 


# Test run

Note: 
   - This test was run inside a Windows agent node of an DC/OS cluster hosted on Azure
   - There is no "Container Monitor Task" in this test run. It was replaced by running two Powershell scripts manually
      ([LocateProxyAndSetEnv.ps1](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/scripts/LocateProxyAndSetEnv.ps1) and [LocateClientAndSetupPortforward.ps1](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/scripts/LocateClientAndSetupPortforward.ps1)) 
      at right moments
   - For debugging purpose, the log from below test run has networking config information output 
      


## 1. Launch a msiserviceclient instance with "MSIServiceClientContainer" as its label
    
            C:\github\MSIRequestProxy\msiserviceclient>docker run -it --label MSIServiceClientContainer msiserviceclient

            C:\app>echo "Start running setupproxynet.ps1"
            "Start running setupproxynet.ps1"

            C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"
            gatewayIP = 172.23.16.1
            MSFT_NetRoute (InstanceID = ";@C8???8;@C8???9??55?@55;A?8??8;@8;55;")
            MSFT_NetRoute (InstanceID = ";@C8???8;@C8???9??55?@55;A?8??8;@8;55:")
            ===========================================================================
            Interface List
             25...........................Software Loopback Interface 4
             26...00 15 5d ad 36 8f ......Hyper-V Virtual Ethernet Adapter #4
            ===========================================================================

            IPv4 Route Table
            ===========================================================================
            Active Routes:
            Network Destination        Netmask          Gateway       Interface  Metric
                      0.0.0.0          0.0.0.0      172.23.16.1     172.23.16.46    756
                    127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
                    127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
              127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
              169.254.169.254  255.255.255.255      172.23.16.1     172.23.16.46    756
                  172.23.16.0    255.255.240.0         On-link      172.23.16.46    756
                 172.23.16.46  255.255.255.255         On-link      172.23.16.46    756
                172.23.31.255  255.255.255.255         On-link      172.23.16.46    756
                    224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
                    224.0.0.0        240.0.0.0         On-link      172.23.16.46    756
              255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
              255.255.255.255  255.255.255.255         On-link      172.23.16.46    756
            ===========================================================================
            Persistent Routes:
              Network Address          Netmask  Gateway Address  Metric
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
              169.254.169.254  255.255.255.255      172.23.16.1  Default
            ===========================================================================

            C:\app>REM the followign lines are debugging prupose
            C:\app>ipconfig
            Windows IP Configuration
            Ethernet adapter vEthernet (Ethernet) 3:
               Connection-specific DNS Suffix  . : 0u4ybne0y4fu5ohbuybmvnje0h.xx.internal.cloudapp.net
               Link-local IPv6 Address . . . . . : fe80::4d1f:336:2101:6b78%26
               IPv4 Address. . . . . . . . . . . : 172.23.16.46
               Subnet Mask . . . . . . . . . . . : 255.255.240.0
               Default Gateway . . . . . . . . . : 172.23.16.1

            C:\app>python .\app.py
             * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
            HTTP request: from client:172.23.27.67
            returned from 169.254.169.254 endpoint ...
            172.23.22.222 - - [05/Feb/2018 21:22:25] "GET / HTTP/1.1" 200 -
            HTTP request: from client:172.23.17.4
            returned from 169.254.169.254 endpoint ...
            172.23.22.222 - - [05/Feb/2018 21:22:33] "GET / HTTP/1.1" 200 -
        
## 2. Launch a Proxy container instance with MSIProxyContainer as its label

            C:\github\MSIRequestProxy\proxy>docker run -it --label MSIProxyContainer proxy

            C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\addnewnetip.ps1'"
            Adding 169.254.169.254 to network interface
            ...

            Windows IP Configuration
            Ethernet adapter vEthernet (Ethernet) 4:
               Connection-specific DNS Suffix  . : 0u4ybne0y4fu5ohbuybmvnje0h.xx.internal.cloudapp.net
               Link-local IPv6 Address . . . . . : fe80::9528:6667:3fa1:c42d%31
               IPv4 Address. . . . . . . . . . . : 172.23.22.222
               Subnet Mask . . . . . . . . . . . : 255.255.240.0
               Default Gateway . . . . . . . . . : 172.23.16.1
            wait for the network setting to be ready for use...

            C:\app>route print -4
            ===========================================================================
            Interface List
             30...........................Software Loopback Interface 5
             31...00 15 5d ad 31 c9 ......Hyper-V Virtual Ethernet Adapter #5
            ===========================================================================

            IPv4 Route Table
            ===========================================================================
            Active Routes:
            Network Destination        Netmask          Gateway       Interface  Metric
                      0.0.0.0          0.0.0.0      172.23.16.1    172.23.22.222    756
                    127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
                    127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
              127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
              169.254.169.254  255.255.255.255         On-link     172.23.22.222    756
                  172.23.16.0    255.255.240.0         On-link     172.23.22.222    756
                172.23.22.222  255.255.255.255         On-link     172.23.22.222    756
                172.23.31.255  255.255.255.255         On-link     172.23.22.222    756
                    224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
                    224.0.0.0        240.0.0.0         On-link     172.23.22.222    756
              255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
              255.255.255.255  255.255.255.255         On-link     172.23.22.222    756
            ===========================================================================
            Persistent Routes:
              Network Address          Netmask  Gateway Address  Metric
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
              169.254.169.254  255.255.255.255      172.23.16.1  Default
                      0.0.0.0          0.0.0.0      172.23.16.1  Default
            ===========================================================================

## 3. Run SetupMSIProxy.ps1 to set the proxy container's forwarding target (MSIServiceClient container instance)
        
            PS C:\github\MSIRequestProxy\scripts> .\SetupMSIProxy.ps1
            Searching for a cotnainer with [MSIProxyContainer] label
            Found: [wizardly_goldberg]
            with ip address = [172.23.22.222]
            proxyContainer: name([wizardly_goldberg]) ipaddress([172.23.22.222])
            Searching for a cotnainer with [MSIServiceClientContainer] label
            Found: [elated_stonebraker]
            with ip address = [172.23.16.46]
            MSIServiceContainer: name([elated_stonebraker]) ipaddress([172.23.16.46])
            docker exec wizardly_goldberg c:\app\proxy -proxyip 172.23.16.46:80
            ....
            
            
Note . In this test run, manually running SetupMSIProxy.ps1 was used to replace 
         "Schedule a gloabl task to setup the MSI request forwarding" step in the Readme.md

## 4. Run any number of app containers

   eg:   Let run two app containers as follows
   
      App container 1:
      
      C:\>docker run -it microsoft/windowsservercore:1709 cmd
      Microsoft Windows [Version 10.0.16299.192]
      (c) 2017 Microsoft Corporation. All rights reserved.

      C:\>ipconfig
      Windows IP Configuration
      Ethernet adapter vEthernet (Ethernet) 2:

         Connection-specific DNS Suffix  . : 0u4ybne0y4fu5ohbuybmvnje0h.xx.internal.cloudapp.net
         Link-local IPv6 Address . . . . . : fe80::6922:e220:2568:f74e%21
         IPv4 Address. . . . . . . . . . . : 172.23.17.4
         Subnet Mask . . . . . . . . . . . : 255.255.240.0
         Default Gateway . . . . . . . . . : 172.23.16.1
         
      App container 2:     
      C:\>docker run -it microsoft/windowsservercore:1709 cmd
      Microsoft Windows [Version 10.0.16299.192]
      (c) 2017 Microsoft Corporation. All rights reserved.

      C:\>ipconfig      
        Windows IP Configuration
        Ethernet adapter vEthernet (Ethernet):

         Connection-specific DNS Suffix  . : 0u4ybne0y4fu5ohbuybmvnje0h.xx.internal.cloudapp.net
         Link-local IPv6 Address . . . . . : fe80::8133:60f3:472c:e8f8%16
         IPv4 Address. . . . . . . . . . . : 172.23.27.67
         Subnet Mask . . . . . . . . . . . : 255.255.240.0
         Default Gateway . . . . . . . . . : 172.23.16.1

 
## 5. ready for querying MSI metadata from app containers

      Inside an app container:
      
      C:\>curl -H Metadata:true "http://169.254.169.254"
            {"compute":
                  {"location":"westus2",
                  "name":"wp27499900-vmss_0",
                  "offer":"WindowsServerSemiAnnual",
                  "osType":"Windows",
                  "platformFaultDomain":"0",
                  "platformUpdateDomain":"0",
                  "publisher":"MicrosoftWindowsServer",
                  "sku":"Datacenter-Core-1709-with-Containers-smalldisk",
                  "version":"1709.0.20171219",
                  "vmId":"1a03b159-571f-4d78-bc5a-f5f7df6d0637",
                  "vmSize":"Standard_D2s_v3"},
              "network"
                  :{"interface":[{"ipv4":
                  {"ipAddress":[{"privateIpAddress":"10.0.0.4","publicIpAddress":""}],
                  "subnet":[{"address":"10.0.0.0","prefix":"16"}]},
                  "ipv6":{"ipAddress":[]},"macAddress":"000D3AFDB2EC"}]}}

     The following logging from the MSIServiceClient container showing the MSI requests were acutally proxied
     through the Proxy container (172.23.22.222). The app container's ip addresses could also be seen inside the 
     MSIServiceClient container.

    From inside the MSIServiceCLient container:
  
       * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
      HTTP request: from client:172.23.27.67 ----------------------------------> this is the app1  container's ip
      returned from 169.254.169.254 endpoint ...
      172.23.22.222 - - [05/Feb/2018 21:22:25] "GET / HTTP/1.1" 200 -  --------> 172.23.22.222 is the Proxy container' ip
      HTTP request: from client:172.23.17.4  ----------------------------------> this is the app2  container's ip
      returned from 169.254.169.254 endpoint ...
      172.23.22.222 - - [05/Feb/2018 21:22:33] "GET / HTTP/1.1" 200 -


                

