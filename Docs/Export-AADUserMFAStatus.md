# Export-AADUserMFAStatus

Exports Multi-Factor Authentication (MFA) status for Microsoft Entra ID (Azure AD) users with comprehensive reporting capabilities.

## Synopsis

This script retrieves and exports detailed MFA status information for Microsoft Entra ID users. It supports both modern Microsoft Graph API and legacy MSOnline (MSOL) authentication methods, providing flexibility for different environments. The script is designed for security audits, compliance reporting, and MFA deployment tracking.

Key capabilities:
- Dual API support: Microsoft Graph (recommended) and MSOnline (legacy)
- Multiple input methods: All users, specific users, CSV import, or interactive prompts
- Comprehensive MFA details including status, methods, and phone numbers
- Flexible output options with timestamped filenames
- Progress tracking and detailed status reporting
- Security summary statistics with warnings for disabled MFA

## Requirements

- **PowerShell Version**: 5.1 or later (7+ recommended)
- **Modules** (choose one):
  - **Option 1 (Recommended)**: Microsoft Graph modules
    - `Microsoft.Graph.Authentication` (version 2.0+)
    - `Microsoft.Graph.Users` (version 2.0+)
    - `Microsoft.Graph.Identity.SignIns` (version 2.0+)
  - **Option 2 (Legacy)**: MSOnline module
    - `MSOnline` (version 1.1+)
- **Permissions**:
  - **For Microsoft Graph**: 
    - `UserAuthenticationMethod.Read.All`
    - `User.Read.All`
  - **For MSOnline**: 
    - User Administrator or Global Reader role in Microsoft 365
- **Platform**: Windows, Linux, macOS (Graph API); Windows only (MSOnline)

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| UserPrincipalNames | String[] | No* | N/A | Array of specific user email addresses to query. Use when checking specific users instead of all users. |
| CsvPath | String | No* | N/A | Path to CSV file containing UserPrincipalName column. Must have .csv extension and file must exist. |
| Interactive | Switch | No* | False | Launches interactive mode with prompts for entering user principal names manually. |
| OutputPath | String | No | `.\MFA_Status_Report_YYYYMMDD_HHMMSS.csv` | Full path where the CSV report will be saved. Must have .csv extension. If not specified, creates timestamped file in current directory. |
| UseGraphAPI | Switch | No | False | Forces use of Microsoft Graph API instead of MSOnline. Recommended for modern environments as MSOnline is being deprecated. |
| IncludeDisabledUsers | Switch | No | False | Includes disabled user accounts in the report. By default, only enabled users are included. |

*Note: Parameter sets are mutually exclusive. If no input parameter is specified, all users are queried by default.

## Examples

### Example 1: Export All Users (Default)
```powershell
.\Export-AADUserMFAStatus.ps1
```

Exports MFA status for all enabled users using available authentication method (Graph or MSOnline).

**Expected Output:**
```
[INFO] === MFA Status Export Script ===
[INFO] Version: 2.0.0
[INFO] Using authentication method: MSOnline
[OK] MSOnline connection verified
[INFO] Mode: All Users
[INFO] Output will be saved to: .\MFA_Status_Report_20251122_143022.csv
[INFO] === Retrieving MFA Status ===
[INFO] Retrieving all users from MSOnline...
[INFO] Found 150 user(s)
[OK] Successfully exported 150 record(s) to: .\MFA_Status_Report_20251122_143022.csv
[INFO] === Summary ===
[INFO] Total Users: 150
[OK] MFA Enabled/Enforced: 142
[WARN] MFA Disabled: 8
[WARN] WARNING: 5.3% of users do not have MFA enabled
[OK] Script execution completed successfully
```

### Example 2: Use Microsoft Graph API with Disabled Users
```powershell
.\Export-AADUserMFAStatus.ps1 -UseGraphAPI -IncludeDisabledUsers
```

Forces Microsoft Graph API usage and includes disabled accounts in the export.

