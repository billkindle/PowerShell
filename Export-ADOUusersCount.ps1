# Export-ADOUusersCount.ps1
# Created By: Bill Kindle
# Created On: 2/22/23

#Requires -Modules ActiveDirectory

function Export-ADOUUsersCount {
<#
.SYNOPSIS
    Count-ADOUsers is for quickly generating a report of the number of users in each OU of an AD domain.
.DESCRIPTION
    Export-ADOUUsersCount is used to count the number of Active Directory (AD) users in each Organizational Unit (OU) specified in the "SearchBase" parameter.
    The function has a single mandatory parameter named "SearchBase", which accepts an array of strings.
    The "SearchBase" parameter specifies the root location (s) in the AD hierarchy from which the function should start searching for user objects. 
    The function will search all sub-OUs beneath the specified "SearchBase" location (s).
    This function loops through each location specified in the "SearchBase" parameter and retrieves all enabled AD users in that location and its sub-OUs.
    The resulting report, ".\AD_User_Count_By_OU.csv", shows the number of users in each OU, sorted in ascending order by the number of users.
.NOTES
    This function requires the ActiveDirector module.
.EXAMPLE
    Export-ADOUsersCount -SearchBase "dc=internal,dc=mylab,dc=com"

    Exports user counts per organizational unit in domain context.
#>
    [CmdletBinding()]
    param (
        # The LDAP search path you are wanting to count. Uses X.500 Directory Specification OU (organizational unit) and DC (domain component)
        [Parameter(Mandatory=$true)]
        [string[]]$SearchBase
    )
    
    begin {

    }
    
    process {
        $User = foreach ($base in $SearchBase) {
            Get-ADUser -Filter {enabled -eq $true} -SearchBase $base -SearchScope Subtree |
                Select-Object @{Name="OU";Expression={$_.distinguishedName -match "cn=.*?,OU=(?<OU>.*)" |
                    Out-Null;$Matches.OU}}
        }
        $report = $User | Group-Object -Property OU | Select-Object -Property Name,Count | Sort-Object Count

        $report | Export-Csv -Path .\AD_User_Count_By_OU.csv -NoTypeInformation

    }
    
    end {
        
    }
}