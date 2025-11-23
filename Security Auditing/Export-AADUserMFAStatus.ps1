<#
.SYNOPSIS
    Exports Multi-Factor Authentication (MFA) status for Microsoft Entra ID (Azure AD) users.

.DESCRIPTION
    Retrieves and exports comprehensive MFA status information for all or specified Microsoft Entra ID users.
    The script supports both legacy MSOnline (MSOL) and modern Microsoft Graph API authentication methods,
    with automatic fallback between methods based on module availability.
    
    Key features:
    - Multiple input methods: All users, specific users array, CSV file, or interactive mode
    - Dual API support: Microsoft Graph (recommended) and MSOnline (legacy)
    - Comprehensive MFA details: Status, default method, phone number, registered methods
    - Flexible output: CSV export with customizable path and timestamped filenames
    - Progress reporting with detailed status messages
    - Proper error handling and validation
    
    The exported report includes:
    - User Principal Name (UPN)
    - Display Name
    - MFA Status (Enabled, Enforced, Disabled)
    - Default MFA Method
    - Registered MFA Phone Number
    - All Registered Methods
    - User Enabled Status
    - Report Timestamp

.PARAMETER UserPrincipalNames
    Array of specific user principal names (email addresses) to retrieve MFA status for.
    Use this parameter when you need to check specific users rather than all users.

.PARAMETER CsvPath
    Path to CSV file containing UserPrincipalName column with users to query.
    Useful for bulk operations with pre-defined user lists.

.PARAMETER Interactive
    Launches interactive mode where the script prompts for user principal names.
    Convenient for ad-hoc queries without preparing input files.

.PARAMETER OutputPath
    Full path where the MFA status report CSV will be saved.
    If not specified, creates a timestamped file in the current directory.
    Default: .\MFA_Status_Report_YYYYMMDD_HHMMSS.csv

.PARAMETER UseGraphAPI
    Forces the script to use Microsoft Graph API instead of MSOnline module.
    Recommended for modern environments as MSOnline is being deprecated.

.PARAMETER IncludeDisabledUsers
    When specified, includes disabled user accounts in the report.
    By default, only enabled users are included to focus on active accounts.

.EXAMPLE
    .\Export-AADUserMFAStatus.ps1
    
    Exports MFA status for all enabled users using default settings.
    Creates timestamped CSV file in current directory.

.EXAMPLE
    .\Export-AADUserMFAStatus.ps1 -UseGraphAPI -IncludeDisabledUsers
    
    Uses Microsoft Graph API and includes disabled accounts in the export.

.EXAMPLE
    .\Export-AADUserMFAStatus.ps1 -UserPrincipalNames @("user1@domain.com","user2@domain.com") -OutputPath "C:\Reports\MFA_Report.csv"
    
    Exports MFA status for specific users to a custom location.

.EXAMPLE
    .\Export-AADUserMFAStatus.ps1 -CsvPath "C:\Input\Users.csv" -Verbose
    
    Imports user list from CSV and exports MFA status with verbose output.

.EXAMPLE
    .\Export-AADUserMFAStatus.ps1 -Interactive
    
    Launches interactive mode for entering user principal names manually.

