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
    
    Import-DscResource -ModuleName xStorage, PSDesiredStateConfiguration, xPendingReboot, ComputerManagementDsc, cChoco, cNtfsAccessControl

    $templateFolder = "$ShareFolder\IT"
    
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

        Script waitForDiskBug
        {
            DependsOn = '[xDisk]DataDisk'
            SetScript = {
                
            }
            GetScript = {
                @{Result = $true}
            }
            TestScript = {
                Get-PSDrive -PSProvider FileSystem | Out-Null
                $true
            }
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\choco"
            DependsOn = "[Script]waitForDiskBug"
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

        if ($DeployShare) {
            File ShareFolder {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = $ShareFolder
                DependsOn = "[Script]waitForDiskBug"
            }

            SmbShare Share1 {
                Name = $ShareName
                Path = $ShareFolder
                DependsOn = "[File]ShareFolder"
                FullAccess = @('Everyone')
            }

            File TemplateFolder {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = $templateFolder
                DependsOn = "[File]ShareFolder"
            }
            
            Script configShare
            {
                DependsOn = @('[cChocoPackageInstaller]installGit', '[File]ShareFolder')
                SetScript = {
                    #git -C $using:ShareFolder clone $using:GitRepo | Out-Null
                    $out = Invoke-Command -ScriptBlock {git -C $using:templateFolder clone $using:GitRepo 2>&1}
                }
                GetScript = {
                    @{Result = Get-ChildItem $using:templateFolder | Measure-Object | %{$_.Count}}
                }
                TestScript = {
                    if (Test-Path $using:templateFolder)  {((Get-ChildItem $using:templateFolder | Measure-Object | %{$_.Count}) -gt 0)} else {$false}
                }
            }

            File MarketingFolder {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = "$ShareFolder\Marketing"
                DependsOn = "[Script]configShare"
            }

            File SalesFolder {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = "$ShareFolder\Sales"
                DependsOn = "[Script]configShare"
            }

            File MarketingFile1 {
                Ensure = "Present"
                Type = "File"
                DestinationPath = "$ShareFolder\Marketing\marketingData1.txt"
                Contents = "Sample marketing data text..."
                DependsOn = "[File]MarketingFolder"
            }

            File MarketingFile2 {
                Ensure = "Present"
                Type = "File"
                DestinationPath = "$ShareFolder\Marketing\marketingData2.txt"
                Contents = "Sample marketing data text..."
                DependsOn = "[File]MarketingFolder"
            }

            File MarketingFile3 {
                Ensure = "Present"
                Type = "File"
                DestinationPath = "$ShareFolder\Marketing\marketingData3.txt"
                Contents = "Sample marketing data text..."
                DependsOn = "[File]MarketingFolder"
            }

            File SalesFile1 {
                Ensure = "Present"
                Type = "File"
                DestinationPath = "$ShareFolder\Sales\salesData1.txt"
                Contents = "Sample sales data text..."
                DependsOn = "[File]SalesFolder"
            }

            File SalesFile2 {
                Ensure = "Present"
                Type = "File"
                DestinationPath = "$ShareFolder\Sales\salesData2.txt"
                Contents = "Sample sales data text..."
                DependsOn = "[File]SalesFolder"
            }

            File SalesFile3 {
                Ensure = "Present"
                Type = "File"
                DestinationPath = "$ShareFolder\Sales\salesData3.txt"
                Contents = "Sample sales data text..."
                DependsOn = "[File]SalesFolder"
            }

            cNtfsPermissionEntry PermissionSetIT
            {
                Ensure = 'Present'
                Path = "$ShareFolder\IT"
                Principal = 'BUILTIN\Users'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType = 'Allow'
                        FileSystemRights = 'FullControl'
                        Inheritance = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
                DependsOn = @('[File]TemplateFolder', '[Script]configShare', '[File]MarketingFile3', '[File]SalesFile3')
            }

            cNtfsPermissionEntry PermissionSetMarketing
            {
                Ensure = 'Present'
                Path = "$ShareFolder\Marketing"
                Principal = 'CONTOSO\Marketing'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType = 'Allow'
                        FileSystemRights = 'FullControl'
                        Inheritance = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
                DependsOn = @('[File]TemplateFolder', '[Script]configShare', '[File]MarketingFile3')
            }
            
            cNtfsPermissionEntry PermissionSetSales
            {
                Ensure = 'Present'
                Path = "$ShareFolder\Sales"
                Principal = 'CONTOSO\Sales'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType = 'Allow'
                        FileSystemRights = 'FullControl'
                        Inheritance = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
                DependsOn = @('[File]TemplateFolder', '[Script]configShare', '[File]SalesFile3')
            }
        }
   }
} 