**Output:** CSV contains both enabled and disabled accounts with complete MFA status.

### Example 3: Specific Users with Custom Output Path
```powershell
.\Export-AADUserMFAStatus.ps1 -UserPrincipalNames @("john.doe@contoso.com","jane.smith@contoso.com") -OutputPath "C:\Reports\MFA_Audit.csv"
```

Exports MFA status for two specific users to a custom location.

**CSV Output:**
```csv
UserPrincipalName,DisplayName,MFAStatus,DefaultMethod,PhoneNumber,RegisteredMethods,IsEnabled,Timestamp
john.doe@contoso.com,John Doe,Enabled,Authenticator App,+1234567890,"Phone, Authenticator App",True,2025-11-22 14:30:22
jane.smith@contoso.com,Jane Smith,Disabled,None,,"None",True,2025-11-22 14:30:23
```

### Example 4: Import from CSV File
```powershell
.\Export-AADUserMFAStatus.ps1 -CsvPath "C:\Input\Users.csv" -Verbose
```

Imports user list from CSV file and exports MFA status with verbose logging.

**Required CSV Format:**
```csv
UserPrincipalName
user1@contoso.com
user2@contoso.com
user3@contoso.com
```

### Example 5: Interactive Mode
```powershell
.\Export-AADUserMFAStatus.ps1 -Interactive
```

Launches interactive mode for manual user entry.

**Interactive Session:**
```
[INFO] === Interactive Mode ===
[INFO] Enter user principal names (email addresses). Type 'done' when finished.
User Principal Name (or 'done' to finish): john.doe@contoso.com
[OK] Added: john.doe@contoso.com
User Principal Name (or 'done' to finish): invalid-email
[WARN] Invalid email format: invalid-email
User Principal Name (or 'done' to finish): jane.smith@contoso.com
[OK] Added: jane.smith@contoso.com
User Principal Name (or 'done' to finish): done
[OK] Collected 2 user(s)
```

### Example 6: Schedule Daily MFA Report
```powershell
# Create scheduled task to run daily MFA audit
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\Scripts\Export-AADUserMFAStatus.ps1 -OutputPath C:\Reports\Daily_MFA_$(Get-Date -Format 'yyyyMMdd').csv"
$trigger = New-ScheduledTaskTrigger -Daily -At 6:00AM
Register-ScheduledTask -TaskName "Daily MFA Report" -Action $action -Trigger $trigger
```

Schedules daily automated MFA status reports.

### Example 7: Compare MFA Status Over Time
```powershell
# Week 1
.\Export-AADUserMFAStatus.ps1 -OutputPath "C:\Audit\MFA_Week1.csv"

# Week 2
.\Export-AADUserMFAStatus.ps1 -OutputPath "C:\Audit\MFA_Week2.csv"

# Compare changes
$week1 = Import-Csv "C:\Audit\MFA_Week1.csv"
$week2 = Import-Csv "C:\Audit\MFA_Week2.csv"

Compare-Object $week1 $week2 -Property UserPrincipalName,MFAStatus
```

Tracks MFA deployment progress over time.

## Setup Instructions

### Option 1: Microsoft Graph API (Recommended)

1. **Install Microsoft Graph modules**:
   ```powershell
   # Install all Graph modules
   Install-Module Microsoft.Graph -Scope CurrentUser -Force
   
   # Or install specific required modules
   Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
   Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force
   Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force
   ```

2. **Connect to Microsoft Graph**:
   ```powershell
   # Interactive authentication
   Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All","User.Read.All"
   
   # Verify connection
   Get-MgContext
   ```

3. **Run the script**:
   ```powershell
   .\Export-AADUserMFAStatus.ps1 -UseGraphAPI
   ```

### Option 2: MSOnline (Legacy)

1. **Install MSOnline module**:
   ```powershell
   Install-Module MSOnline -Scope CurrentUser -Force
   ```

2. **Connect to MSOnline**:
   ```powershell
   Connect-MsolService
   ```

