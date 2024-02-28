# List all VMs
$VMs = Get-VM

# Display a numbered list of VMs
Write-Host "Select a VM:"
for ($i = 0; $i -lt $VMs.Count; $i++) {
    Write-Host "$($i + 1). $($VMs[$i].Name)"
}

# Prompt user to choose a VM
$selection = Read-Host "Enter the number of the VM you want to manage"

if ($selection -ge 1 -and $selection -le $VMs.Count) {
    $selectedVM = $VMs[$selection - 1]

    # Display options for the selected VM
    Write-Host "`nSelected VM: $($selectedVM.Name)"
    Write-Host "1. Stop VM"
    Write-Host "2. Start VM"
    Write-Host "3. Create Checkpoint"
    Write-Host "4. Connect Network Adapter"
    Write-Host "5. Change Memory or CPU"
    Write-Host "6. Delete a VM from Disk"
    $choice = Read-Host "Enter the number of the action you want to perform"

    switch ($choice) {
        1 {
            # Stop the selected VM
            try {
                Stop-VM -VMName $selectedVM.Name -Passthru | Get-VM
            } catch {
                Write-Host "Failed to stop the VM: $_.Exception.Message"
            }
        }
        2 {
            # Start the selected VM
            try {
                Start-VM -VMName $selectedVM.Name -Passthru | Get-VM
            } catch {
                Write-Host "Failed to start the VM: $_.Exception.Message"
            }
        }
        3 {
            # Create a checkpoint for the selected VM
            try {
                Checkpoint-VM -VMName $selectedVM.Name
            } catch {
                Write-Host "Failed to create a checkpoint: $_.Exception.Message"
            }
        }
        4 {
            # Connect a network adapter to the selected VM - Prompt for Switch Name
            Write-Host "Choose the network switch to connect (LAN-Internal or Hyper-V-WAN):"
            $switchChoice = Read-Host "Enter the switch name"

            switch ($switchChoice) {
                "LAN-Internal" {
                    try {
                        Connect-VMNetworkAdapter -VMName $selectedVM.Name -Name "Network Adapter" -SwitchName "LAN-Internal"
                    } catch {
                        Write-Host "Failed to connect to LAN-Internal switch: $_.Exception.Message"
                    }
                }
                "Hyper-V-WAN" {
                    try {
                        Connect-VMNetworkAdapter -VMName $selectedVM.Name -Name "Network Adapter" -SwitchName "Hyper-V-WAN"
                    } catch {
                        Write-Host "Failed to connect to Hyper-V-WAN switch: $_.Exception.Message"
                    }
                }
                default {
                    Write-Host "Invalid selection"
                }
            }
        }
        5 {
            # Select the VM to modify its performance
            $selectedVMName = $selectedVM.Name

            # Ask the user which performance attribute to modify
            $performanceOption = Read-Host "Which performance attribute do you want to change? (Memory/CPU)"

            switch ($performanceOption.ToLower()) {
                "memory" {
                    # Modify memory settings for the VM
                    $newMemoryMB = Read-Host "Enter the new memory size in MB"
                    $confirmChange = Read-Host "Do you want to change the memory size of '$selectedVMName' to '$newMemoryMB' MB? (Y/N)"

                    if ($confirmChange -eq "Y" -or $confirmChange -eq "y") {
                        try {
                            # Convert MB to Bytes
                            $newMemoryBytes = [int64]$newMemoryMB * 1MB

                            # Apply the new memory size to the VM
                            Stop-VM -Name $selectedVMName -Force
                            Set-VMMemory -VMName $selectedVMName -DynamicMemoryEnabled $false -StartupBytes $newMemoryBytes -ErrorAction Stop
                            Start-VM -Name $selectedVMName

                            Write-Host "Memory size of '$selectedVMName' changed to '$newMemoryMB' MB successfully."
                        } catch {
                            Write-Host "Failed to change memory size: $($_.Exception.Message)"
                        }
                    } else {
                        Write-Host "Memory size change canceled."
                    }
                }
                "cpu" {
                    # Modify CPU settings for the VM
                    $newCPUCount = Read-Host "Enter the new CPU count"
                    $confirmChange = Read-Host "Do you want to change the CPU count of '$selectedVMName' to '$newCPUCount'? (Y/N)"

                    if ($vmState -eq "Running") {
                        Write-Host "Turning off the virtual machine '$selectedVMName'..."
                        Stop-VM -Name $selectedVMName -Force
                    }
                    if ($confirmChange -eq "Y" -or $confirmChange -eq "y") {
                        try {
                            Set-VMProcessor -VMName $selectedVMName -Count $newCPUCount -ErrorAction Stop
                            Write-Host "CPU count of '$selectedVMName' changed to '$newCPUCount' successfully."
                        } catch {
                            Write-Host "Failed to change CPU count: $($_.Exception.Message)"
                        }
                    } else {
                        Write-Host "CPU count change canceled."
                    }

                    if ($vmState -eq "Running") {
                        Write-Host "Turning on the virtual machine '$selectedVMName'..."
                        Start-VM -Name $selectedVMName
                    }
                }
                default {
                    Write-Host "Invalid option. Please select either 'Memory' or 'CPU'."
                }           
            }
        }
        6 {
            if ($selectedVM -ne $null) {
                switch ($selectedVM.State) {
                    'Off' {
                        # Delete a VM from Disk
                try {
                    Remove-VM -VMName $selectedVM.Name
                } catch {
                    Write-Host "Failed to delete the VM: $($_.Exception.Message)"
                }
            }
                'Saved' {
                    Write-Host "The selected VM is in a saved state. Please turn it off before deleting."
                }
                default {
                    Write-Host "The selected VM is in an unexpected state."
                    }
                }
            } else {
                Write-Host "Invalid VM selection"
            }
        }
    }
}