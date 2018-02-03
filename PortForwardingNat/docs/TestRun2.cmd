


PS C:\github\MSIExperiment\PortForwardingNat\proxy> docker build -t proxy .
C:\github\MSIExperiment\PortForwardingNat\proxy>docker run -it --label MSIProxyContainer proxy



C:\github\MSIExperiment\PortForwardingNat\utility>docker build -t utility .
C:\github\MSIExperiment\PortForwardingNat\utility>docker run -it  --label Utility utility  cmd


PS C:\github\MSIExperiment\PortForwardingNat\scripts> .\LocateProxyAndSetEnv.ps1
Searching for the proxy container and set the IMSProxyIpAddress to its ip address if found
IMSProxyIpAddress is null
proxyCotnainerName is [blissful_murdock]
proxyAddress is [172.19.196.146]
proxyaddress found is [172.19.196.146]
set IMSProxyIpAddress=172.19.196.146
172.19.196.146


PS C:\github\MSIExperiment\PortForwardingNat\scripts> .\LocateClientAndSetupPortforward.ps1 -ContainerLabel Utility



Inside the client container

Microsoft Windows [Version 10.0.16299.192]
(c) 2017 Microsoft Corporation. All rights reserved.

C:\app>main -proxyip 172.19.196.146:80
init() called
proxyip is
Utiltiy container is running!
server will run on : %v:%v
 169.254.169.254 80
redirecting to : 172.19.196.146:80
backendServiceIpPort :%s
 http://172.19.196.146:80
Waiting for new connection resuest:


C:\github\MSIExperiment\PortForwardingNat\utility>docker run -it microsoft/windowsservercore:1709 cmd
Microsoft Windows [Version 10.0.16299.192]
(c) 2017 Microsoft Corporation. All rights reserved.

C:\>ipconfig

Windows IP Configuration


Ethernet adapter vEthernet (Ethernet) 4:

   Connection-specific DNS Suffix  . : a35nnsbpw3luldrmfovq3r3kng.xx.internal.cloudapp.net
   Link-local IPv6 Address . . . . . : fe80::318d:25d8:8e6c:fb4c%39
   IPv4 Address. . . . . . . . . . . : 172.19.202.200
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . : 172.19.192.1

C:\>curl -H Metadata:true "http://169.254.169.254"
{"compute":{"location":"westus2","name":"wp33555900-vmss_0","offer":"WindowsServerSemiAnnual","osType":"Windows","platformFaultDomain":"0","platformUpdateDomain":"0","publisher":"MicrosoftWindowsServer","sku":"Datacenter-Core-1709-with-Containers-smalldisk","version":"1709.0.20171219","vmId":"0629a204-4436-42d1-99cc-0be9c55720a7","vmSize":"Standard_D2s_v3"},"network":{"interface":[{"ipv4":{"ipAddress":[{"privateIpAddress":"10.0.0.4","publicIpAddress":""}],"subnet":[{"address":"10.0.0.0","prefix":"16"}]},"ipv6":{"ipAddress":[]},"macAddress":"000D3AFD3EED"}]}}















