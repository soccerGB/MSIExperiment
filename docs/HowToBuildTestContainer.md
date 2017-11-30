build images and tag with account namespace



## Building test images for running on the WindowsServerCore 1709 image

1. Build a python image on top of for WindowsServerCore 1709

      


- cd pythonOn1709

      - docker build -t pythonwindow1709 
.

3. Build a proxy container image

            

To make Instance Metadat Service acessible from the proxy container, 
add a new net route for 169.254.169.254 to the active netowrk interface( see setupproxynet.ps1 for details)
      
      
- cd proxy

      - docker build -t proxycontainer .
     

 
2. Build a client container image

            
There are a couple things that need to be setup in a client container
            
.Added 169.254.169.254 as a net ip address to the current network interface (see net.ps1)
                  
New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254
            
.Added a port forwarding rule: from 169.254.169.254:80 to IMSProxyIpAddress:80 via Netsh tool (see setup.bat)
                 
 Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=%IMSProxyIpAddress% connectport=80  protocol=tcp

      
- cd client

      - docker build -t clientcontainer .



PS D:\github\MSIExperiment\proxy> docker build -t pythonwindow1709 .
PS D:\github\MSIExperiment\proxy> docker tag  pythonwindow1709 msitest/test:pythonwindow1709
PS D:\github\MSIExperiment\proxy> docker push msitest/test:pythonwindow1709



PS D:\github\MSIExperiment\pythonOn1709> docker build -t proxycontainer .
PS D:\github\MSIExperiment\pythonOn1709> docker tag proxycontainer msitest/test:proxycontainer
PS D:\github\MSIExperiment\pythonOn1709> docker push msitest/test:proxycontainer


PS D:\github\MSIExperiment\client> docker build -t clientcontainer .
PS D:\github\MSIExperiment\client> docker tag clientcontainer msitest/test:clientcontainer
PS D:\github\MSIExperiment\client> docker push  msitest/test:clientcontainer


push image to the docker hub

PS D:\github\MSIExperiment> docker push  msitest/test:clientcontainer
The push refers to repository [docker.io/msitest/test]
fdf7224b8e17: Pushed
8232361f739c: Skipped foreign layer
4bfe49d7bc33: Skipped foreign layer
clientcontainer: digest: sha256:d1516c158034387dcc4e74dac3eae89c952ce58adefcd40c9de34845393351fe size: 1152
PS D:\github\MSIExperiment>



D:\github\MSIExperiment> docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: msitest
Password:
Login Succeeded