3. **Run the script**:
   ```powershell
   .\Export-AADUserMFAStatus.ps1
   ```

### Azure App Registration (For Automated/Scheduled Runs)

1. **Register an app in Azure AD**:
   - Navigate to Azure Portal > Azure Active Directory > App registrations
   - Click "New registration"
   - Name: "MFA Status Reporter"
   - Supported account types: Single tenant

2. **Configure API permissions**:
   - Add Microsoft Graph permissions:
     - `UserAuthenticationMethod.Read.All` (Application)
     - `User.Read.All` (Application)
   - Grant admin consent

3. **Create client secret**:
   - Certificates & secrets > New client secret
   - Save the secret value securely

4. **Use in script**:
   ```powershell
   $clientId = "your-client-id"
   $tenantId = "your-tenant-id"
   $clientSecret = ConvertTo-SecureString "your-secret" -AsPlainText -Force
   $credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)
   
   Connect-MgGraph -ClientId $clientId -TenantId $tenantId -ClientSecretCredential $credential
   .\Export-AADUserMFAStatus.ps1 -UseGraphAPI
   ```

## Output

The script exports a CSV file with the following columns:

### Output Columns

| Column | Description | Example Values |
|--------|-------------|----------------|
| UserPrincipalName | User's email address (UPN) | john.doe@contoso.com |
| DisplayName | User's display name | John Doe |
| MFAStatus | Current MFA state | Enabled, Enforced, Disabled |
| DefaultMethod | Primary MFA method | Authenticator App, Phone, FIDO2 Security Key |
| PhoneNumber | Registered MFA phone number | +1 (555) 123-4567 |
| RegisteredMethods | All registered MFA methods | Phone, Authenticator App, Email |
| IsEnabled | Account enabled status | True, False |
| Timestamp | Report generation time | 2025-11-22 14:30:22 |

### MFA Status Values

- **Enabled**: MFA is configured and active for the user
- **Enforced**: MFA is enforced by conditional access policies
- **Disabled**: MFA is not configured or active

### Method Types

**Microsoft Graph API Methods:**
- Phone
- Authenticator App
- FIDO2 Security Key
- Software Token
- Email

**MSOnline Methods:**
- OneWaySMS
- TwoWayVoiceMobile
- PhoneAppOTP
- PhoneAppNotification

### Example CSV Output
```csv
UserPrincipalName,DisplayName,MFAStatus,DefaultMethod,PhoneNumber,RegisteredMethods,IsEnabled,Timestamp
john.doe@contoso.com,John Doe,Enabled,Authenticator App,+15551234567,"Phone, Authenticator App",True,2025-11-22 14:30:22
jane.smith@contoso.com,Jane Smith,Enforced,FIDO2 Security Key,,"FIDO2 Security Key, Authenticator App",True,2025-11-22 14:30:23
bob.jones@contoso.com,Bob Jones,Disabled,None,,"None",True,2025-11-22 14:30:24
alice.williams@contoso.com,Alice Williams,Enabled,Phone,+15559876543,Phone,False,2025-11-22 14:30:25
```

## Error Handling

### Common Errors

**Error: "No compatible modules found"**
- **Cause**: Neither Microsoft.Graph nor MSOnline modules are installed
- **Solution**: Install at least one module:
  ```powershell
  # Recommended
  Install-Module Microsoft.Graph -Force
  
  # Or legacy
  Install-Module MSOnline -Force
  ```

**Error: "Failed to connect to Microsoft Graph/MSOnline"**
- **Cause**: Authentication failed or insufficient permissions
- **Solution**: 
  1. Verify credentials are correct
  2. Check required permissions are granted
  3. For Graph, ensure admin consent is provided
  4. Re-authenticate: `Connect-MgGraph` or `Connect-MsolService`

**Error: "CSV must contain 'UserPrincipalName' column"**
- **Cause**: Input CSV file has incorrect column name
- **Solution**: Ensure CSV has a column named exactly `UserPrincipalName` (case-sensitive)

