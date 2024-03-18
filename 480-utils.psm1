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
Function Choice($conf){
    Write-Host "
    Select an Option 1-4:
    [1] Linked Clone
    [2] Create a New V Network
    [3] Get System Information
    [5] Exit
    "
    $choice = Read-Host "Choose or Lose: "

            switch($choice){
                
                '1' {
                    Clear-Host
                    LinkedClone($conf)
                }
                '2' {
                    Clear-Host
                    New-Network($conf)
                }
                '3' {
                    Clear-Host
                    Get-IP($conf)
                }
                '4' {
                    Clear-Host
                    Break
                }
                '5' {
                    Clear-Host
                    Start-Stop($conf)
                }
                Default {Write-Host "Wrong"}
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
'''
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
'''
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
}
Function New-Network($conf)
{
    try {
        # Creates a new V Switch
        $vswitch = New-VirtualSwitch -VMHost $conf.esxi_host -Name (Read-Host "Name the Virtual Switch")
        Write-Host "Please wait while we create your VSwitch :)"
        $msg = "Created Virtual Switch {0}!" -f $vswitch.Name
        Write-Host $msg
        try {
            $vport = New-VirtualPortGroup -VirtualSwitch $vswitch  -Name(Read-Host "Name the Port Group")
            Write-Host "Please wait while we create your Port Group :)"
            $msg = "Created Port Group {0}!" -f $vport.Name
            Write-Host $msg
        } catch {
            Write-Host "Port Group creation failed, Try Harder." -ForegroundColor Red
            Start-Sleep -Seconds 5
        }
        } catch {
            Write-Host "VSwitch creation failed, Try Harder." -ForegroundColor Red
            Start-Sleep -Seconds 5
        }
}
function Get-IP()
{
    $vms = Get-VM
    if ($vms.Count -eq 0) {
        Write-Host "No VMs found."
        return
    }
    Write-Host "Select a VM from the list:"
    for ($i = 0; $i -lt $vms.Count; $i++) {
        Write-Host "$($i + 1): $($vms[$i].Name)"
    }
    $selection = Read-Host "Enter the number of the VM"
    $choice = [int]$selection - 1
    if ($choice -lt 0 -or $choice -ge $vms.Count) {
        Write-Host "Invalid selection."
        return
    }
    $selectedVm = $vms[$choice]
    $networkAdapter = Get-NetworkAdapter -VM $selectedVm | Select-Object -First 1
    if (-not $networkAdapter) {
        Write-Host "No network adapter found for VM '$($selectedVm.Name)'."
        return
    }
    $ipAddresses = $selectedVm.Guest.IpAddress
    if (-not $ipAddresses -or $ipAddresses.Count -eq 0) {
        Write-Host "IP address not found for VM '$($selectedVm.Name)'."
        return
    }
    $ipAddress = $ipAddresses[0]
    $macAddress = $networkAdapter.MacAddress
    Write-Host "VM Name: $($selectedVm.Name)"
    Write-Host "IP: $ipAddress"
    Write-Host "MAC: $macAddress"
}
function Start-Stop() 
{
    # Get all virtual machines in the specified directory
    $virtualMachines = Get-VM
    # Check if there are any VMs to display
    if ($virtualMachines.Count -eq 0) {
        Write-Host "No virtual machines found" -ForegroundColor Red
        return
    }
    # Display the VMs to the user and ask for a selection
    $virtualMachines | Select-Object -Property Name, PowerState | Format-Table -AutoSize
    $selectedVmName = Read-Host "Enter the name of the VM to toggle power state (on/off)"
    # Find the selected VM from the list
    $selectedVm = $virtualMachines | Where-Object { $_.Name -eq $selectedVmName }
    # Check if the VM was found
    if ($selectedVm -eq 0) {
        Write-Host "Virtual machine not found." -ForegroundColor DarkRed
        return
    }
    # Toggle the power state of the selected VM
    try {
        if ($selectedVm.PowerState -eq "PoweredOn") {
            Stop-VM -VM $selectedVm -Confirm:$false
            Write-Host "Virtual machine '$selectedVmName' has been powered off." -ForegroundColor Green
        } else {
            Start-VM -VM $selectedVm -Confirm:$false
            Write-Host "Virtual machine '$selectedVmName' has been powered on." -ForegroundColor Green
        }
    } catch {
        Write-Host "An error occurred while toggling the power state of the virtual machine." -ForegroundColor DarkRed
    }
}


