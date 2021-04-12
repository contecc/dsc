Configuration DSC_Scripts
{
    $domainCred = Get-AutomationPSCredential -Name "DomainAdmin"
    $DomainName = Get-AutomationVariable -Name "DomainName"
    $DomainDN = Get-AutomationVariable -Name "DomainDN"
     
    # Import the modules needed to run the DSC script
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DScResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
 
    Node IsDomainController
    {
        Computer NewComputerName
        {
            Name = "DC1"
        } 
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn = "[Computer]NewComputerName"
        }
        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }
        WindowsFeature InstallRSAT-AD-PowerShell
        {
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
        }
         
        ADDomain $DomainName
        {
            DomainName                    = $DomainName
            Credential                    = $domainCred
            SafemodeAdministratorPassword = $domainCred
            ForestMode                    = 'WinThreshold'
            DependsOn                     = "[WindowsFeature]ADDSInstall"
        }   
        WaitForADDomain $DomainName
        {
            DomainName           = $DomainName
            WaitTimeout          = 600
            RestartCount         = 2
            PsDscRunAsCredential = $domainCred
        }
        ADOrganizationalUnit 'Aurora'
        {
            Name                            = "Aurora"
            Path                            = "$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "TopLevel OU"
            Ensure                          = 'Present'
        }
         
        ADOrganizationalUnit 'WebServers'
        {
            Name                            = "WebServers"
            Path                            = "OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "WebServers OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Aurora"
        }
        ADOrganizationalUnit 'Administration'
        {
            Name                            = "Administration"
            Path                            = "OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "Administration OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Aurora"
        }
        ADOrganizationalUnit 'AdminUsers'
        {
            Name                            = "AdminUsers"
            Path                            = "OU=Administration,OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "Administration OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Administration"
        }
        ADOrganizationalUnit 'ServiceAccounts'
        {
            Name                            = "ServiceAccounts"
            Path                            = "OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "ServiceAccounts OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Aurora"
        }
        ADOrganizationalUnit 'Citrix'
        {
            Name                            = "Citrix"
            Path                            = "OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "Citrix OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Aurora"
        }       
        ADOrganizationalUnit 'Users'
        {
            Name                            = "Users"
            Path                            = "OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "Users OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Aurora"
        }
        ADOrganizationalUnit 'Servers'
        {
            Name                            = "Servers"
            Path                            = "OU=Aurora,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = "Servers OU"
            Ensure                          = 'Present'
            DependsOn                       = "[ADOrganizationalUnit]Aurora"
        }       
        ADUser   'svc_sql'
        {
            UserName = 'svc_sql'
            Description = "Service account for SQL"
            Credential = $Cred
            PasswordNotRequired = $true
            DomainName = 'aurora.com'
            Path = "OU=ServiceAccounts,OU=Aurora,$domainDN"
            Ensure = 'Present'
            DependsOn = "[ADOrganizationalUnit]ServiceAccounts"
            Enabled = $true
            UserPrincipalName = "svc_sql@aurora.com"
            PasswordNeverExpires = $true
            ChangePasswordAtLogon = $false
        }       
    }
}