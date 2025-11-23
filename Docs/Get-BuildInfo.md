# Get-BuildInfo

Retrieves comprehensive Windows build and version information from the local system.

## Synopsis

This script collects detailed information about the Windows operating system including version numbers, edition, build details, installation date, and Windows Feature Experience Pack version. It provides a structured way to gather system information for documentation, troubleshooting, or inventory purposes.

Key capabilities:
- Retrieves Windows version, edition, and build numbers
- Provides installation date and time
- Reports Windows Feature Experience Pack version
- Optional system information (computer name, boot time, PowerShell version)
- Supports both object and JSON output formats
- Compatible with Windows PowerShell 5.1 and PowerShell 7+

## Requirements

- **PowerShell Version**: 5.1 or later (7+ recommended)
- **Modules**: 
  - `Appx` (built-in on Windows, optional for Experience Pack version)
- **Permissions**: 
  - Standard user permissions (no elevation required)
  - Registry read access to `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`
- **Platform**: Windows only (not compatible with Linux/macOS)

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| AsJson | Switch | No | False | Outputs the build information as formatted JSON instead of a PSCustomObject |
| IncludeSystemInfo | Switch | No | False | Includes additional system information such as computer name, last boot time, and PowerShell version details |

## Examples

### Example 1: Basic Usage
```powershell
.\Get-BuildInfo.ps1
```

Displays Windows build information as a PowerShell object with the following properties:

```
Version        : 23H2
Edition        : Windows 11 Pro
OSBuild        : 22631.4602
ReleaseId      : 2009
InstalledOn    : 2024-01-15 10:30:45
ExperiencePack : 1000.22700.1000.0
```

### Example 2: JSON Output
```powershell
.\Get-BuildInfo.ps1 -AsJson
```

Returns the build information formatted as JSON, useful for logging or integration with other tools:

```json
{
  "Version": "23H2",
  "Edition": "Windows 11 Pro",
  "OSBuild": "22631.4602",
  "ReleaseId": "2009",
  "InstalledOn": "2024-01-15 10:30:45",
  "ExperiencePack": "1000.22700.1000.0"
}
```

### Example 3: Include Additional System Information
```powershell
.\Get-BuildInfo.ps1 -IncludeSystemInfo
```

Displays extended information including computer name, PowerShell version, and last boot time:

```
Version           : 23H2
Edition           : Windows 11 Pro
OSBuild           : 22631.4602
ReleaseId         : 2009
InstalledOn       : 2024-01-15 10:30:45
ExperiencePack    : 1000.22700.1000.0
ComputerName      : WORKSTATION01
PowerShellVersion : 7.4.6
PowerShellEdition : Core
LastBootTime      : 2025-11-22 08:15:30
```

### Example 4: Export to File
```powershell
.\Get-BuildInfo.ps1 -IncludeSystemInfo | Export-Csv -Path "C:\Reports\SystemInfo.csv" -NoTypeInformation
```

Exports the build information to a CSV file for documentation or reporting purposes.

### Example 5: Use with Verbose Output
```powershell
.\Get-BuildInfo.ps1 -Verbose
```

Shows detailed progress information during execution, useful for troubleshooting.

## Setup Instructions

1. **Download the script**:
   ```powershell
   # Clone the repository or download Get-BuildInfo.ps1
   ```

2. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the script**:
   ```powershell
   .\Get-BuildInfo.ps1
   ```

No additional modules need to be installed as all dependencies are built into Windows.

## Output

The script returns a PSCustomObject with the following properties:

### Standard Output Properties

- **Version**: Windows display version (e.g., "23H2", "22H2")
- **Edition**: Full Windows product name (e.g., "Windows 11 Pro", "Windows Server 2022 Standard")
- **OSBuild**: Complete build number in format "build.revision" (e.g., "22631.4602")
- **ReleaseId**: Windows release identifier (legacy, may show "2009" for newer builds)
- **InstalledOn**: Date and time when Windows was installed (format: yyyy-MM-dd HH:mm:ss)
- **ExperiencePack**: Windows Feature Experience Pack version number

### Additional Properties (with -IncludeSystemInfo)

- **ComputerName**: NetBIOS name of the computer
- **PowerShellVersion**: Currently running PowerShell version
- **PowerShellEdition**: PowerShell edition ("Desktop" for 5.1, "Core" for 7+)
- **LastBootTime**: Last system boot time (format: yyyy-MM-dd HH:mm:ss)

