
# How to build test container images


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
      Note: proxycontainer image takes a dependency on msitest/test:pythonwindow1709

  ### Build a client container image

      PS D:\github\MSIExperiment\client> docker build -t clientcontainer .
      PS D:\github\MSIExperiment\client> docker tag clientcontainer msitest/test:clientcontainer

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
