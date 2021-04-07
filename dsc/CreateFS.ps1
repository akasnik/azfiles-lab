configuration CreateFS
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$ShareDriveLetter,
   
        [Parameter(Mandatory)]
        [String]$ShareFolder,

        [Parameter(Mandatory)]
        [String]$ShareName,

        [Bool]$DeployShare = $true,
        [String]$GitRepo = "https://github.com/Azure/azure-quickstart-templates.git",

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xStorage, PSDesiredStateConfiguration, xPendingReboot, ComputerManagementDsc, cChoco
    
    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature FileServices
        { 
            Ensure = "Present" 
            Name = "File-Services"		
        }

        xWaitforDisk Disk2
        {
            DiskId = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk DataDisk {
            DiskId = 2
            DriveLetter = $ShareDriveLetter
            DependsOn = "[xWaitForDisk]Disk2"
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\choco"
            DependsOn = "[xDisk]DataDisk"
        }
        
        cChocoPackageInstaller installGit
        {
            Name        = "git"
            DependsOn   = "[cChocoInstaller]installChoco"
            #This will automatically try to upgrade if available, only if a version is not explicitly specified.
            AutoUpgrade = $True
        }

        cChocoPackageInstaller installAzCLI
        {
            Name        = "azure-cli"
            DependsOn   = "[cChocoPackageInstaller]installGit"
            #This will automatically try to upgrade if available, only if a version is not explicitly specified.
            AutoUpgrade = $True
        }
        
        cChocoPackageInstaller installEdge
        {
            Name        = "choco install microsoft-edge"
            DependsOn   = "[cChocoPackageInstaller]installAzCLI"
            #This will automatically try to upgrade if available, only if a version is not explicitly specified.
            AutoUpgrade = $True
        }

        if ($DeployShare) {
            File ShareFolder {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = $ShareFolder
                DependsOn = "[xDisk]DataDisk"
            }

            SmbShare Share1 {
                Name = $ShareName
                Path = $ShareFolder
                DependsOn = "[File]ShareFolder"
            }
            
            Script configShare
            {
                DependsOn = @('[cChocoPackageInstaller]installGit', '[File]ShareFolder')
                SetScript = {
                    #git -C $using:ShareFolder clone $using:GitRepo | Out-Null
                    $out = Invoke-Command -ScriptBlock {git -C $using:ShareFolder clone $using:GitRepo 2>&1}
                }
                GetScript = {
                    @{Result = Get-ChildItem $using:ShareFolder | Measure-Object | %{$_.Count}}
                }
                TestScript = {
                    if (Test-Path $using:ShareFolder)  {((Get-ChildItem $using:ShareFolder | Measure-Object | %{$_.Count}) -gt 0)} else {$false}
                }
            }
        }
   }
} 