**Error: "Output directory does not exist"**
- **Cause**: Specified output path directory doesn't exist
- **Solution**: Create directory first or use valid path:
  ```powershell
  New-Item -Path "C:\Reports" -ItemType Directory -Force
  .\Export-AADUserMFAStatus.ps1 -OutputPath "C:\Reports\MFA_Report.csv"
  ```

**Warning: "User not found: user@domain.com"**
- **Cause**: Specified user doesn't exist in tenant
- **Solution**: Verify UPN is correct. Script continues processing remaining users.

**Error: "Failed to retrieve MFA details for user"**
- **Cause**: Permissions issue or transient API error
- **Solution**: 
  1. Verify required permissions are granted
  2. Check user account is valid
  3. Script adds entry with "Error" status and continues

### Troubleshooting

#### MSOnline Module Deprecated Warning

Microsoft is deprecating MSOnline module. If you see warnings:

```powershell
# Migrate to Microsoft Graph
.\Export-AADUserMFAStatus.ps1 -UseGraphAPI
```

#### Graph API Returns "Error" for Some Users

Check delegated vs application permissions:
```powershell
# View current permissions
Get-MgContext | Select-Object -ExpandProperty Scopes

# Reconnect with correct scopes
Disconnect-MgGraph
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All","User.Read.All"
```

#### Slow Performance with Large Tenants

For tenants with 10,000+ users:
```powershell
# Query specific users or use CSV
.\Export-AADUserMFAStatus.ps1 -CsvPath "C:\Input\PriorityUsers.csv"

# Or schedule during off-hours
# Process runs in background with progress tracking
```

#### CSV Export Encoding Issues

If CSV has encoding problems:
```powershell
# The script uses UTF-8 encoding by default
# Import with matching encoding
$data = Import-Csv -Path ".\MFA_Status_Report.csv" -Encoding UTF8
```

## Notes

### Important Limitations

- **MSOnline Deprecation**: MSOnline module is being deprecated by Microsoft. Migrate to Microsoft Graph API for future-proof solution.
- **Rate Limiting**: Microsoft Graph API has throttling limits. For very large tenants (50,000+ users), consider batching or scheduling during off-peak hours.
- **Conditional Access**: The script reports MFA registration status, not enforcement. Users may be required to use MFA via Conditional Access policies even if not "Enforced" in the report.
- **External Users**: Guest/external users may have limited MFA information available depending on their home tenant.

### Security Considerations

- **Sensitive Information**: Report contains phone numbers and security method information. Store reports securely and limit access.
- **Least Privilege**: Use read-only permissions. Script doesn't require write access to user accounts.
- **Credential Storage**: Never hardcode credentials. Use secure credential managers or Azure Key Vault for automation scenarios.
- **Audit Trail**: Script generates timestamped reports suitable for compliance audits.

### Performance Characteristics

- **Small tenants** (< 1,000 users): ~30-60 seconds
- **Medium tenants** (1,000-10,000 users): ~3-10 minutes
- **Large tenants** (10,000+ users): ~15-30 minutes
- **Memory usage**: ~100-200MB for typical workloads

Progress bars provide real-time status during execution.

### Cross-Platform Considerations

**Microsoft Graph API:**
- ✅ Windows (PowerShell 5.1 and 7+)
- ✅ Linux (PowerShell 7+)
- ✅ macOS (PowerShell 7+)

**MSOnline Module:**
- ✅ Windows only
- ❌ Not supported on Linux/macOS

For cross-platform compatibility, use `-UseGraphAPI` parameter.

### Compliance & Auditing

This script is suitable for:
- **SOC 2 Compliance**: Track MFA deployment as security control
- **ISO 27001**: Evidence of access control implementation
- **NIST Frameworks**: Multi-factor authentication monitoring
- **Internal Audits**: Regular security posture assessments
- **Board Reporting**: Executive dashboards on security metrics

