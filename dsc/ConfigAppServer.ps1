configuration ConfigAppServer
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$ShareDriveLetter,
   
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

        cChocoPackageInstaller installAzPS
        {
            Name        = "az.powershell"
            DependsOn   = "[cChocoPackageInstaller]installAzCLI"
            #This will automatically try to upgrade if available, only if a version is not explicitly specified.
            AutoUpgrade = $True
        }
        
        cChocoPackageInstaller installEdge
        {
            Name        = "choco install microsoft-edge"
            DependsOn   = "[cChocoPackageInstaller]installAzPS"
            #This will automatically try to upgrade if available, only if a version is not explicitly specified.
            AutoUpgrade = $True
        }

        IEEnhancedSecurityConfiguration disableIEESC
        {
            Role = 'Administrators'
            Enabled = $False
        }

   }
} 
