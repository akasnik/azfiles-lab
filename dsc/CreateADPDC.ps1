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
    
    Import-DscResource -ModuleName ActiveDirectoryDsc, xStorage, xNetworking, xDnsServer, PSDesiredStateConfiguration, xPendingReboot
    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
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

        ADDomain FirstDS 
        {
            DomainName = $DomainName
            Credential = $Admincreds
            SafemodeAdministratorPassword = $Admincreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
        }

        ADUser 'MarketingUser1'
        {
            Ensure     = 'Present'
            UserName   = 'MarketingUser1'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[ADDomain]FirstDS'
        }

        ADUser 'MarketingUser2'
        {
            Ensure     = 'Present'
            UserName   = 'MarketingUser2'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[ADDomain]FirstDS'
        }

        ADGroup 'MarketingGroup'
        {
            GroupName   = 'Marketing'
            Ensure      = 'Present'
            MembershipAttribute = 'DistinguishedName'
            MembersToInclude             = @(
                'CN=MarketingUser1,CN=Users,DC=contoso,DC=com'
                'CN=MarketingUser2,CN=Users,DC=contoso,DC=com'
            )
            DependsOn = @('[ADUser]MarketingUser1','[ADUser]MarketingUser2')
        }

        ADUser 'SalesUser1'
        {
            Ensure     = 'Present'
            UserName   = 'SalesUser1'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[ADDomain]FirstDS'
        }

        ADUser 'SalesUser2'
        {
            Ensure     = 'Present'
            UserName   = 'SalesUser2'
            Password   = $DomainCreds
            DomainName = 'contoso.com'
            Path       = 'CN=Users,DC=contoso,DC=com'
            DependsOn = '[ADDomain]FirstDS'
        }

        ADGroup 'SalesGroup'
        {
            GroupName   = 'Sales'
            Ensure      = 'Present'
            MembershipAttribute = 'DistinguishedName'
            MembersToInclude             = @(
                'CN=SalesUser1,CN=Users,DC=contoso,DC=com'
                'CN=SalesUser2,CN=Users,DC=contoso,DC=com'
            )
            DependsOn = @('[ADUser]SalesUser1','[ADUser]SalesUser2')
        }
  }
}