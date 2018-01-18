git@github.com:soccerGB/MSIRS4.git

- You just need to build a VM from \\winbuilds\release\RS_onecore_stack_sdn_dev1

- Import a RS4 compatiable servercore OS container image
  
      eg: 
      copy \\winbuilds\release\RS_ONECORE_STACK_SDN_DEV1\17069.1006.180101-1700\amd64fre\containerbaseospkgs\cbaseospkg_serverdatacentercore_en-us\*.gz c:\temp\ServerCore.gz

      docker import c:\temp\ServerCore.gz microsoft/servercore:rs4
      
      PS C:\WINDOWS\system32> docker images
          REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
          microsoft/servercore   rs4                 edfd4431c954        6 seconds ago       3.6GB


- After that use \\skyshare\scratch\Users\sabansal\Tools\Powershell\hns.psm1 to put a policy on endpoint to redirect traffic. A sample is as follows:

https://github.com/soccerGB/MSIRS4/tree/master/scripts

-  
Get-HNSEndpoint | ? {$_.IPAddress -eq "10.0.0.3"; }  | % {$_.ID} | %{New-HnsProxyPolicy -Destination "10.137.198.118:8080" -OutbountNat $true -Endpoints $_}

This intercepts any traffic to go to 10.137.198.118:8080. You can put a destinationport and destination address filter. Have a look at the commmandlet for other parameters. I use it to redirect traffic to my host from a container with ip 10.0.0.3. 
