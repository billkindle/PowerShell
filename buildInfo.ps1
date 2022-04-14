# I got this example from https://mypowershellnotes.wordpress.com/2020/05/27/get-windows-build-information-from-powershell/
# May turn this into a real function sometime - Bill K. 4/14/22

# Windows Build Information
 
# Appx - Import-Module: Operation is not supported on this platform. (0x80131539)
# https://github.com/PowerShell/PowerShell/issues/13138
 
# How do I find the version of my Windows Feature Experience Pack?
# https://stackoverflow.com/questions/64831517/how-do-i-find-the-version-of-my-windows-feature-experience-pack
 
Switch ($PSVersionTable.PSVersion.ToString())
{
  "7.1.0" {Import-Module -Name Appx -UseWindowsPowerShell; Break}
  "7.1.1" {Import-Module -Name Appx -UseWindowsPowerShell; Break}
}
 
$buildInfo = [PSCustomObject]@{
  Version     = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion
  InstalledOn = [DateTime]::FromFileTime((Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name InstallTime))
  OSBuild     = "{0}.{1}" -f (Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild), (Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name UBR)
  Edition     = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName
  ReleaseId   = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId
  Experience  = (Get-AppxPackage 'MicrosoftWindows.Client.CBS').Version
}
