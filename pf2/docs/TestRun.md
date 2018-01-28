
# Test container images involved

   There are 5 images involved.

      1. Windows RS3 (build 1709) images:
            microsoft/windowsservercore:1709
            microsoft/nanoserver:1709

      2. Windows test images:
            
      -  msitest/test:clientcontainer

                    All 169.254.169.254:80 requests got forwarded to the proxycontainer(see net.ps1)

      - msitest/test:proxycontainer

                     In reponse to metadate quests from client continers. the proxycontainer accesses 
                     the Instance Metadat Service on behalf of client containers

      - msitest/test:pythonwindow1709
            
For test images, you can use above prebuilt images or build from the source [test cotnainer images build instructions](https://github.com/soccerGB/MSIExperiment/blob/master/docs/HowToBuildTestContainer.md)

# How to run this test

Inside an VM that has access to Azure's Instance Metadata Service:

- Pull images

               docker pull msitest/test:pythonwindow1709
               docker pull msitest/test:proxycontainer
               docker pull msitest/test:clientcontainer
      
- Launch proxy container

      docker run -it --label MSIProxyContainer msitest/test:proxycontainer
      
      ps. Run with MSIProxyContainer label on the proxycontainer for helping locate proxy container in a slave node

- In the agent node, locate the ip address of the proxy container and set it to a environment variable, IMSProxyIpAddress
     
     (For prototyping purpose, I remote-desktop-ed into the agnent node, and run a powershell to do set the proxyaddress as an environment. this step is hacky, I still need to find a graceful way to pass this address to the client container)

      PS C:\MSIExperiment> .\LocateProxyAndSetEnv.ps1
      Searching for the proxy container and set the IMSProxyIpAddress to its ip address if found
      IMSProxyIpAddress is null
      proxyCotnainerName is [festive_poitras]
      proxyAddress is [172.24.43.111]
      proxyaddress found is [172.24.43.111]
      172.24.43.111
      PS C:\MSIExperiment>

      PS C:\MSIExperiment> set IMSProxyIpAddress=172.24.43.111
      
- Launch client container

   docker run -it -e IMSProxyIpAddress msitest/test:clientcontainer
   
       ps. Pass the IMSProxyIpAddress environment variable to clientcontainer instances for port forwarding purpose

## Logging for an example run
        1. Launch a proxy container instance with "MSIProxyContainer" as label
        
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

                C:\app>curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02"
                {"compute":{"location":"westus2",
                "name":"wp35723900-vmss_1","offer":"WindowsServerSemiAnnual","osType":"Windows",
                "platformFaultDomain":"1","platformUpdateDomain":"1",
                "publisher":"MicrosoftWindowsServer",
                "sku":"Datacenter-Core-1709-with-Containers-smalldisk"
                ,"version":"1709.0.20171219","vmId":"a7c7a8a7-7cdb-4c49-a3a5-d67dc6aa2050",
                "vmSize":"Standard_D2s_v3"},
                "network":{"interface":[{"ipv4":{"ipAddress":[{"privateIpAddress":"10.0.0.5","publicIpAddress":""}],
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

                C:\app>echo " Run the following commands into each client
                " Run the following commands into each client

                C:\app>echo " $ifIndex = get-netadapter | select -expand ifIndex "
                " $ifIndex = get-netadapter | select -expand ifIndex "

                C:\app>echo " New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254
                " New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254

                C:\app>echo " Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 
                listenport=80 connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp"
                " Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 
                connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp"

                C:\app>python .\app.py
                 * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
        
        2.Locate the ProxyContainer's IP address and setup environment variable:
        
                PS C:\github\MSIExperiment\pf2> .\LocateProxyAndSetEnv.ps1
                Searching for the proxy container and set the IMSProxyIpAddress to its ip address if found
                IMSProxyIpAddress is null
                proxyCotnainerName is [clever_heisenberg]
                proxyAddress is [172.21.198.75]
                proxyaddress found is [172.21.198.75]
                set IMSProxyIpAddress=172.21.198.75
                172.21.198.75
                PS C:\github\MSIExperiment\pf2>

        3.  Launch a client container with "ClientContainer" as label
        
                C:\github\MSIExperiment\pf2>docker run -it --label ClientContainer microsoft/windowsservercore:1709

     
        4.  Locate the ClientContainer's IP address and setup port forwarding:
        
                PS C:\github\MSIExperiment\pf2> .\LocateClientAndSetupPortforward.ps1
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


        
        
  5. From inside a client container, any request for http://169.254.169.254 will be forwarded to the proxycontainer 
     for getting MSI metadata before returning back to the client
  
      - From inside a client container:
     
                C:\>powershell
                Windows PowerShell
                Copyright (C) Microsoft Corporation. All rights reserved.

                PS C:\> $headers=@{}
                PS C:\> $headers["Metadata"] = "True"
                PS C:\> Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -Headers $headers -UseBasicParsing


                StatusCode        : 200
                StatusDescription : OK
                Content           : {"compute":{"location":"westus2","name":"wp35723900-vmss_1","offer":"WindowsServerSemiAnnual","osType":"Win
                                    dows","platformFaultDomain":"1","platformUpdateDomain":"1",
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

      - From inside the proxy container:

                 C:\app>python .\app.py
                 * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
                client request connecting...
                retrun from 169.254.169.254 endpoint ...
                172.21.201.154 - - [28/Jan/2018 08:32:14] "GET / HTTP/1.1" 200 -
