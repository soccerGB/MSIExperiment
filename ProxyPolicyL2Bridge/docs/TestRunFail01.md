Here is the log from a test run.
 
        PS C:\Users\Administrator> docker network ls
        NETWORK ID          NAME                DRIVER              SCOPE
        7cdbe7a39044        myl2bridge          l2bridge            local
        c81a2398fa18        nat                 nat                 local
        86bac2268b7f        none                null                local
        PS C:\Users\Administrator>

        PS C:\Users\Administrator> docker network inspect myl2bridge
        [
            {
                "Name": "myl2bridge",
                "Id": "7cdbe7a390445e7a08cac836397b7cf4ce0353c8f29dfc3ba98f95bd531a900e",
                "Created": "2017-12-12T11:44:06.0781343-08:00",
                "Scope": "local",
                "Driver": "l2bridge",
                "EnableIPv6": false,
                "IPAM": {
                    "Driver": "windows",
                    "Options": null,
                    "Config": [
                        {
                            "Subnet": "10.0.0.0/24",
                            "Gateway": "10.0.0.1"
                        }
                    ]
                },
                "Internal": false,
                "Attachable": false,
                "Ingress": false,
                "ConfigFrom": {
                    "Network": ""
                },
                "ConfigOnly": false,
                "Containers": {},
                "Options": {
                    "com.docker.network.windowsshim.hnsid": "a003cd4d-f20d-4e3d-af1a-ae7b453399a4",
                    "com.docker.network.windowsshim.networkname": "myl2bridge"
                },
                "Labels": {}
            }
        ]
        PS C:\Users\Administrator>


        PS C:\Users\Administrator> docker images
        REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
        clientrs4              latest              875e8d716c18        3 days ago          4.54GB
        microsoft/servercore   rs4                 e9a4dc4311a8        4 days ago          4.54GB
        microsoft/nanoserver   rs4                 3f1d9a7e9e06        4 days ago          208MB


        Container 1
        PS C:\Users\Administrator> docker run -it --network=myl2bridge proxyrs4
        C:\app>echo "Start running setupproxynet.ps1"
        "Start running setupproxynet.ps1"
        C:\app>PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"
        Settig up a new route for the Instance Metadata Service
        Import-Module NetAdapter
        Import-Module Microsoft.PowerShell.Utility
        OK!

        C:\app>ipconfig
        Windows IP Configuration
        Ethernet adapter vEthernet (Ethernet) 3:
           Connection-specific DNS Suffix  . :
           Link-local IPv6 Address . . . . . : fe80::28d9:9d49:3dd7:d1a8%26
           IPv4 Address. . . . . . . . . . . : 10.0.0.118
           Subnet Mask . . . . . . . . . . . : 255.255.255.0
           Default Gateway . . . . . . . . . : 10.0.0.1

        C:\app>echo "Launch a webserver for listing to client container request"
        "Launch a webserver for listing to client container request"

        C:\app>python .\app.py
        * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)

        Container 2
        PS C:\Users\Administrator> docker run -it --network=myl2bridge clientrs4
        Microsoft Windows [Version 10.0.17053.1000]
        (c) 2017 Microsoft Corporation. All rights reserved.

        C:\app>ipconfig

        Windows IP Configuration


        Ethernet adapter vEthernet (Ethernet) 2:

           Connection-specific DNS Suffix  . :
           Link-local IPv6 Address . . . . . : fe80::b489:81a7:e70e:25a5%21
           IPv4 Address. . . . . . . . . . . : 10.0.0.232
           Subnet Mask . . . . . . . . . . . : 255.255.255.0
           Default Gateway . . . . . . . . . : 10.0.0.1

        C:\app>

        //  Container 1 is able to connect to Container 2

        PS C:\app> wget http://10.0.0.118 -UseBasicParsing


        StatusCode        : 200
        StatusDescription : OK
        Content           : Request recieved by the proxycontainer
        RawContent        : HTTP/1.0 200 OK
                            Content-Length: 38
                            Content-Type: text/html; charset=utf-8
                            Date: Tue, 12 Dec 2017 20:00:28 GMT
                            Server: Werkzeug/0.13 Python/3.7.0a2

                            Request recieved by the proxycontainer
        Forms             :
        Headers           : {[Content-Length, 38], [Content-Type, text/html; charset=utf-8], [Date, Tue, 12 Dec 2017 20:00:28
                            GMT], [Server, Werkzeug/0.13 Python/3.7.0a2]}
        Images            : {}
        InputFields       : {}
        Links             : {}
        ParsedHtml        :
        RawContentLength  : 38


        // Add a proxypolicy

        PS C:\github\MSIRS4\scripts> Get-HNSEndpoint | ? {$_.IPAddress -eq "10.0.0.232"; }  | % {$_.ID}
        6d11f077-af54-4a72-b6dd-831e86ead169
        PS C:\github\MSIRS4\scripts> New-HnsProxyPolicy -Destination "10.0.0.118:80" -OutbountNat $true -DestinationPrefix 169.254.169.254 -DestinationPor
        t 80  -Endpoints 6d11f077-af54-4a72-b6dd-831e86ead169

        (Does above policy read as: all the traffics coming out from container 1, if their target is 169.254.169.254:80, it will be reroute  to 10.0.0.118:80?)


        ActivityId                : aa7ee1d9-7d62-4cab-a1ec-0ddec40c2ec6
        CreateProcessingStartTime : 131575820780619124
        GatewayAddress            : 10.0.0.1
        ID                        : 6d11f077-af54-4a72-b6dd-831e86ead169
        IPAddress                 : 10.0.0.232
        MacAddress                : 00-15-5D-76-70-2D
        Name                      : Ethernet
        Policies                  : {@{Type=L2Driver}, @{Destination=10.0.0.118:80; IP=169.254.169.254; OutbountNat=True; Port=80; Type=PROXY}}
        PrefixLength              : 24
        Resources                 : @{AllocationOrder=4; Allocators=System.Object[]; ID=aa7ee1d9-7d62-4cab-a1ec-0ddec40c2ec6; PortOperationTime=0;
                                    State=1; SwitchOperationTime=0; VfpOperationTime=0; parentId=07e0857c-389d-4bec-abf6-5bca2e587251}
        SharedContainers          : {6410dd06584ff453b2f15699acbdf47e83a2230de6db6f6e76abb480a327833b}
        StartTime                 : 131575820785219101
        State                     : 2
        Type                      : l2bridge
        Version                   : 21474836481
        VirtualNetwork            : a003cd4d-f20d-4e3d-af1a-ae7b453399a4
        VirtualNetworkName        : a59ed7d9ecb76b846406389b828aebd89d859c096e5a829d89c0f56ec4f0b05a


        With above set, I was expecting to see the following request got routed  from Container 1 to Container2 and get some response back but it didn’t.

        PS C:\app> wget http://169.254.169.254 -UseBasicParsing
        wget : Unable to connect to the remote server
        At line:1 char:1
        + wget http://169.254.169.254 -UseBasicParsing
        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-WebRequest], WebExc
           eption
            + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand

        PS C:\app>
