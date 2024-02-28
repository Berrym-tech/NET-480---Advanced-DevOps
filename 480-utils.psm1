function 480Banner()
{
    Write-Host "Hello Ryan"
}
function 480Connect([string] $server)
{
    $conn = $global:DefaultVIServer
    #Are we already connected?
    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn

        Write-Host -ForegroundColor Green $msg
    }else
    {
        $conn = Connect-VIServer -server $server
        #If this fails, let Connect-VIServer handle the exception
    }
}

function Get-480Config([string] $config_path) 
{
    $conf=$null
    if(Test-Path $config_path)
    {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = 'Using Configuration at {0}' -f $config_path
        Write-Host -ForegroundColor "Green" $msg
    }else
    {
        Write-Host -ForegroundColor "Yellow" "No Configuration"
    }
    return $conf
}

Function Select-VM([string] $folder)
{
    $selected_vm=$null
    try 
    {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.Name
            $index+=1
        }
        $pick_index = Read-Host "Pick an index"
        $selected_vm = $vms[$pick_index]
        Write-Host "You Picked " $selected_vm.Name
        return $selected_vm
}
    catch 
    {
        Write-Host "Invalid Folder: $folder" -ForegroundColor "Red"
    }
}

function Clone-VM([PSObject] $vm, [string] $cloneName, [string] $esxiHost, [string] $datastore, [string] $networkName, [bool] $powerOn) {
    try {
        $snapshot = Get-Snapshot -VM $vm | Where-Object { $_.Name -eq "BASE" }
        if (-not $snapshot) {
            Write-Host "Base snapshot not found. Please ensure a base snapshot exists." -ForegroundColor Red
            return
        }

        $cloneSpec = New-Object VMware.Vim.VirtualMachineCloneSpec
        $cloneSpec.Location = New-Object VMware.Vim.VirtualMachineRelocateSpec
        $cloneSpec.Location.Datastore = (Get-Datastore -Name $datastore).Id
        $cloneSpec.Location.Host = (Get-VMHost -Name $esxiHost).Id
        $cloneSpec.PowerOn = $powerOn
        $cloneSpec.Template = $false

        $linkedClone = $false
        Read-Host "Do you want to create a Full clone? (Y/N)" | ForEach-Object {
            if ($_ -eq "Y") {
                $cloneSpec.Location.DiskMoveType = "moveAllDiskBackingsAndDisallowSharing"
            } else {
                $cloneSpec.Snapshot = $snapshot.Id
                $linkedClone = $true
            }
        }

        $newVM = $vm | New-VM -Name $cloneName -VMHost $esxiHost -Datastore $datastore -Location (Get-Folder -Name $vm.Folder.Name) -CloneSpec $cloneSpec
        Write-Host "Clone created successfully: $cloneName" -ForegroundColor Green

        if ($linkedClone -and $networkName) {
            $newVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $networkName -Confirm:$false
            Write-Host "Network adapter set to $networkName" -ForegroundColor Green
        }

    } catch {
        Write-Host "Error cloning VM: $_" -ForegroundColor Red
    }
}
