Import-Module '/home/maxwell/Desktop/NET-480---Advanced-DevOps-main/modules/480-utils/' -Force
#Call the Banner Function
480Banner
$conf = Get-480Config -config_path "/home/maxwell/Desktop/NET-480---Advanced-DevOps-main/modules/480.json"
480Connect -server $conf.vcenter_server
Choice($conf)
# Write-Host "Selecting a VM"
# Select-VM -folder "PROD"
# LinkedClone
# New-Network
# Get-IP