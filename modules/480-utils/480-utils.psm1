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

function Show-Menu {
    while ($true) {
        Write-Host "1: Linked Clone"
        Write-Host "2: New Network"
        Write-Host "3: Get IP"
        Write-Host "Q: Quit"

        $selection = Read-Host "Please select an option"

        switch ($selection) {
            '1' {
                # Parameters can be asked from the user or hardcoded
                LinkedClone
            }
            '2' {
                # Ask for necessary parameters or use default values
                New-Network
            }
            '3' {
                # Ask for the VM name
                $vmName = Read-Host "Enter VM name"
                $ipInfo = Get-IP -VMName $vmName
                Write-Host "IP Info: $($ipInfo | Out-String)"
            }
            'Q', 'q' {
                Write-Host "Exiting..."
                break
            }
            default {
                Write-Host "Invalid option, please try again."
            }
        }
    }
}
# Start the script
Show-Menu

function LinkedClone()
{
    param (
        [Parameter(Mandatory=$true)]
        [string] $SnapshotName,
        [Parameter(Mandatory=$true)]
        [string] $VMRenamed,
        [string] $TargetVMHost = "192.168.7.12",
        [string] $TargetDatastore = "datastore1",
        [string] $vm_folder = "BASEVM"
    )
    begin {
        # Prompt user to select a VM from the specified folder
        $SourceVM = Select-VM -folder $vm_folder
        if ($null -eq $SourceVM) {
            Write-Host "No VM selected or found. Exiting function." -ForegroundColor Red
            return
        }
        $SourceVMName = $SourceVM.Name
        Write-Host "Source VM: $SourceVMName"
        Write-Host "Snapshot: $SnapshotName"
        Write-Host "The New VM Name is: $VMRenamed"
        Write-Host "Target Host: $TargetVMHost"
        Write-Host "Target Datastore: $TargetDatastore"
    }
    process {
        try {
            # Retrieve the source VM based on user selection
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
    function New-Network {
    param(
        [string]$SwitchName,
        [string]$PortGroupName,
        [string]$VirtualSwitchType = 'Standard'
    )
    # Create a new Virtual Switch
    $vSwitch = New-VirtualSwitch -Name $SwitchName -Type $VirtualSwitchType
    # Create a new Virtual Port Group on the created Virtual Switch
    New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $PortGroupName

    Write-Output "Virtual Switch and Port Group created successfully."
    }
    function Get-IP {
    param(
        [string]$VMName
    )
    # Get the specified VM object
    $vm = Get-VM -Name $VMName
    # Get network adapter information
    $networkAdapter = Get-NetworkAdapter -VM $vm | Select-Object -First 1

    $vmInfo = @{
        VMName = $VMName
        IPAddress = $vm.Guest.IpAddress[0]
        MACAddress = $networkAdapter.MacAddress
    }

    return $vmInfo
    }
}