Timestamped reports provide point-in-time snapshots for historical comparison.

## Version History

- **2.0.0** (2025-11-22) - Complete rewrite following PowerShell best practices:
  - Added Microsoft Graph API support with automatic fallback
  - Implemented multiple input methods (array, CSV, interactive, all users)
  - Added comprehensive parameter validation with parameter sets
  - Improved error handling and progress reporting
  - Used Generic List for better performance
  - Added support for disabled users inclusion
  - Custom output path support with timestamped default filenames
  - Restructured with helper functions and regions
  - Added Write-Status function for consistent output
  - Enhanced documentation with 7+ examples
  - Added security summary statistics with warnings
  - Cross-platform support with Microsoft Graph
  - Breaking change: Changed from function to script format

- **1.0.0** (2023-03-06) - Initial version
  - Basic MSOnline module support
  - Simple all-user export
  - Fixed output filename
  - Limited error handling

## Author

Bill Kindle (with AI assistance)

## License

See [LICENSE](LICENSE) file in repository root.

## References

- [Microsoft Graph Authentication Methods API](https://learn.microsoft.com/graph/api/authentication-list-methods)
- [MSOnline MFA Management](https://woshub.com/enable-disable-mfa-azure-users/)
- [MSOnline Deprecation Notice](https://learn.microsoft.com/entra/identity/users/users-search-enhanced)
- [Azure AD MFA Documentation](https://learn.microsoft.com/azure/active-directory/authentication/concept-mfa-howitworks)
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph/overview)

## Related Scripts

- `Get-AADUserSignInLogs.ps1` - Analyze sign-in activity
- `Enable-AADUserMFA.ps1` - Bulk enable MFA for users
- `Get-AADConditionalAccessPolicies.ps1` - Review MFA enforcement policies

## Additional Examples

### Generate Monthly Compliance Report
```powershell
# Schedule monthly MFA compliance report
$reportPath = "C:\Compliance\MFA_Report_$(Get-Date -Format 'yyyy-MM').csv"
.\Export-AADUserMFAStatus.ps1 -UseGraphAPI -OutputPath $reportPath

# Email report to security team
$report = Import-Csv $reportPath
$disabledCount = ($report | Where-Object { $_.MFAStatus -eq 'Disabled' }).Count
$body = "Monthly MFA Report: $disabledCount users without MFA enabled. See attached report."
Send-MailMessage -To "security@contoso.com" -Subject "MFA Compliance Report" -Body $body -Attachments $reportPath
```

### Integration with Azure Automation
```powershell
# Azure Automation Runbook example
param([string]$StorageAccountName, [string]$ContainerName)

# Authenticate with managed identity
Connect-AzAccount -Identity
Connect-MgGraph -Identity

# Run MFA export
.\Export-AADUserMFAStatus.ps1 -UseGraphAPI -OutputPath "C:\temp\mfa_report.csv"

# Upload to Azure Storage
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
Set-AzStorageBlobContent -File "C:\temp\mfa_report.csv" -Container $ContainerName -Context $ctx
```

### Filter High-Risk Accounts
```powershell
# Export MFA status
.\Export-AADUserMFAStatus.ps1 -OutputPath "C:\Reports\MFA_Status.csv"

# Identify high-risk accounts (admins without MFA)
$report = Import-Csv "C:\Reports\MFA_Status.csv"
$admins = Get-MgDirectoryRoleMember -DirectoryRoleId (Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'").Id
$riskyAdmins = $report | Where-Object { 
    $_.UserPrincipalName -in $admins.AdditionalProperties.userPrincipalName -and 
    $_.MFAStatus -eq 'Disabled' 
}

if ($riskyAdmins) {
    Write-Warning "CRITICAL: $($riskyAdmins.Count) admin account(s) without MFA!"
    $riskyAdmins | Format-Table UserPrincipalName, DisplayName
}
```
