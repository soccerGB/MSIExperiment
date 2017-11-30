
# How to build test container images

build images and tag with account namespace


## Get the source code

      PS D:\github\git clone git@github.com:soccerGB/MSIExperiment.git 

## Building test images for running on the WindowsServerCore 1709 image

### Build a python image on top of for WindowsServerCore 1709

      PS D:\github\MSIExperiment\pythonOn1709> docker build -t pythonwindow1709 .
      PS D:\github\MSIExperiment\pythonOn1709> docker tag  pythonwindow1709 msitest/test:pythonwindow1709
      
### Build a proxy container image

      PS D:\github\MSIExperiment\pythonOn1709> docker build -t proxycontainer .
      PS D:\github\MSIExperiment\pythonOn1709> docker tag proxycontainer msitest/test:proxycontainer
      Note: proxycontainer image takes a dependency on msitest/test:pythonwindow1709

### Build a client container image

      PS D:\github\MSIExperiment\client> docker build -t clientcontainer .
      PS D:\github\MSIExperiment\client> docker tag clientcontainer msitest/test:clientcontainer

            


## For the msitest account owner only: how to push container to the msitest/test repositories

            D:\github\MSIExperiment> docker login
            Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
            Username: msitest
            Password:
            Login Succeeded

            PS D:\github\MSIExperiment\pythonOn1709> docker push msitest/test:pythonwindow17097
            PS D:\github\MSIExperiment\pythonOn1709> docker push msitest/test:proxycontainer
            PS D:\github\MSIExperiment\client> docker push  msitest/test:clientcontainer
