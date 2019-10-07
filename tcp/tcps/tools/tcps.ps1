. $PSScriptRoot\doublecmd.ps1
. $PSScriptRoot\totalcmd.ps1
. $PSScriptRoot\ini.ps1

if (!$Env:COMMANDER_PLUGINS_PATH) { $Env:COMMANDER_PLUGINS_PATH = Join-Path $Env:ChocolateyToolsLocation TCPlugins }
mkdir -ea 0 $Env:COMMANDER_PLUGINS_PATH

$TCP_Types      = 'Wcx', 'Wdx', 'Wfx', 'Wlx'
$TCP_PluginType = ''
$TCP_PluginFile = ''
 
function Get-TCPluginInfo {
    param(
        [string] $Name,
        [string] $PluginsPath = $Env:COMMANDER_PLUGINS_PATH, 
        [switch] $x32
    )
    
    $pluginExtensions = $TCP_Types | % { if ($x32) {"*.$_"} else {"*.${_}64"} }
    $global:TCP_PluginFile = Get-ChildItem -Recurse -Path $PluginsPath -Include $pluginExtensions -Filter "$Name.*" 
    if (!$global:TCP_PluginFile) { throw "Can't find plugin installation for the '$Name'" }
    if ($global:TCP_PluginFile.Count -gt 1) { throw "Multiple plugins found by the name '$Name': $($global:TCP_PluginFile.Name)"  } 
    $type = $global:TCP_PluginFile.Extension.Substring(1) -replace '64'
    $global:TCP_PluginType = $type.Substring(0,1).ToUpper() + $type.Substring(1)
}

function Get-CallingPackageToolsDir
{
    if ($toolsPath) { return $toolsPath }

    $cStack = @(Get-PSCallStack)
    Split-Path $cStack[$cStack.Length-3].InvocationInfo.MyCommand.Source
}

function Install-TCPlugin($Name) {
    $toolsPath = Get-CallingPackageToolsDir

    $packageArgs = @{
        PackageName    = $Env:ChocolateyPackageName 
        FileFullPath   = gi $toolsPath\*$Name* -Include '*.rar','*.zip'
        FileFullPath64 = gi $toolsPath\*$Name* -Include '*.rar','*.zip'
        Destination    = "$Env:COMMANDER_PLUGINS_PATH\$Name"
    }
    Get-ChocolateyUnzip @packageArgs
    if ($Env:ChocolateyPackageName) {  Remove-Item $packageArgs.FileFullPath -ea 0 }

    if (Test-DC) {
        Write-Host "Adding plugin settings for Double Commander"
        Set-DCPlugin $Name
    }
    if (Test-TC) {
        Write-Host "Adding plugin settings for Total Commander"
        Set-TCPlugin $Name
    }
}

function Uninstall-TCPlugin($Name) {
    if (Test-DC) {
        Write-Host "Removing plugin settings for Double Commander"
        Set-DCPlugin $Name -Uninstall
    }
    if (Test-TC) {
        Write-Host "Removing plugin settings for Total Commander"
        Set-TCPlugin $Name -Uninstall
    }

    Write-Host "Removing plugin files"
    Remove-Item $Env:COMMANDER_PLUGINS_PATH\$Name
}

$Name = 'Services2'

$toolsPath = Resolve-Path $PSScriptRoot\..\..\tcp-$Name\tools
$Env:COMMANDER_INI = ''
$Env:COMMANDER_PLUGINS_PATH = Resolve-Path "$Env:ChocolateyToolsLocation\TCPlugins"
Install-TCPlugin $Name