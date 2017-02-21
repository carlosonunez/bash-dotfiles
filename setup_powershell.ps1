#Requires -Version 4.0
#Requires -RunAsAdministrator


function Get-FileFromRepository {
  param(
    [Parameter(Mandatory=$true)]
    [string]$fileUri
  )
  $fileContent = Invoke-RestMethod $fileUri -ErrorAction SilentlyContinue
  if (!$fileContent) {
    Write-Error "Could not locate file [$fileUri]"
  }
  return $fileContent
}

function Install-Chocolatey {
  iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex  
}

function Install-ChocoPackages {
  params(
    [Parameter(Mandatory=$true)]
    [string[]]$packagesToInstall
  )
  $installedPackages = & choco info --local-only
  $packagesToInstall | %{
    $package = $_
    if (!($installedPackages | ?{$_ -match $package})) {
      echo "Installing: $package"
      choco install $package
    }
  }
}

function Enable-LinuxSubsystem {
  $command = "lxrun /install /setdefaultuser $env:USERNAME /y"
  if (!(Test-Path $(cmd /c where bash))) {
    & $command
  }
}

function Write-PSProfile {
  params(
    [Parameter(Mandatory=$true)]
    [string]$fileContent
  )
  cat $PROFILE >> $env:HOMEPATH\backup_profile.ps1
  echo $fileContent > $PROFILE
}

# ---

$packagesToInstall = Get-FileFromRepository "https://raw.githubusercontent.com/carlosonunez/carlosonunez/setup/master/windows_packages.txt"
if (!$packagesToInstall) {
    Write-Error "Could not locate packages to install from source"
    exit 1
}
powershellProfile = Get-FileFromRepository "https://raw.githubusercontent.com/carlosonunez/carlosonunez/setup/master/windows_powershell_profile.txt"
if (!$powershellProfile) {
    Write-Error "Could not locate Powershell Profile to write."
    exit 1
}
Write-PSProfile -FileContent $powershellProfile
Install-Chocolatey
Install-ChocoPackages -PackagesToIsntall $packagesToInstall
Enable-LinuxSubsystem
