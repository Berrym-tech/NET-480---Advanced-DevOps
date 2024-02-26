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
