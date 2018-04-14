
# Ideally, we want to download the python zip file and install everything inside a container
# but this approach only works on Servercore or above skus, it does not work on nanoserver
# This is why we have to install Python on the build machine before copying files over to 
# the container and updating its PATH to make it work


$ErrorActionPreference = "SilentlyContinue"

# clean up previously installed Python related packages
Get-Package "*python*" | Uninstall-Package

$PYTHON_VERSION="3.7.0a2"
$PYTHON_RELEASE="3.7.0"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$url = "https://www.python.org/ftp/python/$PYTHON_RELEASE/python-$PYTHON_VERSION-amd64.exe"
Write-Host ('Downloading {0} ...' -f $url);
Invoke-WebRequest -Uri $url -OutFile 'python.exe'

dir 

$CurrentDir = (Get-Item -Path ".\").FullName


$PythonInstallationDir  = join-path $CurrentDir "python"
$PythonExecutablePath  = join-path $PythonInstallationDir "python"

Write-Host "Installing Python $PYTHON_VERSION without UI..." 
$process = Start-Process .\python.exe -Wait -ArgumentList @('/quiet','InstallAllUsers=1', ('TargetDir={0}' -f $PythonInstallationDir),'PrependPath=1','Shortcuts=0','Include_doc=0','Include_pip=0','Include_test=0')

Write-Host "Installation exist code: $($process.ExitCode)"

# the installer updated PATH, so we should refresh our local value
	$env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine) 
	Write-Host 'Verifying install python installation by running python --version...'
	Write-Host '  python --version' 
	.\python\python --version 
	Write-Host 'Removing downloaded file (python.exe)...'
	Remove-Item python.exe -Force
	Write-Host 'Complete.';

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
$PYTHON_PIP_VERSION="9.0.3"

Write-Host "Installing pip==$PYTHON_PIP_VERSION"

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py'
python get-pip.py --disable-pip-version-check --no-cache-dir ('pip=={0}' -f $PYTHON_PIP_VERSION) 
Remove-Item get-pip.py -Force 

Write-Host 'Verifying pip install ...'
pip --version
Write-Host 'Complete.'


Write-Host "Creating the Python.zip"
Compress-Archive -Path .\Python -DestinationPath .\Python.zip -Force

Write-Host "Generating python-windows-rs4-nanoserver-insider docker image"
docker build -t  python-windows-rs4-nanoserver-insider . 

Write-Host "Removing unused files"
Remove-Item .\Python.zip -Force
Remove-Item -Recurse -Force .\Python

# clean up previously installed Python related packages
Get-Package "*python*" | Uninstall-Package