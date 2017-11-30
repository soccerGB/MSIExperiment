
# How to build MSI test container images


- ## Get the source code

      PS D:\github\git clone git@github.com:soccerGB/MSIExperiment.git 

- ## Building test images for running on the WindowsServerCore 1709 image

  ### Build a python container image

      PS D:\github\MSIExperiment\pythonOn1709> docker build -t pythonwindow1709 .
      PS D:\github\MSIExperiment\pythonOn1709> docker tag  pythonwindow1709 msitest/test:pythonwindow1709
      
      Note: we need a custom python image that can run on WindowsServerCore 1709
      
  ### Build a proxy container image

      PS D:\github\MSIExperiment\pythonOn1709> docker build -t proxycontainer .
      PS D:\github\MSIExperiment\pythonOn1709> docker tag proxycontainer msitest/test:proxycontainer
      
      Note: 1. proxycontainer image takes a dependency on msitest/test:pythonwindow1709
            2. To make Instance Metadat Service acessible from the proxy container, 
               add a new net route for 169.254.169.254 to the active netowrk interface
               ( see setupproxynet.ps1 for details)

  ### Build a client container image

      PS D:\github\MSIExperiment\client> docker build -t clientcontainer .
      PS D:\github\MSIExperiment\client> docker tag clientcontainer msitest/test:clientcontainer
      
      Note: There are a couple things that need to be setup in a client container
            1.Added 169.254.169.254 as a net ip address to the current network interface (see net.ps1)
                  New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254
            2. Added a port forwarding rule: from 169.254.169.254:80 to IMSProxyIpAddress:80 via 
               Netsh tool (see setup.bat)
               Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=%IMSProxyIpAddress% connectport=80  protocol=tcp

## For the msitest account owner only: 
   ### How to push container to the msitest/test repositories

            D:\github\MSIExperiment> docker login
            Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
            Username: msitest
            Password:
            Login Succeeded

- Make necessary tagging for each built image
            docker tag  pythonwindow1709 msitest/test:pythonwindow1709
            docker tag proxycontainer msitest/test:proxycontainer
            docker tag clientcontainer msitest/test:clientcontainer

            PS D:\github\MSIExperiment> docker images
            REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
            clientcontainer               latest              0545cd78c9d6        2 hours ago         5.58GB
            proxycontainer                latest              0545cd78c9d6        2 hours ago         5.58GB
            msitest/test                  clientcontainer     0545cd78c9d6        2 hours ago         5.58GB
            msitest/test                  proxycontainer      0545cd78c9d6        2 hours ago         5.58GB
            pythonwindow1709              latest              61a085212caa        2 hours ago         5.74GB
            msitest/test                  pythonwindow1709    61a085212caa        2 hours ago         5.74GB
            microsoft/iis                 latest              85fb57957cf1        2 weeks ago         5.73GB
            microsoft/windowsservercore   1709                be1324f21832        2 weeks ago         5.58GB
            microsoft/nanoserver          1709                1502f7107ff0        2 weeks ago         249MB

- Push to public Docker registry repositories
      
            docker push msitest/test:pythonwindow17097
            docker push msitest/test:proxycontainer
            docker push msitest/test:clientcontainer
            
- Images are ready for pull from anywhere
      
            docker pull msitest/test:pythonwindow17097
            docker pull msitest/test:proxycontainer
            docker pull msitest/test:clientcontainer
