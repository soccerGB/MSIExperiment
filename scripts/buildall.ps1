
$ErrorActionPreference = "SilentlyContinue"
Write-output "Stop and remove all running Docker conainers, and related images"

docker stop $(docker ps -a -q)
docker rm  $(docker ps -a -q)
docker rmi -f msiserviceclient
docker rmi -f python-windows-rs4-nanoserver-insider 
docker rmi -f proxy 
docker rmi -f golang-windows-rs4-nanoserver-insider 
docker rmi -f microsoft/nanoserver-insider-ps 

cd ..

cd nanoserverPS
.\buildimage.ps1
cd ..


cd golangRS4
.\buildimage.ps1
cd ..

cd proxy
.\buildimage.ps1
cd ..


cd pythonOnRS4
.\buildimage.ps1
cd ..


cd msiserviceclient
.\buildimage.ps1
cd ..

docker images