.NOTES
    Author: Bill Kindle (with AI assistance)
    Version: 2.0.0
    Created: 2023-03-06
    Updated: 2025-11-22
    
    Required Permissions:
    - For MSOnline: User Administrator or Global Reader role
    - For Microsoft Graph: UserAuthenticationMethod.Read.All, User.Read.All
    
    Required Modules:
    - MSOnline (legacy, being deprecated) OR
    - Microsoft.Graph.Authentication + Microsoft.Graph.Users + Microsoft.Graph.Identity.SignIns
    
    Setup Instructions:
    1. Install required module(s):
       # Option 1: Modern Graph API (Recommended)
       Install-Module Microsoft.Graph -Scope CurrentUser -Force
       
       # Option 2: Legacy MSOnline (Deprecated)
       Install-Module MSOnline -Scope CurrentUser -Force
    
    2. Connect to service:
       # Graph API
       Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All","User.Read.All"
       
       # MSOnline
       Connect-MsolService
    
    3. Run the script with desired parameters
    
    Version History:
    2.0.0 - 2025-11-22 - Complete rewrite following PowerShell best practices:
                         - Added Microsoft Graph API support with automatic fallback
                         - Implemented multiple input methods (array, CSV, interactive, all users)
                         - Added comprehensive parameter validation
                         - Improved error handling and progress reporting
                         - Used Generic List for better performance
                         - Added support for disabled users inclusion
                         - Custom output path support with timestamped default
                         - Restructured with helper functions and regions
                         - Added Write-Status function for consistent output
                         - Enhanced documentation and examples
    1.0.0 - 2023-03-06 - Initial version with basic MSOnline support
    
    References:
    - Microsoft Graph Authentication Methods: https://learn.microsoft.com/graph/api/authentication-list-methods
    - MSOnline MFA Management: https://woshub.com/enable-disable-mfa-azure-users/
    - MSOnline Deprecation Notice: https://learn.microsoft.com/entra/identity/users/users-search-enhanced
#>

#Requires -Version 5.1

[CmdletBinding(DefaultParameterSetName = 'AllUsers')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'SpecificUsers')]
    [ValidateNotNullOrEmpty()]
    [string[]]$UserPrincipalNames,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'CSV')]
    [ValidateScript({
        if (-not (Test-Path $_ -PathType Leaf)) {
            throw "CSV file not found: $_"
        }
        if ($_ -notmatch '\.csv$') {
            throw "File must have .csv extension"
        }
        return $true
    })]
    [string]$CsvPath,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
    [switch]$Interactive,
    
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        $directory = Split-Path $_ -Parent
        if ($directory -and -not (Test-Path $directory)) {
            throw "Output directory does not exist: $directory"
        }
        if ($_ -notmatch '\.csv$') {
            throw "Output file must have .csv extension"
        }
        return $true
    })]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseGraphAPI,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDisabledUsers
)

#region Helper Functions

function Write-Status {
    <#
    .SYNOPSIS
        Outputs standardized status messages with level indicators.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'OK', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $prefix = switch ($Level) {
        'OK'      { '[OK]' }
        'Error'   { '[ERROR]' }
        'Warning' { '[WARN]' }
        'Info'    { '[INFO]' }
        'Debug'   { '[DEBUG]' }
    }
    
    Write-Information "$prefix $Message" -Tags $Level, 'Status' -InformationAction Continue
}

function Initialize-AuthenticationMethod {
    <#
    .SYNOPSIS
        Determines and initializes the appropriate authentication method (Graph or MSOnline).
    #>
    [CmdletBinding()]
    param(
        [switch]$PreferGraph
    )
    
    $authMethod = $null
    
    # Check for Microsoft Graph modules
    $hasGraphAuth = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication
    $hasGraphUsers = Get-Module -ListAvailable -Name Microsoft.Graph.Users
    $hasGraphIdentity = Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns
    
    # Check for MSOnline module
    $hasMSOnline = Get-Module -ListAvailable -Name MSOnline
    
    if ($PreferGraph -or -not $hasMSOnline) {
        if ($hasGraphAuth -and $hasGraphUsers) {
            Write-Verbose "Microsoft Graph modules detected"
            
            # Check if already connected
            $context = Get-MgContext -ErrorAction SilentlyContinue
            if (-not $context) {
                Write-Status "Connecting to Microsoft Graph..." -Level Warning
                try {
                    Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All", "User.Read.All" -ErrorAction Stop
                    Write-Status "Successfully connected to Microsoft Graph" -Level OK
                }
                catch {
                    throw "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
                }
            }
            else {
                Write-Status "Microsoft Graph connection verified" -Level OK
            }
            $authMethod = 'Graph'
        }
        elseif ($hasMSOnline) {
            Write-Status "Microsoft Graph modules not available, falling back to MSOnline" -Level Warning
            $authMethod = 'MSOnline'
        }
        else {
            throw "No compatible modules found. Install either Microsoft.Graph or MSOnline module."
        }
    }
    else {
        $authMethod = 'MSOnline'
    }
    
    # Initialize MSOnline if selected
    if ($authMethod -eq 'MSOnline') {
        Write-Verbose "Using MSOnline module (legacy)"
        try {
            Get-MsolDomain -ErrorAction Stop | Out-Null
            Write-Status "MSOnline connection verified" -Level OK
        }
        catch {
            Write-Status "Connecting to MSOnline service..." -Level Warning
            try {
                Connect-MsolService -ErrorAction Stop
                Write-Status "Successfully connected to MSOnline" -Level OK
            }
            catch {
                throw "Failed to connect to MSOnline: $($_.Exception.Message)"
            }
        }
    }
    
    return $authMethod
}

