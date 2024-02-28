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
