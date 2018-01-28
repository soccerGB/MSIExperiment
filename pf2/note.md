        
        1. Launch a proxy container instance
        
                C:\github\MSIExperiment\pf2\proxy>docker run -it --label MSIProxyContainer proxy
                          
               Windows IP Configuration


                Ethernet adapter vEthernet (Ethernet):

                   Connection-specific DNS Suffix  . : kqatyr3wm3ielb4nh2ebyxeyvh.xx.internal.cloudapp.net
                   Link-local IPv6 Address . . . . . : fe80::848e:ca18:2082:7186%24
                   IPv4 Address. . . . . . . . . . . : 172.21.193.97
                   Subnet Mask . . . . . . . . . . . : 255.255.240.0
                   Default Gateway . . . . . . . . . : 172.21.192.1
 
                C:\app>curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02"
                {"compute":{"location":"westus2","name":"wp35723900-vmss_1","offer":"WindowsServerSemiAnnual","osType":"Windows","platformFaultDomain":"1",
                "platformUpdateDomain":"1","publisher":"MicrosoftWindowsServer","sku":"Datacenter-Core-1709-with-Containers-smalldisk",
                "version":"1709.0.20171219","vmId":"a7c7a8a7-7cdb-4c49-a3a5-d67dc6aa2050","vmSize":"Standard_D2s_v3"},
                "network":{"interface":[{"ipv4":{"ipAddress":[{"privateIpAddress":"10.0.0.5","publicIpAddress":""}],
                "subnet":[{"address":"10.0.0.0","prefix":"16"}]},"ipv6":{"ipAddress":[]},"macAddress":"000D3AF9AECA"}]}}
        
        2.  Launch a client container with "ClientContainer" as label
        
                C:\github\MSIExperiment\pf2>docker run -it --label ClientContainer microsoft/windowsservercore:1709
        
        3.  Locate the ClientContainer's IP address and setup port forwarding:
        
                PS C:\github\MSIExperiment\pf2> .\LocateProxyAndSetEnv.ps1
                Searching for the proxy container and set the IMSProxyIpAddress to its ip address if found
                IMSProxyIpAddress is null
                proxyCotnainerName is [naughty_bose]
                proxyAddress is [172.21.192.224]
                proxyaddress found is [172.21.192.224]
                set IMSProxyIpAddress=172.21.192.224
                172.21.192.224
                PS C:\github\MSIExperiment\pf2>
      
        4.  Locate the ClientContainer's IP address and setup port forwarding:
        
                PS C:\github\MSIExperiment\pf2> .\LocateClientAndSetupPortforward.ps1
                Client cotnainer name is [heuristic_wright]
                IPAddress is [172.21.200.114]
                Client cotnainer name is [heuristic_wright]
                IMSProxyIpAddress = [172.21.192.224]
                Adding 169.254.169.254 ip address to the container net interface
                interfaceIndex  = 29
                New-NetIPAddress : Instance MSFT_NetIPAddress already exists
                At line:1 char:1
                + New-NetIPAddress -InterfaceIndex 29 -IPAddress 169.254.169.254
                + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    + CategoryInfo          : InvalidArgument: (MSFT_NetIPAddress:ROOT/Standar
                   dCimv2/MSFT_NetIPAddress) [New-NetIPAddress], CimException
                    + FullyQualifiedErrorId : Windows System Error 87,New-NetIPAddress

                ===========================================================================
                Interface List
                 28...........................Software Loopback Interface 3
                 29...00 15 5d d6 69 ae ......Hyper-V Virtual Ethernet Adapter #4
                ===========================================================================

                IPv4 Route Table
                ===========================================================================
                Active Routes:
                Network Destination        Netmask          Gateway       Interface  Metric
                          0.0.0.0          0.0.0.0     172.21.192.1   172.21.200.114    756
                        127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
                        127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
                  127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
                  169.254.169.254  255.255.255.255         On-link    172.21.200.114    756
                     172.21.192.0    255.255.240.0         On-link    172.21.200.114    756
                   172.21.200.114  255.255.255.255         On-link    172.21.200.114    756
                   172.21.207.255  255.255.255.255         On-link    172.21.200.114    756
                        224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
                        224.0.0.0        240.0.0.0         On-link    172.21.200.114    756
                  255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
                  255.255.255.255  255.255.255.255         On-link    172.21.200.114    756
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
                Inside the client contianer (heuristic_wright), you can exercise the following command to get MSI data
                $headers=@{}
                $headers["Metadata"] = "True"
                Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -Headers $headers -UseBasicParsing
                PS C:\github\MSIExperiment\pf2>

        
        
  5. From inside a client container, any request for http://169.254.169.254 will be forwarded to the proxycontainer for getting MSI metadata before returning back to the client
  
      - From inside a client container:
     
                PS C:\> $headers=@{}
                PS C:\> $headers["Metadata"] = "True"

                PS C:\> Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -Headers $headers -UseBasicParsing


                StatusCode        : 200
                StatusDescription : OK
                Content           : {"compute":{"location":"westus2","name":"wp35723900-vmss_1","offer":"WindowsServerSemiAnnual","osType":"Win
                                    dows","platformFaultDomain":"1","platformUpdateDomain":"1","publisher":"MicrosoftWindowsServe...
                RawContent        : HTTP/1.0 200 OK
                                    Content-Length: 564
                                    Content-Type: text/html; charset=utf-8
                                    Date: Sun, 28 Jan 2018 08:03:50 GMT
                                    Server: Werkzeug/0.14.1 Python/3.7.0a2

                                    {"compute":{"location":"westus2","name":"wp...
                Forms             :
                Headers           : {[Content-Length, 564], [Content-Type, text/html; charset=utf-8], [Date, Sun, 28 Jan 2018 08:03:50 GMT],
                                    [Server, Werkzeug/0.14.1 Python/3.7.0a2]}
                Images            : {}
                InputFields       : {}
                Links             : {}
                ParsedHtml        :
                RawContentLength  : 564

        - In the proxcontainer 

                       C:\app>ipconfig


                  C:\app>python .\app.py
                   * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
                  client request connecting...
                  retrun from 169.254.169.254 endpoint ...
                  172.21.206.5 - - [28/Jan/2018 06:19:04] "GET / HTTP/1.1" 200 -
                  client request connecting...
                  retrun from 169.254.169.254 endpoint ...
                  172.21.206.5 - - [28/Jan/2018 06:19:08] "GET / HTTP/1.1" 200 -
                  client request connecting...
                  retrun from 169.254.169.254 endpoint ...
                  172.21.206.5 - - [28/Jan/2018 06:19:09] "GET / HTTP/1.1" 200 -
