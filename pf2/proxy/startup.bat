echo "Start running setupproxynet.ps1"

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"

echo "Launch a webserver for listing to client container request"

curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02"

ipconfig 

echo " Run the following commands into each client
echo " $ifIndex = get-netadapter | select -expand ifIndex "
echo "docker exec ecc564884e7b powershell  get-netadapter | select -expand ifIndex"
echo "docker exec ecc564884e7b powershell New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress 169.254.169.254"
echo " Netsh interface portproxy add v4tov4 listenaddress=169.254.169.254 listenport=80 connectaddress=$IMSProxyIpAddress connectport=80  protocol=tcp"

python .\app.py