<#
.SYNOPSIS
    Retrieves comprehensive Windows build and version information.

.DESCRIPTION
    Collects detailed information about the Windows operating system including:
    - Windows version and edition
    - OS build numbers and release information
    - Installation date
    - Windows Feature Experience Pack version
    
    This function is compatible with both Windows PowerShell 5.1 and PowerShell 7+.
    Includes proper error handling for missing registry keys or unavailable components.

.PARAMETER AsJson
    When specified, outputs the build information as formatted JSON instead of a PSCustomObject.

.PARAMETER IncludeSystemInfo
    When specified, includes additional system information such as computer name,
    last boot time, and PowerShell version details.

.EXAMPLE
    .\buildInfo.ps1
    
    Displays Windows build information as a PowerShell object.

.EXAMPLE
    .\buildInfo.ps1 -AsJson
    
    Displays Windows build information formatted as JSON.

.EXAMPLE
    .\buildInfo.ps1 -IncludeSystemInfo
    
    Displays Windows build information with additional system details.

.NOTES
    Author: Bill Kindle (AI Assisted)
    Version: 2.0.0
    Created: 2022-04-14
    Updated: 2025-11-22
    Requires: Windows OS (not compatible with Linux/macOS)
    
    Original Example Source:
    https://mypowershellnotes.wordpress.com/2020/05/27/get-windows-build-information-from-powershell/
    
    Version History:
    2.0.0 - 2025-11-22 - Complete rewrite following PowerShell best practices:
                         - Added comprehensive help documentation
                         - Implemented proper error handling
                         - Added parameter support (AsJson, IncludeSystemInfo)
                         - Improved cross-platform detection
                         - Added function wrapper (Get-WindowsBuildInfo)
                         - Enhanced Appx module handling for PS7+
    1.0.0 - 2022-04-14 - Initial script version
    
    References:
    - Appx module PS7 compatibility: https://github.com/PowerShell/PowerShell/issues/13138
    - Feature Experience Pack: https://stackoverflow.com/questions/64831517/
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AsJson,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSystemInfo
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

function Get-RegistryValue {
    <#
    .SYNOPSIS
        Safely retrieves a registry value with error handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultValue = "Unknown"
    )
    
    try {
        $value = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
        return $value
    }
    catch {
        Write-Verbose "Failed to retrieve registry value '$Name' from '$Path': $($_.Exception.Message)"
        return $DefaultValue
    }
}

function Initialize-AppxModule {
    <#
    .SYNOPSIS
        Loads the Appx module with proper version handling for PowerShell 7+.
    #>
    [CmdletBinding()]
    param()
    
    $psVersion = $PSVersionTable.PSVersion
    
    # Appx module handling for PowerShell 7.0-7.1.x
    # Note: PS 7.2+ has improved Windows compatibility layer
    if ($PSVersionTable.PSEdition -eq 'Core') {
        if ($psVersion.Major -eq 7 -and $psVersion.Minor -le 1) {
            try {
                Write-Verbose "Loading Appx module using Windows PowerShell compatibility"
                Import-Module -Name Appx -UseWindowsPowerShell -ErrorAction Stop -WarningAction SilentlyContinue
                return $true
            }
            catch {
                Write-Verbose "Failed to load Appx module: $($_.Exception.Message)"
                return $false
            }
        }
        else {
            # PowerShell 7.2+ - attempt direct import
            try {
                Import-Module -Name Appx -ErrorAction Stop -WarningAction SilentlyContinue
                return $true
            }
            catch {
                Write-Verbose "Appx module not available: $($_.Exception.Message)"
                return $false
            }
        }
    }
    else {
        # Windows PowerShell 5.1 - module should be natively available
        try {
            Import-Module -Name Appx -ErrorAction Stop -WarningAction SilentlyContinue
            return $true
        }
        catch {
            Write-Verbose "Appx module not available: $($_.Exception.Message)"
            return $false
        }
    }
}

