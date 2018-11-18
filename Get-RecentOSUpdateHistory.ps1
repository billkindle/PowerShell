<#
    Get-RecentOSUpdateHistory.ps1
    Created By: Bill Kindle
    Created On: 11/18/2018
    Description:
    This script will create a basic log of recently installed OS updates on each server listed 
    in the $servers variable. Using PSRemoting, get the last X days of installed OS updates, write 
    the results to a log file and go to the next entry, appending the log file each iteration until
    done. 

    Output should look like this:

    Description     HotFixID  InstalledOn            PSComputerName RunspaceId                          
    -----------     --------  -----------            -------------- ----------                          
    Security Update KB4462941 10/13/2018 12:00:00 AM localhost 2ea4f428-4283-458b-b2f3-d55e6a8f8ea1
    Security Update KB4462949 10/13/2018 12:00:00 AM localhost 2ea4f428-4283-458b-b2f3-d55e6a8f8ea1
    Security Update KB4466536 11/17/2018 12:00:00 AM localhost 2ea4f428-4283-458b-b2f3-d55e6a8f8ea1
    Security Update KB4467703 11/17/2018 12:00:00 AM localhost 2ea4f428-4283-458b-b2f3-d55e6a8f8ea1
    Security Update KB4467697 11/17/2018 12:00:00 AM localhost 2ea4f428-4283-458b-b2f3-d55e6a8f8ea1

#>


# Set a couple of variables or re-write to pull server / computer names from AD.
$servers = Get-Content -Path '.\MyServerList.txt'

# I found 60 days to be a good number as it doesn't give you too much but not too little.
$days = '-60'

# You can place output wherever you want. I just needed a text file, nothing fancy. K.I.S.S. ;-)
$output = '.\MyLogFile.txt'

# This is where the magic happens. If an error occurs, I don't care right now. 
# Just means PSremoting is bad or the host is offline.
ForEach ($server in $servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        Get-HotFix | Where-Object {$_.InstalledOn -gt ((Get-Date).AddDays($days))} |
            Select-Object -Property PSComputerName, Description, HotFixID, InstalledOn
    } | Format-Table -AutoSize | Out-File -Encoding utf8 -FilePath $output -Append -ErrorAction SilentlyContinue
}