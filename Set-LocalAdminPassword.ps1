#Requires -RunAsAdministrator
# Check PowerShell version and edition at runtime
if ($PSVersionTable.PSVersion -lt [Version]"5.1" -and $PSVersionTable.PSEdition -ne "Core") {
    Write-Error "This script requires Windows PowerShell 5.1 or PowerShell 7.5.0 or later."
    exit 1
}

if ($PSVersionTable.PSEdition -eq "Core" -and $PSVersionTable.PSVersion -lt [Version]"7.5.0") {
    Write-Error "This script requires PowerShell 7.5.0 or later for Core edition."
    exit 1
}

function Write-Message {
    param (
        [string]$Message,
        [string]$LogLevel = "INFO"
    )
<#
.SYNOPSIS
Logs messages to the Windows Event Log with specified log levels.

.DESCRIPTION
The `Write-Message` function writes messages to the Windows Event Log under the "Application" log name 
and the "Set-LocalAdminPassword" event source. It supports three log levels: INFO, WARNING, and ERROR, 
each mapped to specific Event IDs. If the event source does not exist, it is created automatically.

.PARAMETER Message
Specifies the message to log in the Windows Event Log.

.PARAMETER LogLevel
Specifies the log level for the message. Valid values are:
- INFO (default): Logs informational messages with Event ID 10090.
- WARNING: Logs warning messages with Event ID 10091.
- ERROR: Logs error messages with Event ID 10093.

.EXAMPLE
Write-Message -Message "Operation completed successfully."
Logs an informational message with the default log level (INFO).

.EXAMPLE
Write-Message -Message "Potential issue detected." -LogLevel "WARNING"
Logs a warning message with the specified log level.

.EXAMPLE
Write-Message -Message "An error occurred during execution." -LogLevel "ERROR"
Logs an error message with the specified log level.

.NOTES
- The function ensures the event source exists before writing to the log.
- Logs are written to the "Application" log under the "Set-LocalAdminPassword" source.
- Event IDs:
  - 10090: Information
  - 10091: Warning
  - 10093: Error
- Requires administrative privileges to create event sources or write to the event log.
#>

    # Define the event source and log name
    $eventSource = "Set-LocalAdminPassword"
    $eventLog = "Application"

    # Ensure the event source exists
    if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        New-EventLog -LogName $eventLog -Source $eventSource -ErrorAction SilentlyContinue
    }

    # Map log levels to event types and Event IDs
    switch ($LogLevel) {
        "INFO" {
            $eventType = [System.Diagnostics.EventLogEntryType]::Information
            $eventId = 10090
        }
        "WARNING" {
            $eventType = [System.Diagnostics.EventLogEntryType]::Warning
            $eventId = 10091
        }
        "ERROR" {
            $eventType = [System.Diagnostics.EventLogEntryType]::Error
            $eventId = 10093
        }
        default {
            $eventType = [System.Diagnostics.EventLogEntryType]::Information
            $eventId = 10090
        }
    }

    # Write the message to the event log
    Write-EventLog -LogName $eventLog -Source $eventSource -EntryType $eventType -EventId $eventId -Message $Message
}
function Set-LocalAdminPassword {
<#
    .SYNOPSIS

    Creates or resets a local administrator account named 'ITSupport' with a secure password.

    .DESCRIPTION

    The `Set-LocalAdminPassword` function ensures a local admin account named 'ITSupport' exists. If it exists, the password 
    is reset. If it does not exist, the account is created and added to the Administrators group. The password can be 
    provided as plain text or a secure string, and the function will handle conversion as needed.

    If the machine is Azure AD-joined, the function will fail gracefully and notify the user that local user management 
    is not supported. Instead, Azure AD roles or Intune should be used for administrative access.

    .PARAMETER Password

    Specifies the password to set for the local admin account. Can be provided as plain text or a secure string.

    .PARAMETER Username

    Specifies the username for the local admin account. Defaults to 'ITSupport' if not provided.

    .PARAMETER WhatIf

    Simulates the actions of the function without making any changes. Useful for testing.

    .EXAMPLE

    Set-LocalAdminPassword -Password "PlainTextPassword123!"
    This command sets the password for the 'ITSupport' account to "PlainTextPassword123!".

    .EXAMPLE

    $securePassword = Read-Host "Enter Password" -AsSecureString
    Set-LocalAdminPassword -Password $securePassword
    This command sets the password for the 'ITSupport' account to the secure string provided by the user.

    .EXAMPLE

    Set-LocalAdminPassword -Password "ComplexPassword123!" -Username "AdminUser"
    This command sets the password for the 'AdminUser' account to "ComplexPassword123!".

    .EXAMPLE

    Set-LocalAdminPassword -Password "PlainTextPassword123!" -WhatIf
    This command simulates setting the password for the 'ITSupport' account without making changes.

    .NOTES

    - Requires administrative privileges to manage local user accounts.
    - Uses PowerShell cmdlets `Get-LocalUser`, `Set-LocalUser`, `New-LocalUser`, and `Add-LocalGroupMember`.
    - If Azure AD-joined, the function will notify the user and exit gracefully.
    - Logs all actions and errors to the Windows Event Log
        - Event Log Name: Application
        - Event Source: Set-LocalAdminPassword
        - Event IDs:
            - 10090: Information
            - 10091: Warning
            - 10093: Error
#>
    param (
        [Parameter(Mandatory = $true)]
        [Object]$Password,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username = "ITSupport", # Default to 'ITSupport' if not provided

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    if ($WhatIf) {
        Write-Message -Message (
            "WhatIf mode enabled. No changes will be made."
        ) -LogLevel "INFO"
        return
    }

    # Check if the machine is Azure AD-joined
    $isAzureADJoined = $null -ne (dsregcmd /status |
        Select-String "AzureAdJoined\s*:\s*YES")
    if ($isAzureADJoined) {
        Write-Message -Message (
            "This machine is Azure AD-joined. Local user management is not supported. " +
            "Use Azure AD roles or Intune for administrative access."
        ) -LogLevel "WARNING"
        return
    }

    # Convert plain text password to a secure string if necessary
    if ($Password -isnot [SecureString]) {
        $passwordValidationParams = @{
            LengthRequirement = ($Password.Length -ge 12)
            UppercaseCheck    = ($Password -match '[A-Z]')
            LowercaseCheck    = ($Password -match '[a-z]')
            DigitCheck        = ($Password -match '\d')
            SpecialCharCheck  = ($Password -match '[!@#$%^&*()]')
        }

        $validationChecks = @{
            LengthRequirement = "Password must be at least 12 characters long."
            UppercaseCheck    = "Password must include at least one uppercase letter."
            LowercaseCheck    = "Password must include at least one lowercase letter."
            DigitCheck        = "Password must include at least one number."
            SpecialCharCheck  = "Password must include at least one special character."
        }

        foreach ($key in $validationChecks.Keys) {
            if (-not $passwordValidationParams[$key]) {
            Write-Message -Message $validationChecks[$key] -LogLevel "ERROR"
            return
            }
        }

        Write-Message -Message (
            "The provided password is not a secure string. " +
            "Converting to a secure string."
        ) -LogLevel "WARNING"
        $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
    }

    try {
        # Check if the account exists
        $account = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
        if ($account) {
            if ($account.Enabled -eq $false) {
                Enable-LocalUser -Name $Username
                Write-Message -Message (
                    "Account '$Username' has been enabled."
                ) -LogLevel "INFO"
            }
            if ($account.LockedOut -eq $true) {
                Unlock-LocalUser -Name $Username
                Write-Message -Message (
                    "Account '$Username' has been unlocked."
                ) -LogLevel "INFO"
            }
            # Reset the password if the account exists
            Set-LocalUser -Name $Username -Password $Password
            Write-Message -Message (
                "Password for account '$Username' has been reset."
            ) -LogLevel "INFO"
        } else {
            # Create the account if it doesn't exist
            $newLocalUserParams = @{
                Name               = $Username
                Password           = $Password
                FullName           = "Local Admin Account"
                Description        = "Local admin account for IT"
                AccountNeverExpires = $true
                ErrorAction        = "Stop"
            }
            New-LocalUser @newLocalUserParams
            Add-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction Stop
            Write-Message -Message (
                "Account '$Username' has been created and added to the Administrators group."
            ) -LogLevel "INFO"
        }
    } catch {
        Write-Message -Message "An error occurred: $_" -LogLevel "ERROR"
    }
}