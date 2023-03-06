# Export-LegacyExchangeDNUsers.ps1
# Created By: Bill Kindle
# Created On: 3/02/23

#Requires -Modules ActiveDirectory

function Export-LegacyExchangeDNUsers {
<#
.SYNOPSIS
    Export-LegacyExchangeDNUsers can be used to generate a report of users' legacyExchangeDN attribute in a CSV formatted report.
.DESCRIPTION
    Export-LegacyExchangeDNUsers can generate a report of users' legacyExchangeDN attribute in a CSV format, which may be helpful during an Exchange migration or troubleshooting scenarios.
    There is one mandatory parameter, SearchBase, which expects an array of strings containing one or more AD distinguished name (DN) paths to search for user objects.
    This function contains a foreach loop that iterates through each of the SearchBase values, and for each value, it runs the Get-ADUser cmdlet with the specified filter to retrieve all the AD user objects that meet the criteria. 
    The function exports results as a CSV file called ".\LegacyExchangeDN_Report.csv" in the current directory. The CSV report of Active Directory (AD) user objects' SamAccountName and legacyExchangeDN attributes.
.NOTES
    This function requires the ActiveDirectory module.
.EXAMPLE
    Export-LegacyExchangeDNUsers -SearchBase "dc=internal,dc=mylab,dc=com"

    Exports all users' LegacyExchangeDN attribute in the searchbase to a CSV file in the directory which the script is run.
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
        foreach ($base in $SearchBase) {
        Get-ADUser -Searchbase $base -Filter * -Properties SamAccountName,legacyExchangeDN |
            Select-Object SamAccountName,legacyExchangeDN |
                Export-Csv -Path .\LegacyExchangeDN_Report.csv -NoTypeInformation
        }
    }
    
    end {
        
    }
}