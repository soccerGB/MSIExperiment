Remove-Item Env:\TestVariable

Write-Host "hello world from Go!"

$date
$a = Get-Date
$time = $a.ToUniversalTime()

[Environment]::SetEnvironmentVariable("TestVariable","I got set at : $time","User")