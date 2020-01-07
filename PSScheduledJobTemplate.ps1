# This is a template for scheduling PowerShell background jobs.
# The intention is to use this chunk of code to further automate
# maintenance cycles or anything else that needs it's own runspace.

$trigger = New-JobTrigger -Once -At 10:05AM
$options = New-ScheduledJobOption -RunElevated -RequireNetwork
$cred = Get-Credential -UserName [credentials] -Message 'Get Credentials for PSJob'

Register-ScheduledJob -Name 'Testing Notification Script' -Trigger $Trigger -Credential $cred -FilePath 
"C:\users\wkindle\Desktop\Code Workspaces\Test-ScheduledJob.ps1" -ScheduledJobOption $options