### Example Output Object
```powershell
Version          : 23H2
Edition          : Windows 11 Pro
OSBuild          : 22631.4602
ReleaseId        : 2009
InstalledOn      : 2024-01-15 10:30:45
ExperiencePack   : 1000.22700.1000.0
```

## Error Handling

### Common Errors

**Error: "This script requires Windows OS"**
- **Cause**: Script executed on Linux or macOS
- **Solution**: This script only works on Windows. Use platform-appropriate tools for Linux/macOS system information.

**Registry Value Not Found**
- **Cause**: Certain registry keys may not exist on older Windows versions
- **Solution**: Script gracefully handles missing values by returning "Unknown" or "N/A". No action needed.

**"Appx module not available"**
- **Cause**: Appx module cannot be loaded (rare on standard Windows installations)
- **Solution**: Script continues without Experience Pack version. To fix, repair Windows features via Settings > Apps > Optional Features.

**"Failed to retrieve LastBootTime"**
- **Cause**: WMI/CIM access issue when using `-IncludeSystemInfo`
- **Solution**: Ensure WMI service is running: `Get-Service Winmgmt`

## Troubleshooting

### Script Shows "Unknown" for Some Values

Check if running on a Windows Insider or pre-release build where registry keys may have different names. Enable verbose output to see which values failed to retrieve:

```powershell
.\Get-BuildInfo.ps1 -Verbose
```

### Experience Pack Version Shows "N/A"

This is normal if:
- Running in Windows Server (doesn't have Feature Experience Pack)
- Running in Windows 10 versions older than 2004
- Appx module failed to load

### Performance Considerations

- Script execution is fast (typically < 1 second)
- No network calls are made
- All data is retrieved from local registry and system
- Safe to run in scheduled tasks or automation scripts

## Notes

### Important Limitations

- **Windows-only**: This script will not work on Linux or macOS systems
- **Local system**: Only retrieves information from the computer where it's executed
- **No remote capability**: Does not support querying remote computers (use `Invoke-Command` wrapper if needed)
- **Registry dependency**: Relies on standard Windows registry structure

### Security Considerations

- No credentials or sensitive information are collected
- No modifications are made to the system (read-only operations)
- No external network connections are established
- Safe to run with standard user privileges

### Cross-Platform Considerations

While PowerShell 7+ is cross-platform, this script explicitly checks for Windows OS and will fail gracefully on other platforms with a clear error message.

### Performance Notes

- Minimal resource usage (< 50MB memory)
- Fast execution (typically completes in under 1 second)
- No blocking operations
- Safe for automation and scheduled execution

## Version History

- **2.0.0** (2025-11-22) - Complete rewrite following PowerShell best practices:
  - Added comprehensive help documentation
  - Implemented proper error handling
  - Added parameter support (AsJson, IncludeSystemInfo)
  - Improved cross-platform detection
  - Added function wrapper (Get-WindowsBuildInfo)
  - Enhanced Appx module handling for PS7+
  - Restructured code into regions
  - Added Write-Status function for consistent output
  - Improved registry value retrieval with defaults

- **1.0.0** (2022-04-14) - Initial script version
  - Basic build information retrieval
  - Simple output format

## Author

Bill Kindle (AI Assisted)

## License

See [LICENSE](LICENSE) file in repository root.

## References

- Original example source: [My PowerShell Notes - Windows Build Information](https://mypowershellnotes.wordpress.com/2020/05/27/get-windows-build-information-from-powershell/)
- Appx module PS7 compatibility: [PowerShell Issue #13138](https://github.com/PowerShell/PowerShell/issues/13138)
- Feature Experience Pack information: [Stack Overflow](https://stackoverflow.com/questions/64831517/)

## Related Scripts

- `Get-RecentOSUpdateHistory.ps1` - View Windows Update history
- `Get-LastWinUpdate.ps1` - Check last Windows Update date

## Additional Examples

### Use in Remote Sessions
```powershell
Invoke-Command -ComputerName SERVER01 -FilePath .\Get-BuildInfo.ps1
```

### Batch Collection from Multiple Computers
```powershell
$computers = Get-Content .\computers.txt
$results = Invoke-Command -ComputerName $computers -FilePath .\Get-BuildInfo.ps1
$results | Export-Csv -Path .\AllSystemInfo.csv -NoTypeInformation
```

### Compare Build Versions
```powershell
$currentBuild = .\Get-BuildInfo.ps1
Write-Host "Current Build: $($currentBuild.OSBuild)"
if ($currentBuild.OSBuild -lt "22631.0") {
    Write-Warning "System may need updating"
}
```
