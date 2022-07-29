#requires -version 3
<#
.SYNOPSIS
  Get the RDS drain mode status from the registry.
.DESCRIPTION
  This script will return the current registry key value of two key entries for Remote Desktop Services monitoring.
  The values found will determine the Nagios alert level.

  HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\TSServerDrainMode
  ---
  When the value is 0, the Remote Desktop Session Host should be allowing new connections. 
  When the value is 1, the Remote Desktop Session Host should be denying new connections, 
  and will route new  requests to other available hosts in a farm. Will allow new connections on restart.
  When the value is 2, the Remote Desktop Session Host should be denying new connections.
  
  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\WinStationsDisabled
  ---
  When the value is 0, the Remote Desktop Session Host should be allowing new connections.
  When the value is 1, the Remote Desktop Session Host should be denying new connections.

  Modes
  ---
  When WinStationsDisabled = 0 and TSServerDrainMode = 0, the host is ENABLED.
  When WinStationsDisabled = 1, the drain mode does not matter. The host is DISABLED.
  When WinStationsDisabled = 0 and TSServerDrainMode = 1, the host is in DRAIN MODE until restart.
  When WinStationsDisabled = 0 and TSServerDrainMode = 2, the host is in DRAIN MODE
  
.NOTES
  Version:        1.0
  Author:         Bill Kindle
  Creation Date:  07/25/2022
#>

#Region Vars
$RegPathWinStations = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
$RegPathTSServerDrainMode = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\"
$WinStationsDisabled = (Get-ItemPropertyValue -Path $RegPathWinStations -Name WinStationsDisabled)
$TSServerDrainMode = (Get-ItemPropertyValue -Path $RegPathTSServerDrainMode -Name TSServerDrainMode)
$ReturnCode = Default
$Message = ""
#EndRegion Vars

#Region Nagios Function 
#This section runs a test to ensure that the Return-Nagios function is present and if so, loads the function. 
#$ReturnNagios = "C:\Program Files\NSClient++\scripts\return-nagios.ps1"
if (-not (test-path $ReturnNagios)) {
    throw "Return-Nagios script file is missing!"
}
else {
    . $ReturnNagios
}
Endregion Nagios Function

# Begin checking RDS Drain Mode Status

#Region RDS Status Unknown
try {
    if (((Test-Path $RegPathWinStationsDisabled -ErrorAction Stop) -eq $false) -or ((Test-Path $RegPathTSServerDrainMode -ErrorAction Stop) -eq $false)) {
        $ReturnCode = Default
        $Message = "RDS Status is unknown. One or more registry entries not found!"
    }
}
catch {
    [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $_
    }
}
#Endregion RDS Status Unkown

#Region RDS Disabled
try {
    # Here you only need ot check if WinStationDisabled
    if ($WinStationsDisabled -eq 1) {
        $ReturnCode = 2
        $Message = "RDS is DISABLED! Please check host RDS host configuration."
    }
}
catch {
    $ReturnCode = Default
    $Message = "Unable to determine RDS status. Please check host."
}
#Endregion RDS Disabled

#Region RDS Enabled
try {
    If (($WinStationsDisabled -eq 0) -and ($TSServerDrainMode -eq 0)) {
        $ReturnCode = 0
        $Message = "RDS host is ENABLED."
    }
}
catch {
    $ReturnCode = Default
    $Message = "Unable to determine RDS status. Please check host."
}
#Endregion RDS Enabled

#Region RDS Drain Mode Until Restart
try {
    if (($WinStationsDisabled -eq 0) -and ($TSServerDrainMode -eq 1)) {
        $ReturnCode = 1
        $Message = "RDS is in DRAIN MODE until RESTART. New Connections will be re-routed to alternate hosts in RDS farm."
    }
}
catch {
    $ReturnCode = Default
    $Message = "Unable to determine RDS status. Please check host."
}
#Endregion RDS Drain Mode Until Restart

#Region RDS Drain Mode
try {
    if (($WinStationsDisabled -eq 0) -and ($TSServerDrainMode -eq 2)) {
        $ReturnCode = 0
        $Message = "RDS is in DRAIN MODE."
    }
}
catch {
    $ReturnCode = Default
    $Message = "Unable to determine RDS status. Please check host."
}
#EndRegion RDS Drain Mode

# Use the Return-Nagios function, otherwise you'll have to build your own. 
Return-Nagios -NagiosStatusCode $ReturnCode -NagiosMessage $Message
