
# Experiments on the redirecting Instance Metadata Service requests from Docker containers to a external facing proxy Docker container  

   This experiment was to find a way to access [Azure's Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) endpoint (http:// 169.254.169.254) from client containers through a dedicated proxy container. My experiment belows show, with appropriate port fordwarding and routing setup,  it's possible to achieve above scenario inside a Azure VM running a WindowsServerCore:1709 (`RS3`) build. 

![Block diagram for Proxying Instance Metadata Service request](https://github.com/soccerGB/MSIExperiment/blob/master/docs/InstanceMetadata.png "Proxying Instance Metadata Service request")

(Note: in this setup, all containers are in the same subset)

## Test container images

   There are 5 images involved.

      Windows RS3 (build 1709) images:
            microsoft/windowsservercore:1709
            microsoft/nanoserver:1709

      Windows test images:
            msitest/test:clientcontainer
            msitest/test:proxycontainer
            msitest/test:pythonwindow1709
            
For test images, you can use above prebuilt images or build from the source [test cotnainer images build instructions](https://github.com/soccerGB/MSIExperiment/blob/master/docs/HowToBuildTestContainer.md)

## How to run this test 

Inside an VM that has access to Azure's Instance Metadata Service:

- Pull images
      docker pull msitest/test:pythonwindow17097
      docker pull msitest/test:proxycontainer
      docker pull msitest/test:clientcontainer
      
- Launch proxy container

      docker run -it --label MSIProxyContainer msitest/test:proxycontainer

- Locate the ip address of the proxy container and set it to a environment variable, IMSProxyIpAddress

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

## Logging for an example run
You should have the following images in the "docker images" output
   
         C:\DCOS\MSI>docker images

               REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE

               clientcontainer               latest              d97ff4d103d9        9 minutes ago       5.39GB

               proxycontainer                latest              5439c82fa6d2        22 hours ago        5.58GB

               pythonwindow1709              latest              4f24f5144bea        23 hours ago        5.55GB

               microsoft/windowsservercore   1709                fc3e0de7ea04        5 weeks ago         5.39GB

               microsoft/nanoserver          1709                33dcd52c91c3        5 weeks ago         236MB
   
- Launch the proxy container instance
   The proxy cotnainer is expected to get run first before launching any client containers which relies on the proxy for accessign Instance Metadata. A new IP route to the network interface for 169.254.169.254 in setupproxynet.ps1 for making the Instance Metadata Service work from the proxy cotnainer itself. Some debugging messages were added into the same ps1 script for debugging purpose
      
        C:\msi\client>docker run -it --label MSIProxyContainer msitest/test:proxycontainer

         C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"
            settig up a new route for the Instance Metadata Service

            ifIndex DestinationPrefix                              NextHop                                  RouteMetric ifMetric PolicyStore
            ------- -----------------                              -------                                  ----------- -------- -----------
            23      169.254.169.254/32                             172.24.32.1                                      256 500      ActiveStore
            23      169.254.169.254/32                             172.24.32.1                                      256          Persiste...
            ===========================================================================
            Interface List
             22...........................Software Loopback Interface 2
             23...00 15 5d e0 cd 4c ......Hyper-V Virtual Ethernet Adapter #2
            ===========================================================================

            IPv4 Route Table
            ===========================================================================
            Active Routes:
            Network Destination        Netmask          Gateway       Interface  Metric
                      0.0.0.0          0.0.0.0      172.24.32.1    172.24.41.216    756
                    127.0.0.0        255.0.0.0         On-link         127.0.0.1    331
                    127.0.0.1  255.255.255.255         On-link         127.0.0.1    331
              127.255.255.255  255.255.255.255         On-link         127.0.0.1    331
              169.254.169.254  255.255.255.255      172.24.32.1    172.24.41.216    756
                  172.24.32.0    255.255.240.0         On-link     172.24.41.216    756
                172.24.41.216  255.255.255.255         On-link     172.24.41.216    756
                172.24.47.255  255.255.255.255         On-link     172.24.41.216    756
                    224.0.0.0        240.0.0.0         On-link         127.0.0.1    331
                    224.0.0.0        240.0.0.0         On-link     172.24.41.216    756
              255.255.255.255  255.255.255.255         On-link         127.0.0.1    331
              255.255.255.255  255.255.255.255         On-link     172.24.41.216    756
            ===========================================================================
            Persistent Routes:
              Network Address          Netmask  Gateway Address  Metric
                      0.0.0.0          0.0.0.0      172.24.32.1  Default
              169.254.169.254  255.255.255.255      172.24.32.1  Default
            ===========================================================================
            Testing access to the  Instance Metadata Service from the proxy container
            Invoke-WebRequest -Uri http://169.254.169.254/metadata/instance?api-version=2017-04-02 -Method GET  -Headers {Metadata=True} -UseBasicParsing



   C:\app>python .\app.py
    * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)


  *Note*: In above experiment run, the proxy container's ip address is `172.24.32.64`. it will be used by client containers for forwarding instnace metadata to.


- Locate and setup the ip address of the proxy container instance to a environment variable

- Once the proxy cotnainer is runnning successfully, use a environment vaiable (IMSProxyIpAddress) to pass the IP addess of the proxy container to client containers. 

      PS C:\MSIExperiment> .\LocateProxyAndSetEnv.ps1
      Searching for the proxy container and set the IMSProxyIpAddress to its ip address if found
      IMSProxyIpAddress is null
      proxyCotnainerName is [pedantic_galileo]
      proxyAddress is [172.24.41.216]
      proxyaddress found is [172.24.41.216]
      172.24.41.216
      PS C:\MSIExperiment> exit

      C:\MSIExperiment>set IMSProxyIpAddress=172.24.41.216

- Launch a client container instance
  C:\MSIExperiment>docker run -it -e IMSProxyIpAddress msitest/test:clientcontainer

         ============ inside the container ===============

         C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\net.ps1'"
            Adding 169.254.169.254 to network interface


            IPAddress         : 169.254.169.254
            InterfaceIndex    : 28
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
            InterfaceIndex    : 28
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

            wait for the network setting to be ready for use...

            Windows IP Configuration


            Ethernet adapter vEthernet (Ethernet) 2:

               Connection-specific DNS Suffix  . : 3xojbo1mt10efniqkq31gfg3ja.xx.internal.cloudapp.net
               Link-local IPv6 Address . . . . . : fe80::a975:3ac0:cbd7:3358%28
               IPv4 Address. . . . . . . . . . . : 172.24.36.220
               Subnet Mask . . . . . . . . . . . : 255.255.240.0
               IPv4 Address. . . . . . . . . . . : 169.254.169.254
               Subnet Mask . . . . . . . . . . . : 255.255.255.255
               Default Gateway . . . . . . . . . : 172.24.32.1
            IMSProxyIpAddress is 172.24.41.216
            Setting up port fordwaring for 169.254.169.254:80 to


Accessing the Instance Matadata Service from inside a client container 

            C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& Invoke-WebRequest -Uri "http://169.254.169.254" -Method GET -UseBasicParsing"


            StatusCode        : 200
            StatusDescription : OK
            Content           : {"compute":{"location":"westus2","name":"26652acs900-vmss_1","offer":"WindowsServerSemiAnnual","osType":"Windows","platformFaultDomain":"1","platformU
                                pdateDomain":"1","publisher":"MicrosoftWindowsServ...
            RawContent        : HTTP/1.0 200 OK
                                Content-Length: 564
                                Content-Type: text/html; charset=utf-8
                                Date: Thu, 30 Nov 2017 23:44:04 GMT
                                Server: Werkzeug/0.12.2 Python/3.7.0a2

                                {"compute":{"location":"westus2","name":"26...
            Forms             :
            Headers           : {[Content-Length, 564], [Content-Type, text/html; charset=utf-8], [Date, Thu, 30 Nov 2017 23:44:04 GMT], [Server, Werkzeug/0.12.2 Python/3.7.0a2]}
            Images            : {}
            InputFields       : {}
            Links             : {}
            ParsedHtml        :
            RawContentLength  : 564




            C:\app>cmd
            Microsoft Windows [Version 10.0.16299.64]
            (c) 2017 Microsoft Corporation. All rights reserved.

            C:\app>