function Get-WindowsBuildInfo {
    <#
    .SYNOPSIS
        Retrieves detailed Windows build and version information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemInfo
    )
    
    # Platform validation
    if (-not $IsWindows -and $null -ne $IsWindows) {
        throw "This script requires Windows OS. Current platform: $(if ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' })"
    }
    
    Write-Verbose "Gathering Windows build information..."
    
    # Registry path for Windows version information
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    # Retrieve core Windows information
    $version = Get-RegistryValue -Path $regPath -Name "DisplayVersion" -DefaultValue "N/A"
    $currentBuild = Get-RegistryValue -Path $regPath -Name "CurrentBuild" -DefaultValue "0"
    $ubr = Get-RegistryValue -Path $regPath -Name "UBR" -DefaultValue "0"
    $productName = Get-RegistryValue -Path $regPath -Name "ProductName" -DefaultValue "Unknown"
    $releaseId = Get-RegistryValue -Path $regPath -Name "ReleaseId" -DefaultValue "N/A"
    
    # Parse installation time
    $installTime = "Unknown"
    try {
        $installTimeValue = Get-RegistryValue -Path $regPath -Name "InstallTime"
        if ($installTimeValue -ne "Unknown") {
            $installTime = [DateTime]::FromFileTime([long]$installTimeValue).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
    catch {
        Write-Verbose "Failed to parse InstallTime: $($_.Exception.Message)"
    }
    
    # Retrieve Windows Feature Experience Pack version
    $experiencePackVersion = "N/A"
    if (Initialize-AppxModule) {
        try {
            $appxPackage = Get-AppxPackage -Name 'MicrosoftWindows.Client.CBS' -ErrorAction SilentlyContinue
            if ($appxPackage) {
                $experiencePackVersion = $appxPackage.Version
            }
            else {
                Write-Verbose "Windows Feature Experience Pack not found"
            }
        }
        catch {
            Write-Verbose "Failed to retrieve Experience Pack version: $($_.Exception.Message)"
        }
    }
    else {
        Write-Verbose "Appx module not available, skipping Experience Pack version retrieval"
    }
    
    # Build result object
    $buildInfo = [PSCustomObject]@{
        Version          = $version
        Edition          = $productName
        OSBuild          = "$currentBuild.$ubr"
        ReleaseId        = $releaseId
        InstalledOn      = $installTime
        ExperiencePack   = $experiencePackVersion
    }
    
    # Add system information if requested
    if ($IncludeSystemInfo) {
        $buildInfo | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $env:COMPUTERNAME
        $buildInfo | Add-Member -MemberType NoteProperty -Name "PowerShellVersion" -Value $PSVersionTable.PSVersion.ToString()
        $buildInfo | Add-Member -MemberType NoteProperty -Name "PowerShellEdition" -Value $PSVersionTable.PSEdition
        
        try {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $lastBootTime = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
            $buildInfo | Add-Member -MemberType NoteProperty -Name "LastBootTime" -Value $lastBootTime
        }
        catch {
            Write-Verbose "Failed to retrieve LastBootTime: $($_.Exception.Message)"
            $buildInfo | Add-Member -MemberType NoteProperty -Name "LastBootTime" -Value "Unknown"
        }
    }
    
    return $buildInfo
}

#endregion

#region Main Execution

try {
    Write-Status "Retrieving Windows build information..." -Level Info
    
    # Get build information
    $buildInfo = Get-WindowsBuildInfo -IncludeSystemInfo:$IncludeSystemInfo
    
    # Output results based on format preference
    if ($AsJson) {
        $buildInfo | ConvertTo-Json -Depth 3
    }
    else {
        $buildInfo
    }
    
    Write-Verbose "Build information retrieval completed successfully"
}
catch {
    Write-Status "Failed to retrieve build information: $($_.Exception.Message)" -Level Error
    throw
}

#endregion
