echo "Start running setupproxynet.ps1"

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '.\setupproxynet.ps1'"

ipconfig

echo "Launch a webserver for listing to client container request"

python .\app.py

