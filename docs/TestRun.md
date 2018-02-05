
# Container images

      1.	Test container images involved:
      
               C:\github\MSIRequestProxy\pythonOn1709>docker images
               REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
               proxy                         latest              d5db1ac1de23        5 minutes ago       6.57GB
               msiserviceclient              latest              d98b7f1a5331        12 minutes ago      6.29GB
               pythonon1709                  latest              bcf47de890e3        14 minutes ago      6.25GB
               golang                        latest              1002c7d901fc        12 days ago         6.53GB
               microsoft/windowsservercore   1709                0a41f8d5bbff        4 weeks ago         6.09GB
               microsoft/nanoserver          1709                c4f1aa3885f1        4 weeks ago         303MB
               
      2.	How to build test container images:
   
               C:\github\MSIRequestProxy\pythonOn1709> docker build -t pythonon1709 .
               C:\github\MSIRequestProxy\msiserviceclient>docker build -t msiserviceclient .
               C:\github\MSIRequestProxy\proxy>docker build -t msiserviceclient .


      
         - The msiserviceclient container image depends on pythononwindows for setting up a simple http server.

         - Inside the msiserviceclient container image, the following new route added into its routing table 
           as part of the container startup sequence. This is needed for enabling accessing MSI from
           inside the MSIServiceClient container

   - msiserviceclient [Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/msiserviceclient/dockerfile)  

                   All the actual MSI access is done through this container.

   - proxy: [Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/proxy/dockerfile)   

                  The proxy container proxies the MSI requests from all other app containers inside the same subnet.
                  It forwards all the MSI request to the msiserviceclient for the actual MSi operation [Dockerfile]() 

   - pythonrs3:[Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/proxy/dockerfile) 

                  This image is needed for testing purpose only, for helping creaste a simple server 
                  inside the msiserviceclient.[Dockerfile]() 


# Test run

