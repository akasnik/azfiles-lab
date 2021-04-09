configuration ConfigClient 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    ) 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    $domain = $DomainName.split('.')[0]
    $DCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("$domain\$($Admincreds.Username)", $Admincreds.Password)


    Node localhost
    {
        Group AddMarketingToLocalAdminGroup {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= "$domain\Marketing"
            Credential = $dCredential
            PsDscRunAsCredential = $DCredential
        }

        Group AddSalesToLocalAdminGroup {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= "$domain\Sales"
            Credential = $dCredential
            PsDscRunAsCredential = $DCredential
        }
   }
} 