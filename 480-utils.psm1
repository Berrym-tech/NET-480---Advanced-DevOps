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

function Clone-VM {
    param (
        [Parameter(Mandatory=$true)]
        [string] $SourceVMName,
        [Parameter(Mandatory=$true)]
        [string] $SnapshotName,
        [Parameter(Mandatory=$true)]
        [string] $VMRenamed,
        [string] $TargetVMHost = "192.168.7.12",
        [string] $TargetDatastore = "datastore1"
    )
    begin {
        Write-Host "Source VM: $SourceVMName"
        Write-Host "Snapshot: $SnapshotName"
        Write-Host "The New VM Name is: $VMRenamed"
        Write-Host "Target Host: $TargetVMHost"
        Write-Host "Target Datastore: $TargetDatastore"
    }
    process {
        try {
            # Retrieve the source VM
            $vm = Get-VM -Name $SourceVMName -ErrorAction Stop
            # Find the specified snapshot
            $snapshot = Get-Snapshot -VM $vm -Name $SnapshotName -ErrorAction Stop
            # Get the target host and datastore
            $vmhost = Get-VMHost -Name $TargetVMHost -ErrorAction Stop
            $ds = Get-DataStore -Name $TargetDatastore -ErrorAction Stop
            # Create a linked clone from the snapshot
            $linkedCloneName = "{0}.linked" -f $vm.name
            $linkedVM = New-VM -LinkedClone -Name $linkedCloneName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -ErrorAction Stop
            # Create a new VM from the linked clone
            $newvm = New-VM -Name "$VMRenamed.base" -VM $linkedVM -VMHost $vmhost -Datastore $ds -ErrorAction Stop
            # Create a snapshot of the new VM
            $newvm | New-Snapshot -Name "Base" -ErrorAction Stop
            Write-Host "Clone operation completed successfully."
        }
        catch {
            Write-Host "ERROR: $_"
            exit
        }
    }
    end {
        Write-Host "Function execution completed."
    }
}