Note: 
   - This test was run inside a Windows agent node of an DC/OS cluster hosted on Azure
   - There is no "Container Monitor Task" in this test run. It was replaced by running two Powershell scripts manually
      ([LocateProxyAndSetEnv.ps1](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/scripts/LocateProxyAndSetEnv.ps1) and [LocateClientAndSetupPortforward.ps1](https://github.com/soccerGB/MSIExperiment/blob/master/PortForwardingNat/scripts/LocateClientAndSetupPortforward.ps1)) 
      at right moments
   - For debugging purpose, the log from below test run has networking config information output 
      


## 1. Launch a proxy container instance with "MSIProxyContainer" as its label
    
         C:\github\MSIExperiment\pf2>docker run -it --label MSIProxyContainer proxy
         
         C:\app>echo "Start running setupproxynet.ps1"
         "Start running setupproxynet.ps1"

         C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"
         gatewayIP = 172.21.192.1
         MSFT_NetRoute (InstanceID = ";@C8???8;@C8???9??55??55;A?8?;8;C?8;55;...)
         MSFT_NetRoute (InstanceID = ";@C8???8;@C8???9??55??55;A?8?;8;C?8;55:...)
         ===========================================================================
         Interface List
         23...........................Software Loopback Interface 2
         24...00 15 5d d6 66 3d ......Hyper-V Virtual Ethernet Adapter #3
         ===========================================================================

         IPv4 Route Table
         ===========================================================================
         Active Routes:
         Network Destination        Netmask          Gateway       Interface  Metric
                 0.0.0.0          0.0.0.0     172.21.192.1    172.21.198.75    756
               127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
               127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
         127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
         169.254.169.254  255.255.255.255     172.21.192.1    172.21.198.75    756
            172.21.192.0    255.255.240.0         On-link     172.21.198.75    756
           172.21.198.75  255.255.255.255         On-link     172.21.198.75    756
          172.21.207.255  255.255.255.255         On-link     172.21.198.75    756
               224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
               224.0.0.0        240.0.0.0         On-link     172.21.198.75    756
         255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
         255.255.255.255  255.255.255.255         On-link     172.21.198.75    756
         ===========================================================================
         Persistent Routes:
         Network Address          Netmask  Gateway Address  Metric
                 0.0.0.0          0.0.0.0     172.21.192.1  Default
         169.254.169.254  255.255.255.255     172.21.192.1  Default
         ===========================================================================
         Testing access to the  Instance Metadata Service from the proxy container
         Invoke-WebRequest -Uri http://169.254.169.254/metadata/instance?api-version=2017-04-02 
                         -Method GET  -Headers System.Collections.Hashtable -UseBasicParsing

         C:\app>echo "Launch a webserver for listing to client container request"
         "Launch a webserver for listing to client container request"

         // a MSI test access from inside the proxy container to make sure it has access to the MSI
         
         C:\app>curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02"
                  {"compute":{"location":"westus2",
                              "name":"wp35723900-vmss_1",
                              "offer":"WindowsServerSemiAnnual",
                              "osType":"Windows",
                              "platformFaultDomain":"1",
                              "platformUpdateDomain":"1",
                              "publisher":"MicrosoftWindowsServer",
                              "sku":"Datacenter-Core-1709-with-Containers-smalldisk",
                              "version":"1709.0.20171219","vmId":"a7c7a8a7-7cdb-4c49-a3a5-d67dc6aa2050",
                              "vmSize":"Standard_D2s_v3"},
                   "network":{"interface":
                                    [{"ipv4":{"ipAddress":[{"privateIpAddress":"10.0.0.5","publicIpAddress":""}],
                              "subnet":[{"address":"10.0.0.0","prefix":"16"}]},
                              "ipv6":{"ipAddress":[]},"macAddress":"000D3AF9AECA"}]}}
                   
         C:\app>ipconfig
         Windows IP Configuration
         Ethernet adapter vEthernet (Ethernet):

          Connection-specific DNS Suffix  . : kqatyr3wm3ielb4nh2ebyxeyvh.xx.internal.cloudapp.net
          Link-local IPv6 Address . . . . . : fe80::9039:bc41:18bc:2e18%24
          IPv4 Address. . . . . . . . . . . : 172.21.198.75
          Subnet Mask . . . . . . . . . . . : 255.255.240.0
          Default Gateway . . . . . . . . . : 172.21.192.1

         C:\app>python .\app.py
         * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
        
## 2. Locate the ProxyContainer's IP address
        
       PS C:\github\MSIExperiment\pf2> .\LocateProxyAndSetEnv.ps1
       
       Searching for the proxy container and set the IMSProxyIpAddress to its ip address if found
       IMSProxyIpAddress is null
       proxyCotnainerName is [clever_heisenberg]
       proxyAddress is [172.21.198.75]
       proxyaddress found is [172.21.198.75]
       set IMSProxyIpAddress=172.21.198.75
       172.21.198.75
       PS C:\github\MSIExperiment\pf2>

## 3. Launch a client container with "ClientContainer[X]" as its label
        
       C:\github\MSIExperiment\pf2>docker run -it --label ClientContainer microsoft/windowsservercore:1709

      ps. You can run repeat step 3 and step 4 for many clients as needed
      
## 4. Locate the ClientContainer's IP address and setup port forwarding configuration
        
       PS C:\github\MSIExperiment\pf2> .\LocateClientAndSetupPortforward.ps1  -ContainerLabel ClientContainer
       
       Client cotnainer name is [quirky_swirles]
       IPAddress is [172.21.201.154]
       Client cotnainer name is [quirky_swirles]
       IMSProxyIpAddress = [172.21.198.75]
       Adding 169.254.169.254 ip address to the container net interface
       interfaceIndex  = 29


       IPAddress         : 169.254.169.254
       InterfaceIndex    : 29
       InterfaceAlias    : vEthernet (Ethernet) 2
       AddressFamily     : IPv4
       Type              : Unicast
       PrefixLength      : 32
       PrefixOrigin      : Manual
       SuffixOrigin      : Manual
       AddressState      : Tentative
       ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
       PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
       SkipAsSource      : False
       PolicyStore       : ActiveStore

       IPAddress         : 169.254.169.254
       InterfaceIndex    : 29
       InterfaceAlias    : vEthernet (Ethernet) 2
       AddressFamily     : IPv4
       Type              : Unicast
       PrefixLength      : 32
       PrefixOrigin      : Manual
       SuffixOrigin      : Manual
       AddressState      : Invalid
       ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
       PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
       SkipAsSource      : False
       PolicyStore       : PersistentStore
       ===========================================================================
       Interface List
        28...........................Software Loopback Interface 3
        29...00 15 5d d6 62 1b ......Hyper-V Virtual Ethernet Adapter #4
       ===========================================================================
       IPv4 Route Table
       ===========================================================================
       Active Routes:
       Network Destination        Netmask          Gateway       Interface  Metric
                 0.0.0.0          0.0.0.0     172.21.192.1   172.21.201.154    756
               127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
               127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
         127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
            172.21.192.0    255.255.240.0         On-link    172.21.201.154    756
          172.21.201.154  255.255.255.255         On-link    172.21.201.154    756
          172.21.207.255  255.255.255.255         On-link    172.21.201.154    756
               224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
               224.0.0.0        240.0.0.0         On-link    172.21.201.154    756
         255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
         255.255.255.255  255.255.255.255         On-link    172.21.201.154    756
       ===========================================================================
       Persistent Routes:
         Network Address          Netmask  Gateway Address  Metric
                 0.0.0.0          0.0.0.0     172.21.192.1  Default
         169.254.169.254  255.255.255.255     172.21.192.1  Default
                 0.0.0.0          0.0.0.0     172.21.192.1  Default
       ===========================================================================
       wait for the network setting to be ready for use...
       Setup port forwarding

       Done!
       Inside the client contianer (quirky_swirles), you can exercise the following command to get MSI data
       $headers=@{}
       $headers["Metadata"] = "True"
       Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -Headers $headers -UseBasicParsing
       PS C:\github\MSIExperiment\pf2>
 
### From inside a client container:
    
     Any requests target for http://169.254.169.254 will be forwarded to the proxycontainer, which will return  
     the MSI metadata back the requesting container once it's recieved from the MSI service

       C:\>powershell
       Windows PowerShell
       Copyright (C) Microsoft Corporation. All rights reserved.

       PS C:\> $headers=@{}
       PS C:\> $headers["Metadata"] = "True"
       PS C:\> Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -Headers $headers -UseBasicParsing

       StatusCode        : 200
       StatusDescription : OK
       Content           : {"compute":
                                {"location":"westus2",
                                 "name":"wp35723900-vmss_1",
                                  "offer":"WindowsServerSemiAnnual",
                                  "osType":"Windows",
                                  "platformFaultDomain":"1",
                                  "platformUpdateDomain":"1",
                                  "publisher":"MicrosoftWindowsServe...
       RawContent        : HTTP/1.0 200 OK
                           Content-Length: 564
                           Content-Type: text/html; charset=utf-8
                           Date: Sun, 28 Jan 2018 08:32:14 GMT
                           Server: Werkzeug/0.14.1 Python/3.7.0a2

                           {"compute":{"location":"westus2","name":"wp...
       Forms             :
       Headers           : {[Content-Length, 564], [Content-Type, text/html; charset=utf-8], 
                          [Date, Sun, 28 Jan 2018 08:32:14 GMT],
                           [Server, Werkzeug/0.14.1 Python/3.7.0a2]}
       Images            : {}
       InputFields       : {}
       Links             : {}
       ParsedHtml        :
       RawContentLength  : 564

                
### From inside the proxy container:

      From the logging spewed out from the simple webserver, it shows its gettings MSI requests 
      forwarded to it from 172.21.201.154, which is the ip address assigned to the client container in this test run

       C:\app>python .\app.py
       * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
       client request connecting...
       retrun from 169.254.169.254 endpoint ...
       172.21.201.154 - - [28/Jan/2018 08:32:14] "GET / HTTP/1.1" 200 -
