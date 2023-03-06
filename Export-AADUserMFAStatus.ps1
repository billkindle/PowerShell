# Export-AADUserMFAStatus.ps1
# Modified By: Bill Kindle
# Modified On: 3/06/23

#Requires -Modules MSOnline

function Export-AADUserMFAStatus {
<#
.SYNOPSIS
    Export current MFA status for all Microsoft 365 Azure Active Directory users. 
.DESCRIPTION
    This function is designed to connect to Microsoft 365 Azure Active Directory and return the current
    MFA status for all users. Using this function can assist with security audits. A simple CSV report
    is generated in the directoy the command is run from. 
.NOTES
    Requires MSOnline module and connection to MSOL account with proper administrative rights.
.LINK
    https://woshub.com/enable-disable-mfa-azure-users/
.EXAMPLE
    Export-AADUserMFAStatus -Verbose
    Exports a CSV report containing the UPN, MFA State, MFA Phone, and MFA Method.
#>

    [CmdletBinding()]
    param (        
    )
    
    begin {
        Connect-MsolService
        $Report = @()
        $AzUsers = Get-MsolUser -All
    }
    
    process {
        ForEach ($AzUser in $AzUsers) {
            $DefaultMFAMethod = ($AzUser.StrongAuthenticationMethods | 
                Where-Object { $_.IsDefault -eq "True" }).MethodType
            $MFAState = $AzUser.StrongAuthenticationRequirements.State
            if ($null -eq $MFAState) {$MFAState = "Disabled"}

            $objReport = [PSCustomObject]@{
                User = $AzUser.UserPrincipalName
                MFAState = $MFAState
                MFAPhone = $AzUser.StrongAuthenticationUserDetails.PhoneNumber
                MFAMethod = $DefaultMFAMethod
            }
    
            $Report += $objReport
    
        }
    }
    
    end {
        $Report | Export-Csv -Path .\AAD_User_MFA_Status.csv -NoTypeInformation
    }

}