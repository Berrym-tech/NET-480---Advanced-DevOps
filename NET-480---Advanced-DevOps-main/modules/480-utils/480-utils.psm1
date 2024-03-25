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
Function Choice($conf)
{
    Write-Host "
    Select an Option 1-6:
    [1] Linked Clone
    [2] Create a New Network
    [3] Get IP
    [4] Start / Stop VM
    [5] Set-Network
    [6] Exit
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
                    Start-Stop($conf)
                }
                '5' {
                    Clear-Host
                    Set-Network($conf)
                }
                '6' {
                    Clear-Host
                    Break
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
Function LinkedClone([string] $folder)
{
try {
    Get-VM -Location $conf.vm_folder | Select-Object Name -ExpandProperty Name
    $linked = Get-VM -Name (Read-Host -Prompt "VM to Clone: ") -ErrorAction Stop
    try{
        $linked | Get-Snapshot | Select-Object Name -ExpandProperty Name
        $linked_snap = Get-Snapshot -VM $linked -Name (Read-Host -Prompt "Snapshot Name: ")
        $msg = "Datastore is {0}, Type Yes if it is Correct, Type No if you wish to use another Datastore" -f $conf.datastore
        try {
            $datastore = Read-Host -Prompt $msg
            If ($datastore = "Yes"){
                $datastore = $conf.datastore
             } else {
                $datastore = Read-Host -Prompt "Enter the datastore you wish to change to: " 
             }
            try {
                $clonename = Read-Host -Prompt "New name for VM: "
                    try{
                        $linkedname = "{0}.linked" -f $clonename
                        $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $linked -ReferenceSnapshot $linked_snap -VMHost $conf.esxi_host -Datastore $datastore
                            try{ 
                                $newvm = New-VM -Name $clonename -VM $linkedvm -VMHost $conf.esxi_host -Datastore $datastore
                                $newvm | New-Snapshot -Name "Base" 
                                $linkedvm | Remove-VM -DeletePermanently -Confirm:$false
                                Write-Host "Clone created at $datastore named $clonename." -ForegroundColor Green
                            } catch {
                                Write-Host "Error"
                                Break
                            }
                    } catch {
                        Write-Host "Linking failed"
                        Break
                    }
            } catch {
                Write-Host "Use a Different Name next time"
                Break
            }
        } catch {
            Write-Host "Datastore name is wrong"
            Break
    }
    } catch {
        Write-Host = "Snapshot Name is wrong"
        Break
    }
}
catch {
    Write-Host "Invalid VM"
    Break
}
}
Function New-Network($conf)
{
    try {
        $vswitch = New-VirtualSwitch -VMHost $conf.esxi_host -Name (Read-Host "Vswitch Name: ")
        $msg = "Created Virtual Switch {0}!" -f $vswitch.Name
        Write-Host $msg
        try {
            $vport = New-VirtualPortGroup -VirtualSwitch $vswitch  -Name(Read-Host "Port Group Name: ")
            $msg2 = "Created Virtual Port Group {0}!" -f $vport.Name
            Write-Host $msg2
        } catch {
            Write-Host "Port Group creation failed" -ForegroundColor Red
        }
        } catch {
            Write-Host "Vswitch creation failed" -ForegroundColor Red
        }
}

Function Get-IP($conf)
{
    Write-Host "Name a VM:"
    Get-VM -Location $conf.vm_folder_PROD | Select-Object Name -ExpandProperty Name
    $vm = Read-Host "Enter VM Name: "
    $ip = (Get-VM -Name $vm).Guest.IPAddress[0]
    $mac = (Get-NetworkAdapter -VM $vm | Select-Object MacAddress).MacAddress[0]
    $msg = "$ip hostname=$vm mac=$mac"
    Write-Host $msg
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
    # Toggle the power state
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
function Set-Network()
{
    try {
        Write-Host "Choose a VM to change a Network adapter on:"
        Get-VM -Location $conf.vm_folder_PROD | Select-Object Name -ExpandProperty Name
        $vm = Read-Host "Select a VM: "
        Get-VirtualNetwork
        $network = Read-Host "Select A Network: "
        Get-NetworkAdapter -VM $vm | Select-Object Name -ExpandProperty Name
        $ryan = Read-Host "Select A Network Adapter: "
        Get-VM $vm | Get-NetworkAdapter -Name $ryan| Set-NetworkAdapter -NetworkName $network -Confirm:$false
    } catch {
        Write-Host "Error"
       }
}