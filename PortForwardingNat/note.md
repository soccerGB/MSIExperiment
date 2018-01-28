        
        1. Launch a proxy container instance
        
        
              C:\github\MSIExperiment\pf2\pythonOn1709>docker run -it proxy cmd
                          
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
        
        
        
        1. Add 169.254.169.254 as a new IP addess to the interface via docker exec
        
              PS C:\github\MSIExperiment\pf2\client> docker exec ecc564884e7b powershell  "get-netadapter | select -expand ifIndex"
              29
              PS C:\github\MSIExperiment\pf2\client> docker exec ecc564884e7b powershell "New-NetIPAddress -InterfaceIndex 29 -IPAddress 169.254.169.254"

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


               PS C:\github\MSIExperiment\pf2\client> docker exec ecc564884e7b powershell "route print -4"
              ===========================================================================
              Interface List
               28...........................Software Loopback Interface 3
               29...00 15 5d d6 66 b4 ......Hyper-V Virtual Ethernet Adapter #4
              ===========================================================================

              IPv4 Route Table
              ===========================================================================
              Active Routes:
              Network Destination        Netmask          Gateway       Interface  Metric
                        0.0.0.0          0.0.0.0     172.21.192.1     172.21.206.5    756
                      127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
                      127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
                127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
                169.254.169.254  255.255.255.255         On-link      172.21.206.5    756
                   172.21.192.0    255.255.240.0         On-link      172.21.206.5    756
                   172.21.206.5  255.255.255.255         On-link      172.21.206.5    756
                 172.21.207.255  255.255.255.255         On-link      172.21.206.5    756
                      224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
                      224.0.0.0        240.0.0.0         On-link      172.21.206.5    756
                255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
                255.255.255.255  255.255.255.255         On-link      172.21.206.5    756
              ===========================================================================
              Persistent Routes:
                Network Address          Netmask  Gateway Address  Metric
                        0.0.0.0          0.0.0.0     172.21.192.1  Default
                169.254.169.254  255.255.255.255     172.21.192.1  Default
                        0.0.0.0          0.0.0.0     172.21.192.1  Default
              ===========================================================================

2. Setup port fordwarding from 169.254.169.254:80 -> ProxyContain IP address:80

          PS C:\github\MSIExperiment\pf2\client> docker exec ecc564884e7b "Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectad
          dress=172.21.193.97 connectport=80  protocol=tcp"
          container ecc564884e7beb3dc954de564c7aa10e046ca4504ea38d5e6a1ffbe1eda5844f encountered an error during CreateProcess: failure in a Windows system call: The system cannot find the file specified. (0x2) extra info: {"ApplicationName":"","CommandLine":"\"Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=172.21.193.97 connectport=80  protocol=tcp\"","User":"","WorkingDirectory":"C:\\","Environment":{},"EmulateConsole":false,"CreateStdInPipe":true,"CreateStdOutPipe":true,"CreateStdErrPipe":true,"ConsoleSize":[0,0]}
          PS C:\github\MSIExperiment\pf2\client> docker exec ecc564884e7b Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectadd
          ress=172.21.193.97 connectport=80  protocol=tcp

        PS C:\github\MSIExperiment\pf2\client>
        
  3. From inside a client container, any request for http://169.254.169.254 will be forwarded to the proxycontainer for getting MSI metadata 
     before returning back to the client
  
      From inside a client container:
      
            C:\>curl -H Metadata:true "http://169.254.169.254"
          {"compute":{"location":"westus2","name":"wp35723900-vmss_1","offer":"WindowsServerSemiAnnual","osType":"Windows","platformFaultDomain":"1","platformUpdateDomain":"1","publisher":"MicrosoftWindowsServer","sku":"Datacenter-Core-1709-with-Containers-smalldisk","version":"1709.0.20171219","vmId":"a7c7a8a7-7cdb-4c49-a3a5-d67dc6aa2050","vmSize":"Standard_D2s_v3"},"network":{"interface":[{"ipv4":{"ipAddress":[{"privateIpAddress":"10.0.0.5","publicIpAddress":""}],"subnet":[{"address":"10.0.0.0","prefix":"16"}]},"ipv6":{"ipAddress":[]},"macAddress":"000D3AF9AECA"}]}}


     In the proxcontainer 
     
               C:\app>ipconfig

          
          C:\app>python .\app.py
           * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
          172.21.206.5 - - [28/Jan/2018 06:17:46] "GET /metadata/instance?api-version=2017-04-02 HTTP/1.1" 404 -
          172.21.206.5 - - [28/Jan/2018 06:18:24] "GET /metadata/instance?api-version=2017-04-02 HTTP/1.1" 404 -
          client request connecting...
          retrun from 169.254.169.254 endpoint ...
          172.21.206.5 - - [28/Jan/2018 06:19:04] "GET / HTTP/1.1" 200 -
          client request connecting...
          retrun from 169.254.169.254 endpoint ...
          172.21.206.5 - - [28/Jan/2018 06:19:08] "GET / HTTP/1.1" 200 -
          client request connecting...
          retrun from 169.254.169.254 endpoint ...
          172.21.206.5 - - [28/Jan/2018 06:19:09] "GET / HTTP/1.1" 200 -