function Get-InteractiveUserInput {
    <#
    .SYNOPSIS
        Prompts user for UPN input in interactive mode.
    #>
    [CmdletBinding()]
    param()
    
    Write-Status "=== Interactive Mode ===" -Level Info
    Write-Status "Enter user principal names (email addresses). Type 'done' when finished." -Level Info
    
    $upns = [System.Collections.Generic.List[string]]::new()
    
    do {
        $input = Read-Host "User Principal Name (or 'done' to finish)"
        if ($input -ne 'done' -and -not [string]::IsNullOrWhiteSpace($input)) {
            # Basic email format validation
            if ($input -match '^[^@]+@[^@]+\.[^@]+$') {
                $upns.Add($input)
                Write-Status "Added: $input" -Level OK
            }
            else {
                Write-Status "Invalid email format: $input" -Level Warning
            }
        }
    } while ($input -ne 'done')
    
    if ($upns.Count -eq 0) {
        throw "No valid user principal names provided"
    }
    
    return $upns.ToArray()
}

function Get-MFAStatusMSOnline {
    <#
    .SYNOPSIS
        Retrieves MFA status using MSOnline module.
    #>
    [CmdletBinding()]
    param(
        [string[]]$UserPrincipalNames,
        [switch]$AllUsers,
        [switch]$IncludeDisabled
    )
    
    try {
        if ($AllUsers) {
            Write-Status "Retrieving all users from MSOnline..." -Level Info
            if ($IncludeDisabled) {
                $users = Get-MsolUser -All -ErrorAction Stop
            }
            else {
                $users = Get-MsolUser -All -ErrorAction Stop | Where-Object { $_.BlockCredential -eq $false }
            }
        }
        else {
            Write-Status "Retrieving specific users from MSOnline..." -Level Info
            $users = [System.Collections.Generic.List[object]]::new()
            foreach ($upn in $UserPrincipalNames) {
                try {
                    $user = Get-MsolUser -UserPrincipalName $upn -ErrorAction Stop
                    $users.Add($user)
                }
                catch {
                    Write-Status "User not found: $upn" -Level Warning
                }
            }
        }
        
        Write-Status "Found $($users.Count) user(s)" -Level Info
        
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
        $i = 0
        
        foreach ($user in $users) {
            $i++
            Write-Progress -Activity "Processing MFA Status" -Status "Processing $($user.UserPrincipalName)" -PercentComplete (($i / $users.Count) * 100)
            
            $defaultMethod = ($user.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq $true }).MethodType
            $mfaState = $user.StrongAuthenticationRequirements.State
            
            if ([string]::IsNullOrEmpty($mfaState)) {
                $mfaState = "Disabled"
            }
            
            $allMethods = ($user.StrongAuthenticationMethods | ForEach-Object { $_.MethodType }) -join ', '
            if ([string]::IsNullOrEmpty($allMethods)) {
                $allMethods = "None"
            }
            
            $result = [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                DisplayName       = $user.DisplayName
                MFAStatus         = $mfaState
                DefaultMethod     = if ($defaultMethod) { $defaultMethod } else { "None" }
                PhoneNumber       = $user.StrongAuthenticationUserDetails.PhoneNumber
                RegisteredMethods = $allMethods
                IsEnabled         = -not $user.BlockCredential
                Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            $results.Add($result)
        }
        
        Write-Progress -Activity "Processing MFA Status" -Completed
        return $results
    }
    catch {
        throw "Failed to retrieve MFA status via MSOnline: $($_.Exception.Message)"
    }
}

