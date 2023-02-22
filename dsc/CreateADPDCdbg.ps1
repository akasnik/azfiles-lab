configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Bool]$CreateForest = $true,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, xDnsServer, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script EnableDNSDiags
	    {
      	    SetScript = { 
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript =  { @{} }
            TestScript = { $false }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddr
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        xDnsServerForwarder DnsForwarder
        {
            IsSingleInstance = 'Yes'
            IPAddresses = '168.63.129.16'
        }

        xWaitforDisk Disk2
        {
            DiskId = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskId = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
        }
        
        xADUser 'MarketingUser1'
        {
            Ensure     = 'Present'
            UserName   = 'MarketingUser1'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[xADDomain]FirstDS'
        }

        xADUser 'MarketingUser2'
        {
            Ensure     = 'Present'
            UserName   = 'MarketingUser2'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[xADDomain]FirstDS'
        }

        xADGroup 'MarketingGroup'
        {
            GroupName   = 'Marketing'
            Ensure      = 'Present'
            MembershipAttribute = 'DistinguishedName'
            MembersToInclude             = @(
                'CN=MarketingUser1,CN=Users,DC=contoso,DC=com'
                'CN=MarketingUser2,CN=Users,DC=contoso,DC=com'
            )
            DependsOn = @('[xADUser]MarketingUser1','[xADUser]MarketingUser2')
        }

        xADUser 'SalesUser1'
        {
            Ensure     = 'Present'
            UserName   = 'SalesUser1'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[xADDomain]FirstDS'
        }

        xADUser 'SalesUser2'
        {
            Ensure     = 'Present'
            UserName   = 'SalesUser2'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[xADDomain]FirstDS'
        }

        xADGroup 'SalesGroup'
        {
            GroupName   = 'Sales'
            Ensure      = 'Present'
            MembershipAttribute = 'DistinguishedName'
            MembersToInclude             = @(
                'CN=SalesUser1,CN=Users,DC=contoso,DC=com'
                'CN=SalesUser2,CN=Users,DC=contoso,DC=com'
            )
            DependsOn = @('[xADUser]SalesUser1','[xADUser]SalesUser2')
        }
   }
} 