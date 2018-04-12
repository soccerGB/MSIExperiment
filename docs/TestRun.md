
# Container images

# Test container images involved:
      
      PS C:\> docker images
      REPOSITORY                            TAG                 IMAGE ID            CREATED             SIZE
      msiserviceclient                      latest              946c20ad23c4        2 minutes ago       3.8GB
      python-windows-rs4-insider            latest              8e19e8442def        4 minutes ago       3.79GB
      proxy                                 latest              ca571384fda9        8 minutes ago       4.01GB
      golang-windows-rs4-insider            latest              da708fd0e299        9 minutes ago       4GB
      microsoft/windowsservercore-insider   latest              cfe539d8e1b2        7 days ago          3.68GB
      microsoft/nanoserver-insider          latest              cf1b1fc82be8        7 days ago          231MB         
         
               
# How to build test container images:
   
   - msiserviceclient [Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/msiserviceclient/dockerfile)  

            C:\github\MSIRequestProxy\msiserviceclient>docker build -t msiserviceclient .

            All the actual MSI access is done through this container.
            The msiserviceclient container image depends on pythononwindows for setting up a simple http server.
            Inside the msiserviceclient container image, the following new route added into its routing table 
            as part of the container startup sequence. This is needed for enabling accessing MSI from inside the
            MSIServiceClient container             

   - proxy: [Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/proxy/dockerfile)  
   
            C:\github\MSIRequestProxy\proxy>docker build -t proxy .
         
            The proxy container proxies the MSI requests from all other app containers inside the same subnet.
            It forwards all the MSI request to the msiserviceclient for the actual MSi operation [Dockerfile]() 

   - python-windows-rs4-insider:[Dockerfile](https://github.com/soccerGB/MSIRequestProxy/blob/master/pythonOnRS4/dockerfile) 
   
            C:\github\MSIRequestProxy\pythonOnRS4> docker build -t python-windows-rs4-insider .

            This image is needed for testing purpose only, for helping creaste a simple server 
            inside the msiserviceclient.[Dockerfile]() 


# Test run

Note: 
   - This test was run inside a Windows agent node of an DC/OS cluster hosted on Azure
   - There is no "Container Monitor Task" in this test run. It was replaced by running two Powershell scripts manually
      ([SetupMSIProxy.ps1](https://github.com/soccerGB/MSIRequestProxy/blob/master/scripts/SetupMSIProxy.ps1)
   - For debugging purpose, the log from below test run has networking config information output 
      

## 1. Launch a msiserviceclient instance with "MSIServiceClientContainer" as its label
    
            New a cmd window:
            
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

            New a cmd window:
            
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
        
            New a Powershell cmd window:
            
            PS C:\github\MSIRequestProxy\scripts> .\SetupMSIProxy.ps1
            Searching for a cotnainer with [MSIProxyContainer] label
            Found: [adoring_goldstine]
            with ip address = [172.22.235.64]
            proxyContainer: name([adoring_goldstine]) ipaddress([172.22.235.64])
            Searching for a cotnainer with [MSIServiceClientContainer] label
            Found: [gallant_kowalevski]
            with ip address = [172.22.230.199]
            MSIServiceContainer: name([gallant_kowalevski]) ipaddress([172.22.230.199])
            docker exec adoring_goldstine c:\app\proxy -proxyip 172.22.230.199:80
            init() called
            proxyip is
            Utiltiy container is running!
            server will run on : %v:%v
             169.254.169.254 80
            redirecting to : 172.22.230.199:80
            backendServiceIpPort :%s
             http://172.22.230.199:80
            Waiting for new connection resuest:

            
            
Note . In this test run, manually running SetupMSIProxy.ps1 was used to replace 
         "Schedule a gloabl task to setup the MSI request forwarding" step in the Readme.md

## 4. Run any number of app containers

   eg:   Let run two app containers as follows
   
      App container 1:

      New a cmd window:
      
      PS C:\> docker run -it microsoft/windowsservercore-insider cmd
      Microsoft Windows [Version 10.0.17133.1]
      (c) 2018 Microsoft Corporation. All rights reserved.

      C:\>ipconfig
      Windows IP Configuration
      Ethernet adapter vEthernet (Ethernet) 3:
         Connection-specific DNS Suffix  . : w34qrs0grtuexhf54ugtziktnf.xx.internal.cloudapp.net
         Link-local IPv6 Address . . . . . : fe80::f8d9:14f6:71f8:be6a%35
         IPv4 Address. . . . . . . . . . . : 172.22.225.58
         Subnet Mask . . . . . . . . . . . : 255.255.240.0
         Default Gateway . . . . . . . . . : 172.22.224.1

         
      App container 2:  
      
      New a cmd window:
      C:\>docker run -it microsoft/windowsservercore-insider cmd
      Microsoft Windows [Version 10.0.17133.1]
      (c) 2018 Microsoft Corporation. All rights reserved.

      C:\>ipconfig

      Windows IP Configuration


      Ethernet adapter vEthernet (Ethernet) 4:

         Connection-specific DNS Suffix  . : w34qrs0grtuexhf54ugtziktnf.xx.internal.cloudapp.net
         Link-local IPv6 Address . . . . . : fe80::5040:4148:9727:5076%40
         IPv4 Address. . . . . . . . . . . : 172.22.225.15
         Subnet Mask . . . . . . . . . . . : 255.255.240.0
         Default Gateway . . . . . . . . . : 172.22.224.1

 
## 5. Querying MSI metadata from app containers

      Accessing MSI data from inside the container 1:
      
      C:\>curl -H Metadata:true "http://169.254.169.254"
      {
            "compute":{
                  "location":"westus2",
                  "name":"wp41724900-vmss_1",
                  "offer":"",
                  "osType":"Windows",
                  "platformFaultDomain":"1",
                  "platformUpdateDomain":"1",
                  "publisher":"",
                  "sku":"",
                  "version":"",
                  "vmId":"c4f95933-e5bd-495f-8fa1-0a6a30d32063",
                  "vmSize":"Standard_D2s_v3"}
                   },
              "network":{
                  "interface":[{"ipv4":{
                                    "ipAddress":[{"privateIpAddress":"10.0.0.5","publicIpAddress":""}],
                                    "subnet":[{"address":"10.0.0.0", "prefix":"16"}]},
                              "ipv6":{"ipAddress":[]},
                              "macAddress":"000D3AF9FA3B"}]
                  }
      }

      Accessing MSI data from inside the container 2:
      

      C:\>curl -H Metadata:true "http://169.254.169.254"
      {
               "compute":{
                  "location":"westus2",
                  "name":"wp41724900-vmss_1",
                  "offer":"",
                  "osType":"Windows",
                  "platformFaultDomain":"1",
                  "platformUpdateDomain":"1",
                  "publisher":"","sku":"",
                  "version":"",
                  "vmId":"c4f95933-e5bd-495f-8fa1-0a6a30d32063",
                  "vmSize":"Standard_D2s_v3"
                  },
                  
                  "network":{
                        "interface":[{"ipv4":{
                                               "ipAddress":[{"privateIpAddress":"10.0.0.5","publicIpAddress":""}],
                                                "subnet":[{"address":"10.0.0.0","prefix":"16"}]},
                                    "ipv6":{"ipAddress":[]},
                                    "macAddress":"000D3AF9FA3B"}]
                             }
      }
  



     The following logging from the MSIServiceClient container showing the MSI requests were acutally proxied
     through the Proxy container (172.23.22.222). The app container's ip addresses could also be seen inside the 
     MSIServiceClient container.

    Output from inside the MSIServiceCLient container:
  
       * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
      HTTP request: from client:172.22.225.15  -------------------------> this is ip address of the container 1
      returned from 169.254.169.25 endpoint ...
      172.22.235.64 - - [12/Apr/2018 02:48:29] "GET / HTTP/1.1" 200 -
      HTTP request: from client:172.22.225.58 -------------------------> this is ip address of the container 2
      returned from 169.254.169.254 endpoint ...
      172.22.235.64 - - [12/Apr/2018 02:52:18] "GET / HTTP/1.1" 200 -


                

