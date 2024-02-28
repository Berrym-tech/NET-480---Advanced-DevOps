Import-Module '480-utils' -Force
#Call the Banner Function
480Banner
$conf = Get-480Config -config_path = "/home/maxwell/Desktop/modules/480.json"
480Connect -server $conf.vcenter_server
Write-Host "Selecting a VM"
Select-VM -folder "BASEVM"
LinkedClone