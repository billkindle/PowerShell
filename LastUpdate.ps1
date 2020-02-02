<#

    Name: LastUpdate.ps1
    Created By: Bill Kindle
    Created On: 01/31/2020

    Description:
    This script is meant to pull Last Windows Update information from a host
    for use with Zabbix Enterprise Monitoring. The script is able to detect 
    what version of Windows it is running on, and use the appropriate code to 
    pull information from the registry (Legacy OS / Windows 7/2012/2008) or use 
    newer PowerShell methods (NextGen OS / Windows 10/2016/2019).

    This info is reported as STDOUT which can be read by Zabbix Agents.

    "This is the way."
        -The Mandalorian.

#>

#Region Path Checks & Data Gathering

<#
    The idea here is to use test-path on the Registry entry to determine if the host is
    Windows 7 / Windows Server 2012 R2, otherwise assume it's Windows 10 / Windows Server 2016.
#>

# This Path should be valid on Windows 7 / Windows Server 2012 R2
If ((Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\') -eq $true) {

    <# 
        Here I'm going to get the last update time but I'm going 
        to test for a value first. If no value, return '999' 
        which is read by Zabbix as a problem. 
    #>

    If ((Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install') -eq $true) {

        #Get the time from registry key for Windows 7 / Windows Server 2012R2
        $LastTime = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install\').LastSuccessTime

        #Here I'm just taking the output gathered, converting it to a string using the date format specified

        #Write-Host -ForegroundColor 'Yellow' "Test Path FAILED!"
        $FromDate  =[DateTime] $LastTime
        $ToDate    =[DateTime] (Get-Date).DateTime
 
        $Days = ($ToDate - $FromDate).TotalDays
        $Output = $Days.ToString("###")
    
        Write-Host -ForegroundColor 'Yellow' $Output

    }
    else {

        # '999' is configured as a trigger in Zabbix to signify host is in error.
        Write-Host -ForegroundColor 'Yellow' "999"

    }

}
else {

    #I need to make a time baseline here for the math later
    $NowTime = (Get-Date).Date

    #This is the only way I've found to extract a date on Windows 10 / Windows Server 2016/2019
    $LastTime = (Invoke-CimMethod -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUSettings -MethodName GetLastUpdateInstallationDate).LastUpdateInstallationDate

    #Here I'm just taking the output gathered, converting it to a string using the date format specified
    $LastTimeStr = $LastTime.ToString('yyyy-MM-dd')

    #Combine times and tally the days
    $Output = (New-TimeSpan -Start $LastTimeStr -End $NowTime).TotalDays

    #This is the output Zabbix is looking for.
    Write-Host -ForegroundColor 'Yellow' $Output

}

#EndRegion

