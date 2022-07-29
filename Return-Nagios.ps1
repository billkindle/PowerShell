<#
.SYNOPSIS
  Nagios to Powershell interface
.DESCRIPTION
  This script provides an means for a PowerShell script to return data to Nagios or similar clones.
.PARAMETER NagiosStatusCode
    This is the status code returned to Nagios.    
        0 = OK, No problems.
        1 = Check is at a WARNING level.
        2 = Check is at a CRITICAL level
        3 = Check has failed or returned an unknown value or response.
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Borrowed function from a coworker. Saving for later use.
.EXAMPLE
  Return-Nagios -NagiosStatusCode 0 -NagiosMessage "Process completed successfully"
.EXAMPLE
  Return-Nagios -NagiosStatusCode 2 -NagiosMessage "Something bad happened, please investigate"
#>

function Return-Nagios { 
    param( 
        [Parameter(mandatory=$true)]
        [int] $NagiosStatusCode, 
        [string] $NagiosMessage="No data to display" )
     
    # Output for Nagios
    switch ($NagiosStatusCode) 
    {
        0 {Write-Host "OK: " $NagiosMessage}
        1 {Write-Host "WARNING: " $NagiosMessage}
        2 {Write-Host "CRITICAL: " $NagiosMessage }
        default {Write-Host "UNK: " $NagiosMessage}
    }
    exit $NagiosStatusCode
}