function Get-MFAStatusGraph {
    <#
    .SYNOPSIS
        Retrieves MFA status using Microsoft Graph API.
    #>
    [CmdletBinding()]
    param(
        [string[]]$UserPrincipalNames,
        [switch]$AllUsers,
        [switch]$IncludeDisabled
    )
    
    try {
        if ($AllUsers) {
            Write-Status "Retrieving all users from Microsoft Graph..." -Level Info
            if ($IncludeDisabled) {
                $users = Get-MgUser -All -Property Id,UserPrincipalName,DisplayName,AccountEnabled -ErrorAction Stop
            }
            else {
                $users = Get-MgUser -All -Property Id,UserPrincipalName,DisplayName,AccountEnabled -Filter "accountEnabled eq true" -ErrorAction Stop
            }
        }
        else {
            Write-Status "Retrieving specific users from Microsoft Graph..." -Level Info
            $users = [System.Collections.Generic.List[object]]::new()
            foreach ($upn in $UserPrincipalNames) {
                try {
                    $user = Get-MgUser -UserId $upn -Property Id,UserPrincipalName,DisplayName,AccountEnabled -ErrorAction Stop
                    $users.Add($user)
                }
                catch {
                    Write-Status "User not found: $upn" -Level Warning
                }
            }
        }
        
        Write-Status "Found $($users.Count) user(s)" -Level Info
        
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
        $i = 0
        
        foreach ($user in $users) {
            $i++
            Write-Progress -Activity "Processing MFA Status" -Status "Processing $($user.UserPrincipalName)" -PercentComplete (($i / $users.Count) * 100)
            
            try {
                # Get authentication methods
                $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
                
                # Determine MFA status based on registered methods
                $registeredMethods = @()
                $phoneNumber = "None"
                
                foreach ($method in $authMethods) {
                    $methodType = $method.AdditionalProperties.'@odata.type'
                    switch -Wildcard ($methodType) {
                        '*phoneAuthenticationMethod' { 
                            $registeredMethods += "Phone"
                            if ($method.AdditionalProperties.phoneNumber) {
                                $phoneNumber = $method.AdditionalProperties.phoneNumber
                            }
                        }
                        '*microsoftAuthenticatorAuthenticationMethod' { $registeredMethods += "Authenticator App" }
                        '*fido2AuthenticationMethod' { $registeredMethods += "FIDO2 Security Key" }
                        '*softwareOathAuthenticationMethod' { $registeredMethods += "Software Token" }
                        '*emailAuthenticationMethod' { $registeredMethods += "Email" }
                    }
                }
                
                $mfaStatus = if ($registeredMethods.Count -gt 0) { "Enabled" } else { "Disabled" }
                $methodsList = if ($registeredMethods.Count -gt 0) { $registeredMethods -join ', ' } else { "None" }
                $defaultMethod = if ($registeredMethods.Count -gt 0) { $registeredMethods[0] } else { "None" }
                
                $result = [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    DisplayName       = $user.DisplayName
                    MFAStatus         = $mfaStatus
                    DefaultMethod     = $defaultMethod
                    PhoneNumber       = $phoneNumber
                    RegisteredMethods = $methodsList
                    IsEnabled         = $user.AccountEnabled
                    Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                $results.Add($result)
            }
            catch {
                Write-Status "Failed to retrieve MFA details for $($user.UserPrincipalName): $($_.Exception.Message)" -Level Warning
                
                # Add entry with error
                $result = [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    DisplayName       = $user.DisplayName
                    MFAStatus         = "Error"
                    DefaultMethod     = "Error retrieving data"
                    PhoneNumber       = "N/A"
                    RegisteredMethods = "Error"
                    IsEnabled         = $user.AccountEnabled
                    Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                $results.Add($result)
            }
        }
        
        Write-Progress -Activity "Processing MFA Status" -Completed
        return $results
    }
    catch {
        throw "Failed to retrieve MFA status via Microsoft Graph: $($_.Exception.Message)"
    }
}

#endregion

#region Main Execution

try {
    Write-Status "=== MFA Status Export Script ===" -Level Info
    Write-Status "Version: 2.0.0" -Level Info
    
    # Determine authentication method
    $authMethod = Initialize-AuthenticationMethod -PreferGraph:$UseGraphAPI
    Write-Status "Using authentication method: $authMethod" -Level Info
    
    # Determine input source
    $usersToQuery = $null
    $queryAllUsers = $false
    
    switch ($PSCmdlet.ParameterSetName) {
        'AllUsers' {
            Write-Status "Mode: All Users" -Level Info
            $queryAllUsers = $true
        }
        'SpecificUsers' {
            Write-Status "Mode: Specific Users ($($UserPrincipalNames.Count))" -Level Info
            $usersToQuery = $UserPrincipalNames
        }
        'CSV' {
            Write-Status "Mode: CSV Input" -Level Info
            Write-Status "Reading CSV file: $CsvPath" -Level Info
            try {
                $csvData = Import-Csv -Path $CsvPath -ErrorAction Stop
                if (-not $csvData.UserPrincipalName) {
                    throw "CSV must contain 'UserPrincipalName' column"
                }
                $usersToQuery = $csvData.UserPrincipalName
                Write-Status "Loaded $($usersToQuery.Count) user(s) from CSV" -Level OK
            }
            catch {
                throw "Failed to read CSV file: $($_.Exception.Message)"
            }
        }
        'Interactive' {
            Write-Status "Mode: Interactive" -Level Info
            $usersToQuery = Get-InteractiveUserInput
            Write-Status "Collected $($usersToQuery.Count) user(s)" -Level OK
        }
    }
    
    # Set default output path if not specified
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputPath = Join-Path (Get-Location) "MFA_Status_Report_$timestamp.csv"
    }
    
    Write-Status "Output will be saved to: $OutputPath" -Level Info
    
    if ($IncludeDisabledUsers) {
        Write-Status "Including disabled user accounts" -Level Info
    }
    
    # Retrieve MFA status based on authentication method
    Write-Status "=== Retrieving MFA Status ===" -Level Info
    
    if ($authMethod -eq 'Graph') {
        if ($queryAllUsers) {
            $mfaReport = Get-MFAStatusGraph -AllUsers -IncludeDisabled:$IncludeDisabledUsers
        }
        else {
            $mfaReport = Get-MFAStatusGraph -UserPrincipalNames $usersToQuery -IncludeDisabled:$IncludeDisabledUsers
        }
    }
    else {
        if ($queryAllUsers) {
            $mfaReport = Get-MFAStatusMSOnline -AllUsers -IncludeDisabled:$IncludeDisabledUsers
        }
        else {
            $mfaReport = Get-MFAStatusMSOnline -UserPrincipalNames $usersToQuery -IncludeDisabled:$IncludeDisabledUsers
        }
    }
    
    # Export results
    Write-Status "=== Exporting Results ===" -Level Info
    
    try {
        $mfaReport | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Status "Successfully exported $($mfaReport.Count) record(s) to: $OutputPath" -Level OK
    }
    catch {
        throw "Failed to export CSV: $($_.Exception.Message)"
    }
    
    # Summary statistics
    Write-Status "=== Summary ===" -Level Info
    $enabled = ($mfaReport | Where-Object { $_.MFAStatus -eq 'Enabled' -or $_.MFAStatus -eq 'Enforced' }).Count
    $disabled = ($mfaReport | Where-Object { $_.MFAStatus -eq 'Disabled' }).Count
    $total = $mfaReport.Count
    
    Write-Status "Total Users: $total" -Level Info
    Write-Status "MFA Enabled/Enforced: $enabled" -Level (if ($enabled -gt 0) { 'OK' } else { 'Info' })
    Write-Status "MFA Disabled: $disabled" -Level (if ($disabled -gt 0) { 'Warning' } else { 'Info' })
    
    if ($disabled -gt 0) {
        $percentage = [math]::Round(($disabled / $total) * 100, 1)
        Write-Status "WARNING: $percentage% of users do not have MFA enabled" -Level Warning
    }
    
    Write-Status "Script execution completed successfully" -Level OK
}
catch {
    Write-Status "Script execution failed: $($_.Exception.Message)" -Level Error
    throw
}

#endregion