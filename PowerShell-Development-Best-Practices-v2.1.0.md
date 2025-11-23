# PowerShell Script Development Best Practices Guide

## Overview
This guide provides a comprehensive framework for developing robust, enterprise-ready PowerShell scripts. It captures proven development patterns, architectural approaches, and best practices for creating high-quality automation solutions.

---

## Table of Contents

### Core Framework
- [Development Philosophy](#development-philosophy)
- [Script Architecture Framework](#script-architecture-framework)
- [Authentication & Connection Management](#authentication--connection-management)
- [User Experience Design](#user-experience-design)
- [Documentation Standards](#documentation-standards)

### Quality & Testing
- [Testing & Quality Assurance](#testing--quality-assurance)
- [Code Coverage & Analysis](#code-coverage--analysis)
- [Mutation Testing](#mutation-testing)

### Integration & Performance
- [API Integration Best Practices](#api-integration-best-practices)
- [Performance Optimization](#performance-optimization)
- [Performance & Load Testing](#performance--load-testing)
- [Cross-Platform PowerShell](#cross-platform-powershell)

### Configuration Management
- [Desired State Configuration (DSC)](#desired-state-configuration-dsc)

### Security & Maintenance
- [Security Considerations](#security-considerations)
- [Code Signing & Execution Policy](#code-signing--execution-policy)
- [Constrained Language Mode](#constrained-language-mode)
- [Version Control & Maintenance](#version-control--maintenance)
- [Module Development](#module-development)

### Examples & Patterns
- [Development Workflow](#development-workflow)
- [Common Patterns & Templates](#common-patterns--templates)
- [Complete Example Script](#complete-example-script)
- [Anti-Patterns - What NOT to Do](#anti-patterns---what-not-to-do)

### Reference
- [Lessons Learned](#lessons-learned)
- [Quick Reference Card](#quick-reference-card)
- [Glossary](#glossary)
- [Change Log](#change-log)

### Appendix
- [Appendix A: AI Development Instructions](#appendix-a-ai-development-instructions)

---

## Development Philosophy

### Core Principles
1. **User-Centric Design**: Multiple input methods to accommodate different use cases
2. **Comprehensive Validation**: Validate everything before processing
3. **Clear Communication**: Provide detailed feedback and progress indicators
4. **Error Resilience**: Handle edge cases gracefully
5. **Documentation First**: Extensive help and examples
6. **Security Conscious**: Validate inputs, require explicit permissions

## Script Architecture Framework

### 1. Script Structure Template
```powershell
<#
.SYNOPSIS
    Brief description of what the script does

.DESCRIPTION
    Detailed description including:
    - Purpose and use cases
    - Input methods supported
    - Authentication requirements
    - Important limitations or considerations

.PARAMETER ParameterName
    Clear description of each parameter

.EXAMPLE
    Provide multiple real-world examples

.NOTES
    Author: [Name] (with AI assistance if applicable)
    Version: X.X
    Created: [Date]
    Requires: [List all module dependencies]
    
    Required Permissions:
    - List specific permissions needed
    
    Setup Instructions:
    - Step-by-step setup guide
#>

#Requires -Module [List all required modules]

[CmdletBinding(SupportsShouldProcess)]
param(
    # Well-defined parameter sets for different usage modes
)

# Helper functions go here
# Main execution logic
```

### 2. Parameter Design Principles

#### Parameter Sets for Different Use Cases
- **Array Input**: Direct parameter input for scripting and automation
- **CSV Input**: File-based input for bulk operations and data-driven scenarios
- **Interactive Mode**: User-friendly guided input for ad-hoc operations

#### Parameter Validation Examples
```powershell
[Parameter(Mandatory = $true, ParameterSetName = 'Array')]
[ValidateNotNullOrEmpty()]
[string[]]$InputItems

[Parameter(Mandatory = $true, ParameterSetName = 'CSV')]
[ValidateScript({Test-Path $_ -PathType Leaf})]
[string]$CsvPath

[Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
[switch]$Interactive
```

#### Optional Override Parameters
- Skip validation switches for edge cases
- Custom configuration parameters (domains, tenants, endpoints)
- Debug and testing switches
- Output formatting options

### 3. Validation Framework

#### Multi-Layer Validation Approach
1. **Format Validation**: Input format, file existence, data structure validation
2. **Business Logic Validation**: Domain restrictions, organizational rules, policy compliance
3. **System Validation**: Resource existence, service connectivity, permission verification
4. **Pre-execution Validation**: Confirm all inputs and dependencies before processing

#### Validation Function Pattern
```powershell
function Test-[Entity]Comprehensive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputValue,
        
        [string]$RequiredPattern,
        [switch]$SkipFormatValidation,
        [switch]$SkipExistenceValidation
    )
    
    $result = [PSCustomObject]@{
        OverallValid = $false
        Issues = @()
        FormatValid = $false
        ExistenceConfirmed = $false
        # Additional validation properties as needed
    }
    
    # Perform validation checks
    # Add issues to $result.Issues array
    # Set specific validation flags
    
    $result.OverallValid = (-not $result.Issues.Count)
    return $result
}
```

## Authentication & Connection Management

### Hybrid Authentication Strategy
When multiple services are required:

1. **Service-Specific Authentication**: Use appropriate modules for each service
2. **Single Connection Pattern**: Establish connections once at script start
3. **Connection Validation**: Verify connections before processing
4. **Graceful Fallbacks**: Handle authentication failures appropriately

### Modern Connection Guidance (2025+)
Modern modules (Microsoft.Graph 2.x+, ExchangeOnlineManagement 3.x+) maintain reusable contexts and refresh tokens automatically. Prefer an implicit "detect existing context" pattern before calling `Connect-*` again. Only invoke explicit `Connect-MgGraph` / `Connect-ExchangeOnline` / other `Connect-*` commands when:
1. No active context/session is detected
2. Running app-only or certificate-based non-interactive auth (CI, scheduled task)
3. Performing tenant switch that requires a new token scope
4. Using an older module version lacking automatic refresh

Avoid reconnecting inside loops or helper functions; connect once, then validate. For Graph, use `Get-MgContext` to detect existing session; for Exchange Online use `Get-ConnectionInformation`. Fail fast with clear error messages when a required module or context is absent.

### Connection Management Pattern
```powershell
function Initialize-[Service]Connection {
    [CmdletBinding()]
    param()
    
    # Check if module is available
    if (-not (Get-Module -ListAvailable -Name [ServiceModule])) {
        throw "Module not installed"
    }
    
    # Detect existing connection/context first
    $connectionStatus = [ConnectionCheckLogic]
    if (-not $connectionStatus) {
        Write-Status "Connecting to [Service]..." -Level Warning
        try {
            [ConnectionCommand]  # e.g. Connect-MgGraph -Scopes User.Read.All
            Write-Status "Successfully connected to [Service]" -Level OK
        }
        catch {
            throw "Connection failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-Status "[Service] connection verified" -Level OK
    }
}
```

## User Experience Design

### Progress Communication
- **Visual Feedback**: Use color coding for status messages
- **Progress Indicators**: Show progress for batch operations
- **Clear Results**: Summarize success/failure counts
- **Detailed Logging**: Provide verbose options for troubleshooting

### Input Methods Hierarchy
1. **Scripting First**: Direct parameter input for automation
2. **Batch Processing**: CSV file support for bulk operations
3. **Interactive Mode**: Guided input for ad-hoc usage

### Error Handling Strategy
```powershell
try {
    # Main operation
    $result.Success = $true
    $result.Message = "Success message"
}
catch {
    $result.Success = $false
    $result.Message = $_.Exception.Message
    Write-Error "Detailed error for user"
}
finally {
    # Always update counters and results
    $script:Results += $result
}
```

### Logging & Status Output
Use a lightweight wrapper that emits structured, capturable output via `Write-Information` while preserving clear, ASCII-safe prefixes. This replaces prior `Write-Host` examples and improves testability (Pester can capture information records; logging can be redirected).
In PowerShell 7+, Write-Host is a wrapper for Write-Information and writes to the capturable information stream (6>) - it is no longer an anti-pattern and is safe for colored status messages; the migration here favors Write-Status for consistency and tagging, not because Write-Host is unsafe.

```powershell
function Write-Status {
    <#
    .SYNOPSIS
        Emit standardized status messages.
    .DESCRIPTION
        Wraps Write-Information with tagged, prefixed output. Avoids direct Write-Host usage.
    .PARAMETER Message
        The message text (ASCII-safe only).
    .PARAMETER Level
        Message level classification.
    .EXAMPLE
        Write-Status "Initializing" -Level Info
    .EXAMPLE
        Write-Status "User created" -Level OK
    .EXAMPLE
        Write-Status "Validation failed" -Level Error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info','OK','Warning','Error','Debug')]
        [string]$Level = 'Info'
    )
    $prefix = switch ($Level) {
        'OK'      { '[OK]' }
        'Error'   { '[ERROR]' }
        'Warning' { '[WARN]' }
        'Info'    { '[INFO]' }
        'Debug'   { '[DEBUG]' }
    }
    # Information records are capturable; tags support filtering.
    Write-Information "$prefix $Message" -Tags $Level,'Status'
}
```

Guidelines:
1. Prefer `Write-Status` or `Write-Information` for routine output.
2. Reserve `Write-Warning` / `Write-Error` for actual warnings/errors.
3. Keep messages ASCII-only (`[OK]`, `[ERROR]`) to avoid encoding issues across hosts.
4. In legacy scripts still using `Write-Host`, migrate gradually; update analyzer settings to stop excluding `PSAvoidUsingWriteHost` once migration completes.

Redirecting / Capturing:
```powershell
$info = & .\MyScript.ps1 *>&1 | Where-Object { $_.MessageData -is [string] }
$info | ForEach-Object { $_.MessageData }
```

For CI environments, you can parse tags for structured logs.

## Documentation Standards

### Help Documentation Requirements
- **Synopsis**: One-line description
- **Description**: Detailed explanation with context
- **Parameters**: Every parameter documented
- **Examples**: Multiple real-world scenarios
- **Notes**: Setup requirements, permissions, limitations

### README Documentation Structure
1. **Overview**: What the script does and why
2. **Prerequisites**: Detailed setup requirements
3. **Usage Examples**: Copy-paste ready examples
4. **Parameter Reference**: Complete parameter documentation
5. **Troubleshooting**: Common issues and solutions
6. **Architecture Details**: How it works (for complex scripts)

## Testing & Quality Assurance

### Testing Approach
1. **Parameter Validation**: Test all parameter combinations
2. **Edge Cases**: Invalid inputs, network failures, permission issues
3. **WhatIf Testing**: Verify -WhatIf functionality
4. **Batch Testing**: Test with various data sizes
5. **Connection Scenarios**: Test with existing/missing connections

### Pester Testing Framework

Pester is PowerShell's native testing framework. Use it for unit and integration testing.

#### Basic Pester Test Structure
```powershell
BeforeAll {
    # Import the script or module to test
    . $PSScriptRoot\MyScript.ps1
}

Describe "Test-EmailComprehensive" {
    Context "Format Validation" {
        It "Should accept valid email addresses" {
            $result = Test-EmailComprehensive -EmailAddress "user@contoso.com"
            $result.FormatValid | Should -Be $true
        }
        
        It "Should reject invalid email format" {
            $result = Test-EmailComprehensive -EmailAddress "invalid-email"
            $result.FormatValid | Should -Be $false
            $result.Issues | Should -Contain "Invalid email format"
        }
    }
    
    Context "Domain Validation" {
        It "Should accept emails from required domain" {
            $result = Test-EmailComprehensive -EmailAddress "user@contoso.com" -RequiredDomain "contoso.com"
            $result.DomainValid | Should -Be $true
        }
        
        It "Should reject emails from other domains" {
            $result = Test-EmailComprehensive -EmailAddress "user@external.com" -RequiredDomain "contoso.com"
            $result.DomainValid | Should -Be $false
        }
    }
    
    Context "Skip Validation" {
        It "Should skip domain validation when flag is set" {
            $result = Test-EmailComprehensive -EmailAddress "user@external.com" -SkipDomainValidation
            $result.DomainValid | Should -Be $true
        }
    }
}
```

#### Pester Test Categories

**Unit Tests** - Test individual functions in isolation:
```powershell
Describe "Initialize-GraphConnection" {
    It "Should throw error when module not installed" {
        Mock Get-Module { $null }
        { Initialize-GraphConnection } | Should -Throw "*module*not installed*"
    }
    
    It "Should skip connection if already connected" {
        Mock Get-MgContext { @{TenantId = "test-tenant"} }
        Mock Connect-MgGraph { }
        Initialize-GraphConnection
        Should -Invoke Connect-MgGraph -Times 0
    }
}
```

**Integration Tests** - Test full script execution:
```powershell
Describe "Script End-to-End" {
    It "Should process CSV input successfully" {
        # Create test CSV
        $testData = @(
            @{EmailAddress = "test1@contoso.com"},
            @{EmailAddress = "test2@contoso.com"}
        )
        $testCsv = "TestDrive:\test.csv"
        $testData | Export-Csv -Path $testCsv -NoTypeInformation
        
        # Run script with WhatIf
        { & .\MyScript.ps1 -CsvPath $testCsv -WhatIf } | Should -Not -Throw
    }
}
```

### PSScriptAnalyzer for Code Quality

PSScriptAnalyzer performs static code analysis to identify code quality issues and best practice violations.

#### Basic PSScriptAnalyzer Usage
```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# Analyze a single script
Invoke-ScriptAnalyzer -Path .\MyScript.ps1

# Analyze with specific severity levels
Invoke-ScriptAnalyzer -Path .\MyScript.ps1 -Severity Error,Warning

# Analyze entire directory
Invoke-ScriptAnalyzer -Path .\Scripts\ -Recurse

# Export results to file
Invoke-ScriptAnalyzer -Path .\MyScript.ps1 | Export-Csv -Path "analysis-results.csv"
```

#### Custom PSScriptAnalyzer Settings
Create `PSScriptAnalyzerSettings.psd1` in your repository root:
```powershell
@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        # 'PSAvoidUsingWriteHost'  # (Temporary) Remove once all legacy scripts migrated to Write-Status
    )
    Rules = @{
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
                'win-8_x64_10.0.18362.0_5.1.18362.145_x64_4.0.30319.42000_framework'
            )
        }
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @('5.1', '7.0')
        }
    }
}
```

#### Integration with CI/CD
```powershell
# CI/CD Pipeline Script
$analysisResults = Invoke-ScriptAnalyzer -Path .\Scripts\ -Recurse -Severity Error,Warning

if ($analysisResults) {
    $analysisResults | Format-Table -AutoSize
    Write-Error "PSScriptAnalyzer found $($analysisResults.Count) issues"
    exit 1
} else {
    Write-Status "PSScriptAnalyzer passed with no issues" -Level OK
    exit 0
}
```

### Quality Checkpoints
- [ ] All parameters have help documentation
- [ ] Multiple usage examples provided
- [ ] Error handling for all external calls
- [ ] Progress feedback for long operations
- [ ] Results summary and export
- [ ] SupportsShouldProcess implemented
- [ ] Verbose logging available
- [ ] Pester tests for validation functions
- [ ] PSScriptAnalyzer passes with no errors
- [ ] Code coverage above 80% threshold

---

## Code Coverage & Analysis

### Pester Code Coverage

Code coverage measures what percentage of your code is executed by tests. Aim for 80%+ coverage on critical functions.

#### Basic Code Coverage
```powershell
# Run tests with code coverage
$coverageFiles = Get-ChildItem -Path .\*.ps1 -Recurse -Exclude *.Tests.ps1

$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = $coverageFiles
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = 'coverage.xml'

$result = Invoke-Pester -Configuration $config

# Display coverage summary
${level = if ($result.CodeCoverage.CoveragePercent -ge 80) { 'OK' } else { 'Warning' }}
Write-Status "Code Coverage: $($result.CodeCoverage.CoveragePercent)%" -Level $level
```

#### Detailed Coverage Analysis
```powershell
# Analyze which lines are not covered
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\MyScript.ps1'
$config.Run.Path = '.\Tests'

$result = Invoke-Pester -Configuration $config

# Show missed commands
foreach ($missed in $result.CodeCoverage.MissedCommands) {
    Write-Status "Line $($missed.Line): $($missed.Function) - $($missed.Command)" -Level Error
}

# Show coverage by function
$result.CodeCoverage.ByFunction | ForEach-Object {
    $percent = if ($_.TotalCommandCount -gt 0) {
        [math]::Round(($_.CommandsExecuted / $_.TotalCommandCount) * 100, 2)
    } else { 0 }
    
    $fnLevel = if ($percent -ge 80) { 'OK' } elseif ($percent -ge 50) { 'Warning' } else { 'Error' }
    Write-Status "$($_.Function): $percent% ($($_.CommandsExecuted)/$($_.TotalCommandCount))" -Level $fnLevel
}
```

#### Coverage-Focused Test Example
```powershell
# Tests\MyScript.Tests.ps1

BeforeAll {
    . $PSScriptRoot\..\MyScript.ps1
}

Describe "Get-UserData" {
    Context "Input Validation" {
        It "Should handle null input" {
            { Get-UserData -UserId $null } | Should -Throw
        }
        
        It "Should handle empty string" {
            { Get-UserData -UserId "" } | Should -Throw
        }
        
        It "Should validate UserId format" {
            { Get-UserData -UserId "invalid" } | Should -Throw
        }
    }
    
    Context "Success Path" {
        It "Should return data for valid user" {
            $result = Get-UserData -UserId "user@domain.com"
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Error Handling" {
        It "Should handle API errors gracefully" {
            Mock Get-MgUser { throw "API Error" }
            { Get-UserData -UserId "user@domain.com" } | Should -Throw "API Error"
        }
        
        It "Should handle network timeouts" {
            Mock Get-MgUser { throw [System.TimeoutException]::new() }
            { Get-UserData -UserId "user@domain.com" } | Should -Throw
        }
    }
    
    Context "Edge Cases" {
        It "Should handle special characters in UserId" {
            $result = Get-UserData -UserId "user+test@domain.com"
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle very long UserIds" {
            $longEmail = "a" * 50 + "@domain.com"
            { Get-UserData -UserId $longEmail } | Should -Not -Throw
        }
    }
}
```

### CI/CD Integration with Coverage

#### GitHub Actions Example
```yaml
name: Test and Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Pester
        shell: pwsh
        run: |
          Install-Module Pester -Force -SkipPublisherCheck -MinimumVersion 5.0
      
      - name: Run Tests with Coverage
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './Tests'
          $config.CodeCoverage.Enabled = $true
          $config.CodeCoverage.Path = './src/*.ps1'
          $config.CodeCoverage.OutputFormat = 'JaCoCo'
          $config.CodeCoverage.OutputPath = './coverage.xml'
          $config.TestResult.Enabled = $true
          $config.TestResult.OutputPath = './testResults.xml'
          
          $result = Invoke-Pester -Configuration $config
          
          if ($result.CodeCoverage.CoveragePercent -lt 80) {
              Write-Error "Code coverage $($result.CodeCoverage.CoveragePercent)% is below 80% threshold"
              exit 1
          }
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v2
        with:
          files: ./coverage.xml
          flags: unittests
```

#### Azure DevOps Pipeline Example
```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Install Pester'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module Pester -Force -SkipPublisherCheck -MinimumVersion 5.0

- task: PowerShell@2
  displayName: 'Run Tests with Coverage'
  inputs:
    targetType: 'inline'
    script: |
      $config = New-PesterConfiguration
      $config.Run.Path = './Tests'
      $config.CodeCoverage.Enabled = $true
      $config.CodeCoverage.Path = './src/*.ps1'
      $config.CodeCoverage.OutputFormat = 'JaCoCo'
      $config.CodeCoverage.OutputPath = '$(Build.ArtifactStagingDirectory)/coverage.xml'
      $config.TestResult.Enabled = $true
      $config.TestResult.OutputPath = '$(Build.ArtifactStagingDirectory)/testResults.xml'
      
      $result = Invoke-Pester -Configuration $config
      
    Write-Status "Code Coverage: $($result.CodeCoverage.CoveragePercent)%" -Level (if ($result.CodeCoverage.CoveragePercent -ge 80) { 'OK' } else { 'Warning' })
      
      if ($result.FailedCount -gt 0) {
          Write-Error "Tests failed"
          exit 1
      }

- task: PublishTestResults@2
  displayName: 'Publish Test Results'
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: '$(Build.ArtifactStagingDirectory)/testResults.xml'
    failTaskOnFailedTests: true

- task: PublishCodeCoverageResults@1
  displayName: 'Publish Code Coverage'
  inputs:
    codeCoverageTool: 'JaCoCo'
    summaryFileLocation: '$(Build.ArtifactStagingDirectory)/coverage.xml'
```

### Coverage Best Practices

#### What to Prioritize for Coverage
1. **Critical business logic** - Core functionality that must always work
2. **Validation functions** - Input validation and sanitization
3. **Error handling paths** - Ensure errors are caught and handled
4. **Edge cases** - Boundary conditions and unusual inputs

#### What Not to Over-Test
1. **Simple property getters/setters** - Low value tests
2. **Third-party cmdlet calls** - Mock these instead
3. **UI/Display code** - Focus on logic, not formatting

#### Coverage Goals by Component
```powershell
# Production Script Structure
MyScript.ps1
├── Parameter Validation      → Target: 95%+ coverage
├── Validation Functions      → Target: 90%+ coverage
├── Connection Management     → Target: 85%+ coverage
├── Core Business Logic       → Target: 90%+ coverage
├── Error Handling           → Target: 85%+ coverage
├── Progress/Display Code    → Target: 50%+ coverage (lower priority)
└── Cleanup/Disposal         → Target: 80%+ coverage
```

#### Improving Coverage
```powershell
# Find untested functions
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\src\*.ps1'
$result = Invoke-Pester -Configuration $config

# Functions with no coverage
$result.CodeCoverage.ByFunction | 
    Where-Object { $_.CommandsExecuted -eq 0 } |
    ForEach-Object {
        Write-Warning "No coverage: $($_.Function) in $($_.File)"
    }

# Functions with low coverage (< 50%)
$result.CodeCoverage.ByFunction | 
    Where-Object { 
        $_.TotalCommandCount -gt 0 -and 
        ($_.CommandsExecuted / $_.TotalCommandCount) -lt 0.5 
    } |
    ForEach-Object {
        $percent = [math]::Round(($_.CommandsExecuted / $_.TotalCommandCount) * 100, 1)
        Write-Warning "Low coverage ($percent%): $($_.Function)"
    }
```

---

## Mutation Testing

### Overview
Mutation testing evaluates test suite effectiveness by introducing small changes (mutations) into source code and verifying that tests fail. A high mutation score indicates tests are sensitive to behavioral changes, not just line execution.

### Core Concepts
- **Mutant**: Modified version of code (e.g., changing an operator, negating a condition).
- **Killed Mutant**: Tests failed as expected when running against mutated code.
- **Survived Mutant**: Tests still passed (indicates inadequate assertions).
- **Mutation Score**: (Killed / Total) * 100.

### Common Mutation Operators
1. Arithmetic change: `+` to `-`, `*` to `/`.
2. Logical negation: `-eq` to `-ne`, `-lt` to `-gt`.
3. Boolean flip: `$true` to `$false`.
4. Conditional removal: remove an `if` branch body.
5. Return value alteration: replace literal values.

### Implementing Mutation Testing in PowerShell (Manual Approach)
No mature dedicated framework exists, so build a lightweight harness using the PowerShell AST.

```powershell
function Invoke-MutationTesting {
    [CmdletBinding()]param(
        [Parameter(Mandatory)][string]$TargetPath,
        [Parameter(Mandatory)][string]$TestsPath,
        [int]$MaxMutants = 50
    )

    $original = Get-Content -Path $TargetPath -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($original,[ref]$null,[ref]$null)

    $mutants = [System.Collections.Generic.List[pscustomobject]]::new()

    # Example: Flip comparison operators
    foreach ($token in $ast.Tokenize()) {
        if ($mutants.Count -ge $MaxMutants) { break }
        switch ($token.Text) {
            '-eq' { $replacement='-ne' }
            '-ne' { $replacement='-eq' }
            '-gt' { $replacement='-lt' }
            '-lt' { $replacement='-gt' }
            default { continue }
        }
        $mutated = $original.Substring(0,$token.Extent.StartOffset) + $replacement + $original.Substring($token.Extent.EndOffset)
        $mutants.Add([pscustomobject]@{Operator=$token.Text; Replacement=$replacement; Code=$mutated})
    }

    $killed = 0
    foreach ($m in $mutants) {
        $tempFile = Join-Path $env:TEMP ("mutant_" + [guid]::NewGuid().Guid + '.ps1')
        Set-Content -Path $tempFile -Value $m.Code -Encoding UTF8
        try {
            $config = New-PesterConfiguration
            $config.Run.Path = $TestsPath
            $config.TestResult.Enabled = $false
            $env:MUTATION_TARGET = $tempFile
            $result = Invoke-Pester -Configuration $config -Quiet
            if ($result.FailedCount -gt 0) { $killed++ } else { Write-Warning "Survived mutant: $($m.Operator)->$($m.Replacement)" }
        } finally { Remove-Item $tempFile -ErrorAction SilentlyContinue }
    }

    $score = if ($mutants.Count) { [math]::Round(($killed/$mutants.Count)*100,2) } else { 0 }
    [pscustomobject]@{Mutants=$mutants.Count; Killed=$killed; Score=$score}
}
```

### Usage Pattern
1. Generate mutants with limited operator set first.
2. Run existing Pester tests against each mutant.
3. Review survived mutants; add or strengthen assertions.
4. Repeat until additional mutants mostly killed (diminishing returns).

### Best Practices
- Limit number of mutants to keep runtime acceptable.
- Focus on critical functions (validation, business rules).
- Automate periodic mutation runs (weekly CI job) separate from regular PR tests.
- Track mutation score trend over time; set improvement goals.

### Mutation Score Targets (Guidance)
- Initial adoption: 40–60%.
- Mature suite: 70–85%.
- Rare 90%+ usually indicates over-testing or trivial code.

---

## API Integration Best Practices

### Service Integration Patterns
- **Microsoft Graph**: User management, SharePoint, Teams, etc.
- **Exchange Online**: Email and mailbox management
- **Azure REST APIs**: Resource management and monitoring
- **Active Directory**: On-premises identity management
- **Custom REST APIs**: Third-party service integration

### Service Integration Best Practices
- **Minimal Permissions**: Request only required scopes and permissions
- **Connection Reuse**: Establish connections once, use throughout script execution
- **Error Handling**: Handle service-specific errors appropriately
- **Fallback Strategies**: Alternative approaches when primary methods fail
- **Rate Limiting**: Respect API rate limits and implement backoff strategies

---

## Performance Optimization

### Performance Philosophy
Performance optimization in PowerShell requires understanding both the language's strengths and limitations. Focus on: batch processing optimization, memory management, efficient data structures, and leveraging .NET methods when appropriate.

### Batch Processing & Scalability

#### Connection Reuse
- **Principle**: Establish connections once at script start, reuse throughout execution
- **Impact**: Reduces authentication overhead and API rate limiting
- **Example**: Connect to Exchange Online once, process all mailboxes in batch

#### Progress Tracking
- **User Feedback**: Show progress bars for operations processing multiple items
- **Transparency**: Keep users informed during long-running operations
- **Pattern**: Use `Write-Progress` with calculated percentage complete

#### Error Tolerance
- **Continue on Failure**: Process remaining items even when individual operations fail
- **Result Aggregation**: Collect both successes and failures for comprehensive reporting
- **Pattern**: Try-catch within loops, accumulate results in collection

### Memory Management

#### Result Collection Best Practices
- **Generic Lists**: Use `[System.Collections.Generic.List[T]]` instead of arrays with `+=`
- **Capacity Planning**: Pre-allocate list capacity when size is known
- **Resource Cleanup**: Dispose of connections and large objects when done

#### Large Dataset Handling
- **Streaming**: Process data in chunks rather than loading everything into memory
- **Filtering**: Filter at the source (server-side) before retrieving data
- **Pagination**: Use pagination parameters for APIs that support them

### PowerShell-Specific Performance Tips

#### 1. Use .NET Methods for Better Performance
```powershell
# Slow - PowerShell cmdlets
$content = Get-Content -Path $file

# Fast - .NET methods
$content = [System.IO.File]::ReadAllText($file)

# Slow - String concatenation in loop
$result = ""
foreach ($item in $items) {
    $result += $item
}

# Fast - StringBuilder for large strings
$sb = [System.Text.StringBuilder]::new()
foreach ($item in $items) {
    [void]$sb.Append($item)
}
$result = $sb.ToString()
```

#### 2. Filter Left, Format Right
```powershell
# Slow - Filtering after retrieving all data
Get-Process | Where-Object {$_.CPU -gt 100}

# Fast - Filter at the source
Get-Process | Where-Object CPU -gt 100

# Even faster - Use provider filtering when available
Get-ChildItem -Path C:\Logs -Filter *.log
```

#### 3. Avoid Pipeline for Large Datasets
```powershell
# Slow - Pipeline processing
1..10000 | ForEach-Object { $_ * 2 }

# Fast - ForEach loop
$results = foreach ($i in 1..10000) { $i * 2 }

# Fastest - .NET loop for critical performance
$results = [System.Collections.Generic.List[int]]::new(10000)
for ($i = 1; $i -le 10000; $i++) {
    $results.Add($i * 2)
}
```

#### 4. Use Efficient Data Structures
```powershell
# Slow - Array with += (creates new array each time)
$array = @()
foreach ($item in $items) {
    $array += $item  # Very slow for large datasets
}

# Fast - ArrayList
$list = [System.Collections.ArrayList]::new()
foreach ($item in $items) {
    [void]$list.Add($item)
}

# Fastest - Generic List with capacity
$list = [System.Collections.Generic.List[PSCustomObject]]::new($items.Count)
foreach ($item in $items) {
    $list.Add($item)
}
```

#### 5. Optimize Hash Table Lookups
```powershell
# Slow - Searching array repeatedly
$users = Get-MgUser -All
foreach ($email in $emails) {
    $user = $users | Where-Object {$_.Mail -eq $email}  # O(n) for each lookup
}

# Fast - Build hash table for O(1) lookups
$userLookup = @{}
Get-MgUser -All | ForEach-Object { $userLookup[$_.Mail] = $_ }

foreach ($email in $emails) {
    $user = $userLookup[$email]  # O(1) lookup
}
```

#### 6. Parallel Processing with ForEach-Object -Parallel
```powershell
# PowerShell 7+ only
# Sequential processing (slow)
$results = foreach ($server in $servers) {
    Test-Connection $server -Count 1 -Quiet
}

# Parallel processing (fast)
$results = $servers | ForEach-Object -Parallel {
    Test-Connection $_ -Count 1 -Quiet
} -ThrottleLimit 10
```

#### 7. Avoid Unnecessary Object Creation
```powershell
# Slow - Creating PSCustomObject for each item
$results = foreach ($item in $largeDataset) {
    [PSCustomObject]@{
        Name = $item.Name
        Value = $item.Value
        Status = "Processed"
    }
}

# Fast - Process without creating new objects if not needed
foreach ($item in $largeDataset) {
    $item | Add-Member -NotePropertyName "Status" -NotePropertyValue "Processed" -Force
}
```

#### 8. Use -Filter Instead of Where-Object
```powershell
# Slow - Client-side filtering
Get-ADUser -Filter * | Where-Object {$_.Department -eq "IT"}

# Fast - Server-side filtering
Get-ADUser -Filter {Department -eq "IT"}

# Slow - Get all then filter
Get-MgUser -All | Where-Object {$_.Department -eq "IT"}

# Fast - Filter parameter when available
Get-MgUser -Filter "Department eq 'IT'"
```

#### 9. Cache Expensive Operations
```powershell
# Slow - Repeated expensive calls
foreach ($email in $emails) {
    $user = Get-MgUser -Filter "mail eq '$email'"  # API call each time
    # Process user
}

# Fast - Cache results
$allUsers = Get-MgUser -All  # One API call
$userLookup = @{}
$allUsers | ForEach-Object { $userLookup[$_.Mail] = $_ }

foreach ($email in $emails) {
    $user = $userLookup[$email]  # Memory lookup
    # Process user
}
```

#### 10. Measure and Profile Your Code
```powershell
# Measure execution time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
# Your code here
$stopwatch.Stop()
Write-Status "Execution time: $($stopwatch.Elapsed.TotalSeconds) seconds" -Level Info

# Measure specific code blocks
Measure-Command {
    # Code to measure
}

# Profile multiple approaches
$methods = @{
    'Method1' = { Get-Process | Where-Object CPU -gt 100 }
    'Method2' = { Get-Process | Where-Object {$_.CPU -gt 100} }
}

foreach ($method in $methods.GetEnumerator()) {
    $time = (Measure-Command -Expression $method.Value).TotalMilliseconds
    Write-Status "$($method.Key): $time ms" -Level Debug
}
```

### Performance Best Practices Summary

1. **Filter early**: Reduce data volume as soon as possible
2. **Use .NET methods**: For file I/O, string manipulation, and collections
3. **Cache expensive operations**: API calls, remote queries, computations
4. **Choose right data structure**: Generic Lists over arrays with +=
5. **Avoid pipeline overhead**: Use foreach loops for large datasets
6. **Parallel processing**: Use -Parallel for independent operations (PS7+)
7. **Server-side filtering**: Use -Filter parameters when available
8. **Profile your code**: Measure before and after optimizations
9. **Batch operations**: Combine multiple API calls when possible
10. **Dispose resources**: Clean up connections and large objects

---

## Performance & Load Testing

### Goals
Beyond micro-optimizations, validate how scripts behave under volume (number of items) and concurrency (parallel operations). Establish baselines and Service Level Objectives (SLOs) such as: "Process 5,000 users in < 3 minutes" or "API failure recovery keeps error rate < 2%".

### Key Metrics
- **Throughput**: Items processed per second.
- **Latency**: Distribution (p50, p90, p99) of operation time.
- **Resource Usage**: Memory growth, CPU percentage spikes.
- **Error Rate**: Failures per batch; retry success ratio.
- **Idle Wait**: Time waiting on network vs active compute.

### Test Data Generation
```powershell
function New-FakeUsers {
    param([int]$Count = 1000)
    $list = [System.Collections.Generic.List[pscustomobject]]::new($Count)
    for ($i=1; $i -le $Count; $i++) {
        $list.Add([pscustomobject]@{Email="user$i@contoso.com"; Dept='IT'; Enabled=$true})
    }
    return $list
}
```

### Load Harness Pattern
```powershell
function Test-LoadPerformance {
    [CmdletBinding()]param(
        [int]$Items = 2000,
        [int]$Parallel = 10,
        [switch]$ParallelMode
    )

    $data = New-FakeUsers -Count $Items
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $errors = 0
    $processed = 0

    if ($ParallelMode) {
        $results = $data | ForEach-Object -Parallel {
            # Simulate work
            Start-Sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 25)
            if ((Get-Random -Minimum 0 -Maximum 200) -eq 42) { throw 'Synthetic failure' }
            $_
        } -ThrottleLimit $Parallel
    } else {
        $results = foreach ($item in $data) {
            try {
                Start-Sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 25)
                if ((Get-Random -Minimum 0 -Maximum 200) -eq 42) { throw 'Synthetic failure' }
                $item
            } catch { $errors++ }
            $processed++
        }
    }

    $stopwatch.Stop()
    $throughput = if ($stopwatch.Elapsed.TotalSeconds -gt 0) { [math]::Round($processed / $stopwatch.Elapsed.TotalSeconds,2) } else { 0 }
    [pscustomobject]@{
        Items       = $Items
        Parallel    = $ParallelMode.IsPresent
        ElapsedSec  = [math]::Round($stopwatch.Elapsed.TotalSeconds,2)
        Throughput  = $throughput
        Errors      = $errors
        ErrorRate   = if ($processed) { [math]::Round(($errors/$processed)*100,2) } else { 0 }
    }
}
```

### Measuring Memory
```powershell
$before = [GC]::GetTotalMemory($false)
# Run script logic here
$after = [GC]::GetTotalMemory($false)
Write-Status "Memory Delta: $([math]::Round(($after-$before)/1MB,2)) MB" -Level Info
```

### Profiling Strategies
1. **Stopwatch per logical phase** (validation, connection, processing, export).
2. **Custom timing wrapper**: Decorate functions to log start/end and duration.
3. **Compare sequential vs parallel**: Ensure parallelization saves wall-clock time and does not inflate error rate.
4. **Warm-up run**: Discard first run to mitigate JIT / module load overhead.

### Latency Bucket Logging
```powershell
$buckets = @{ '0-10ms'=0; '10-25ms'=0; '25-50ms'=0; '50ms+'=0 }
foreach ($item in 1..500) {
    $sw=[System.Diagnostics.Stopwatch]::StartNew(); Start-Sleep -Milliseconds (Get-Random -Minimum 3 -Maximum 60); $sw.Stop()
    $t=$sw.ElapsedMilliseconds
    switch ($t) {
        {$_ -le 10} { $buckets['0-10ms']++ }
        {$_ -le 25} { $buckets['10-25ms']++ }
        {$_ -le 50} { $buckets['25-50ms']++ }
        default { $buckets['50ms+']++ }
    }
}
$buckets.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize
```

### CI Integration
- Run a reduced load test nightly (not on every PR) to avoid long pipelines.
- Fail build if throughput regression exceeds defined threshold (e.g., >15% slower than baseline stored in JSON).
- Archive trend data for capacity planning.

### Establishing Baselines
Store baseline metrics:
```powershell
Test-LoadPerformance -Items 3000 | ConvertTo-Json | Set-Content baseline_performance.json
```
Compare current run:
```powershell
$baseline = Get-Content baseline_performance.json | ConvertFrom-Json
$current  = Test-LoadPerformance -Items 3000
if ($current.Throughput -lt ($baseline.Throughput * 0.85)) { Write-Error "Throughput regression detected" }
```

### Best Practices Summary
1. Define measurable SLOs up front.
2. Separate correctness tests from load/performance tests.
3. Automate regression detection (delta thresholds).
4. Simulate realistic error conditions and latency variance.
5. Log structured metrics for trend analysis.
6. Avoid over-parallelization that exhausts API rate limits.

---

## Cross-Platform PowerShell

### PowerShell Versions Overview

#### Windows PowerShell 5.1 (Legacy)
- **Platform**: Windows only
- **Runtime**: .NET Framework 4.x
- **Status**: Maintenance mode (no new features)
- **Use Case**: Legacy Windows systems, specific Windows-only modules
- **Path**: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`

#### PowerShell 7+ (Modern)
- **Platform**: Windows, Linux, macOS
- **Runtime**: .NET 6/7/8 (cross-platform)
- **Status**: Active development
- **Use Case**: New development, cross-platform automation, cloud-native workloads
- **Path**: `C:\Program Files\PowerShell\7\pwsh.exe` (Windows)

### Platform-Specific Considerations

#### File System Paths
```powershell
# WRONG - Windows-specific path separators
$path = "C:\Users\John\Documents\file.txt"

# RIGHT - Cross-platform path construction
$path = Join-Path $env:HOME "Documents" "file.txt"

# Or use .NET methods
$path = [System.IO.Path]::Combine($env:HOME, "Documents", "file.txt")

# Platform detection
if ($IsWindows) {
    $configPath = "C:\ProgramData\MyApp\config.json"
} elseif ($IsLinux) {
    $configPath = "/etc/myapp/config.json"
} elseif ($IsMacOS) {
    $configPath = "/usr/local/etc/myapp/config.json"
}
```

> Deprecation / Compatibility Note: Avoid relying on legacy OS detection via `[System.Environment]::OSVersion` or directly calling `[System.OperatingSystem]::IsWindows()` unless you have verified the target PowerShell edition supports the newer static methods. Windows PowerShell 5.1 (Desktop) does not expose the modern `OperatingSystem.IsWindows()` helpers. Prefer the built-in automatic variables `$IsWindows`, `$IsLinux`, `$IsMacOS` for cross-version scripts; use the static methods only inside guarded logic: `if ($PSVersionTable.PSEdition -eq 'Core' -and [System.OperatingSystem]::IsWindows()) { ... }`.
> OS Detection Note: You may use `[System.OperatingSystem]::IsWindows()` / `IsLinux()` / `IsMacOS()` for runtime-specific branching in 7.4+, but the `$Is*` automatic variables remain supported (not deprecated) and are still the simplest cross-version option.

#### Environment Variables
```powershell
# Cross-platform user profile
$userProfile = if ($IsWindows) { $env:USERPROFILE } else { $env:HOME }

# Temporary directory
$tempDir = if ($IsWindows) { $env:TEMP } else { $env:TMPDIR }

# Or use .NET
$tempDir = [System.IO.Path]::GetTempPath()
```

#### Line Endings
```powershell
# Platform-appropriate line endings
$newline = [System.Environment]::NewLine  # CRLF on Windows, LF on Unix

# Writing files with correct encoding
$content | Out-File -FilePath $path -Encoding UTF8 -NoNewline
$content | Add-Content -FilePath $path
```

#### Executables and Commands
```powershell
# WRONG - Assumes Windows
Start-Process "notepad.exe" -ArgumentList $file

# RIGHT - Platform-appropriate editors
if ($IsWindows) {
    Start-Process "notepad.exe" $file
} elseif ($IsLinux) {
    Start-Process "nano" $file
} elseif ($IsMacOS) {
    Start-Process "open" $file
}

# Better - Use native cmdlets when available
Get-Content $file  # Works everywhere
```

### PowerShell 7 New Features

#### Parallel Processing
```powershell
# PowerShell 7+ only - parallel ForEach-Object
$servers = @('server1', 'server2', 'server3', 'server4', 'server5')

$results = $servers | ForEach-Object -Parallel {
    Test-Connection $_ -Count 1 -Quiet
    [PSCustomObject]@{
        Server = $_
        Online = $?
        Timestamp = Get-Date
    }
} -ThrottleLimit 5

# Variables from parent scope require $using:
$timeout = 30
$results = $servers | ForEach-Object -Parallel {
    Test-NetConnection $_ -Port 443 -WarningAction SilentlyContinue -InformationLevel Quiet -TimeOut $using:timeout
} -ThrottleLimit 10
```

#### Ternary Operator
```powershell
# PowerShell 7+ - Ternary operator
$status = $isOnline ? "Online" : "Offline"

# PowerShell 5.1 equivalent
$status = if ($isOnline) { "Online" } else { "Offline" }
```

#### Null Coalescing
```powershell
# PowerShell 7+ - Null coalescing
$value = $input ?? $default

# PowerShell 5.1 equivalent
$value = if ($null -ne $input) { $input } else { $default }
```

#### Pipeline Chain Operators
```powershell
# PowerShell 7+ - Run next command only if previous succeeded
Get-ChildItem *.txt && Get-Content $_ | Select-String "error"

# PowerShell 7+ - Run next command only if previous failed
Test-Path $file || Write-Error "File not found"
```

### PowerShell 7.4+ Changes & Deprecations

PowerShell 7.4 (built on .NET 8) continues the trend of cleaning up legacy platform detection and environment APIs. Key points:

| Area | Legacy Pattern | Preferred Pattern (7.4+) | Notes |
|------|----------------|---------------------------|-------|
| OS Detection | `[System.Environment]::OSVersion.Platform` | `$IsWindows / $IsLinux / $IsMacOS` | Environment.OSVersion is not reliable for cross-platform feature gating. |
| OS Helpers | (Unavailable in 5.1) `[System.OperatingSystem]::IsWindows()` | Guarded use: `if ($PSVersionTable.PSEdition -eq 'Core' -and [System.OperatingSystem]::IsWindows())` | Only use when specific .NET behavior matters. |
| Path Handling | Manual string concatenation | `Join-Path`, `[System.IO.Path]::Combine()` | Reduces platform-specific bugs. |
| Encoding Default | OEM Code Page (5.1) | UTF-8 (7.4+) | PowerShell 7.4 defaults to UTF-8 without BOM, simplifying cross-platform text handling. |
| TLS / Crypto | Potential legacy protocol fallback | Modern protocols enforced | Remove explicit TLS 1.0/1.1 enabling code unless required. |
| Background Jobs | Legacy WinPS limitations | Improved job isolation | Test any custom runspace code for compatibility. |

Deprecation Guidance:
1. Avoid new reliance on `Environment.OSVersion`; prefer runtime feature detection (e.g., test module availability, use `$IsWindows`).
2. Migrate text operations to UTF-8 explicitly for consistency with 7.4 defaults.
3. Audit scripts for explicit code page conversions and remove unless required by system dependencies.
4. Consolidate platform branching by centralizing detection in a helper (`Get-PlatformInfo`) rather than scattering `if ($IsWindows)` checks.

Note: `$IsWindows`, `$IsLinux`, and `$IsMacOS` are NOT deprecated in PowerShell 7.4+; they remain the simplest, cross-version detection variables. The static helpers `[System.OperatingSystem]::IsWindows()` / `IsLinux()` / `IsMacOS()` are optional for scenarios where you need .NET runtime feature checks—use them inside guarded logic when you explicitly target PowerShell 7+ and newer .NET builds.

Helper pattern:
```powershell
function Get-PlatformInfo {
    [CmdletBinding()]param()
    $edition = $PSVersionTable.PSEdition
    $os = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
    [PSCustomObject]@{ OS=$os; Edition=$edition; Version=$PSVersionTable.PSVersion; Utf8Default=$edition -eq 'Core' }
}
```

Testing recommendation: Run critical scripts under 5.1 and 7.4 side-by-side; diff outputs and log any behavioral discrepancies (encoding, path resolution, module availability).

### Module Compatibility

#### Checking Compatibility
```powershell
# Check if module is compatible
$module = Get-Module -Name MyModule -ListAvailable
$module.CompatiblePSEditions  # Returns 'Desktop', 'Core', or both

# Require specific edition in script
#Requires -PSEdition Core  # PowerShell 7+ only
#Requires -PSEdition Desktop  # Windows PowerShell 5.1 only
```

#### Windows-Only Modules
Some modules only work on Windows PowerShell 5.1:
- **ActiveDirectory** module (older version)
- Some legacy Exchange modules
- Certain Windows-specific management tools

```powershell
# Handle Windows-only modules in cross-platform scripts
if ($IsWindows -and $PSVersionTable.PSEdition -eq 'Desktop') {
    Import-Module ActiveDirectory
} else {
    Write-Warning "ActiveDirectory module requires Windows PowerShell 5.1"
}
```

### Cross-Platform Script Template

```powershell
<#
.SYNOPSIS
    Cross-platform PowerShell script template
.NOTES
    Compatible with: PowerShell 5.1+ (Windows), PowerShell 7+ (All platforms)
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Platform detection
$platform = if ($IsWindows) { 
    "Windows" 
} elseif ($IsLinux) { 
    "Linux" 
} elseif ($IsMacOS) { 
    "macOS" 
} else { 
    "Unknown" 
}

Write-Status "Running on: $platform" -Level Info
Write-Status "PowerShell Version: $($PSVersionTable.PSVersion)" -Level Info
Write-Status "Edition: $($PSVersionTable.PSEdition)" -Level Info

# Set default output path based on platform
if (-not $OutputPath) {
    $OutputPath = if ($IsWindows) {
        Join-Path $env:USERPROFILE "Documents" "output.txt"
    } else {
        Join-Path $env:HOME "output.txt"
    }
}

# Use cross-platform path construction
$configDir = if ($IsWindows) {
    Join-Path $env:APPDATA "MyApp"
} else {
    Join-Path $env:HOME ".config" "myapp"
}

# Create directory if needed (cross-platform)
if (-not (Test-Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
}

# File operations with proper encoding
$content = @"
Platform: $platform
PowerShell: $($PSVersionTable.PSVersion)
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$content | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

Write-Status "Output written to: $OutputPath" -Level OK
```

### Testing Cross-Platform Scripts

```powershell
# Test on multiple platforms using Docker
# Windows Container
docker run -it --rm -v ${PWD}:/scripts mcr.microsoft.com/powershell:latest pwsh -File /scripts/myscript.ps1

# Linux Container
docker run -it --rm -v ${PWD}:/scripts mcr.microsoft.com/powershell:lts-ubuntu-22.04 pwsh -File /scripts/myscript.ps1

# Test with different PowerShell versions
# Windows PowerShell 5.1
powershell.exe -File .\myscript.ps1

# PowerShell 7
pwsh -File .\myscript.ps1
```

### Migration from Windows PowerShell to PowerShell 7

#### Key Differences to Address
1. **$PSVersionTable.PSEdition** - Check for 'Core' vs 'Desktop'
2. **Automatic variables** - Some may be missing or different in PS7
3. **Module compatibility** - Test all imported modules
4. **Performance** - PS7 is generally faster
5. **New syntax** - Leverage ternary operators, null coalescing, etc.

#### Migration Checklist
- [ ] Test on PowerShell 7 with `-PSEdition Core` requirement
- [ ] Replace Windows-specific paths with cross-platform alternatives
- [ ] Update module imports to use compatible versions
- [ ] Test file I/O with UTF-8 encoding
- [ ] Verify cmdlet availability across versions
- [ ] Update shebang for Unix systems: `#!/usr/bin/env pwsh`
- [ ] Test on actual target platforms (not just Docker)

---

## Security Considerations

### Input Validation
- **Sanitize All Inputs**: Validate format, existence, and safety
- **Domain Restrictions**: Enforce organizational policies
- **Permission Checks**: Verify user has required permissions
- **Path Validation**: Use `Test-Path` and validate file extensions
- **Script Injection Prevention**: Avoid using `Invoke-Expression` with user input

### Authentication Security
- **Modern Authentication**: Use OAuth 2.0 where available
- **Minimal Permissions**: Request least privilege required
- **Connection Encryption**: Ensure encrypted communications
- **Certificate-Based Auth**: Prefer certificates over passwords for service accounts

### Credential Management Best Practices

#### NEVER Store Credentials in Plain Text
**PROHIBITED PATTERNS:**
```powershell
# [X] NEVER DO THIS - Plain text credentials
$password = "MyPassword123"
$apiKey = "sk-1234567890abcdef"
$connectionString = "Server=sql.example.com;User=sa;Password=P@ssw0rd;"
```

#### Approved Credential Patterns

**1. Interactive Credential Prompts**
```powershell
# Secure credential prompt
$credential = Get-Credential -Message "Enter credentials for SQL Server"
$username = $credential.UserName
$password = $credential.GetNetworkCredential().Password
```

**2. SecretManagement Module (Recommended)**
```powershell
# Install SecretManagement and vault provider
Install-Module Microsoft.PowerShell.SecretManagement -Force
Install-Module SecretStore -Force

# Register secret vault
Register-SecretVault -Name LocalStore -ModuleName SecretStore -DefaultVault

# Store secrets securely
$credential = Get-Credential
Set-Secret -Name "SQLServerCred" -Secret $credential

# Retrieve secrets in scripts
$credential = Get-Secret -Name "SQLServerCred" -AsPlainText
```

**3. Encrypted XML Files (Legacy)**
```powershell
# Save credentials (one-time setup)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\creds.xml"

# Retrieve in script
$credential = Import-Clixml -Path "$env:USERPROFILE\creds.xml"
```

**4. Azure Key Vault (Enterprise)**
```powershell
# Store in Azure Key Vault
$secretValue = ConvertTo-SecureString "MySecretPassword" -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName "MyVault" -Name "SQLPassword" -SecretValue $secretValue

# Retrieve from Key Vault
$secret = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "SQLPassword"
$password = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
```

**5. Windows Credential Manager**
```powershell
# Using CredentialManager module
Install-Module CredentialManager -Force

# Store credential
New-StoredCredential -Target "MyApp" -UserName "user@domain.com" -Password "SecurePass123" -Persist LocalMachine

# Retrieve credential
$credential = Get-StoredCredential -Target "MyApp"
```

**6. Environment Variables (CI/CD Only)**
```powershell
# In CI/CD pipeline - store in secure pipeline variables
# Access in script
$apiKey = $env:API_KEY
$password = $env:SQL_PASSWORD

if (-not $apiKey) {
    throw "API_KEY environment variable not set"
}
```

**7. Certificate-Based Authentication**
```powershell
# Using certificate for authentication (no passwords)
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -eq "CN=MyAppCert"}
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $cert.Thumbprint
```

#### Managed Identity (Azure Resources)
```powershell
# For scripts running on Azure VMs/Functions/Automation
# No credentials needed - uses Azure Managed Identity
Connect-AzAccount -Identity

# Access Key Vault
$secret = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "Secret" -AsPlainText
```

### Security Validation Checklist

Before deploying any script, verify:

- [ ] No hardcoded passwords, API keys, or connection strings
- [ ] No plain text credentials in variables or comments
- [ ] No secrets in CSV templates or example files
- [ ] Credentials retrieved using approved patterns only
- [ ] Secrets stored in vault or secure credential manager
- [ ] Base64-encoded strings checked (could hide credentials)
- [ ] Environment variables validated before use
- [ ] Certificate files stored securely (not in code)
- [ ] Git repository scanned for accidentally committed secrets
- [ ] `.gitignore` includes credential files and secret paths

### Secret Scanning
```powershell
# Scan for potential secrets before commit
function Test-ScriptForSecrets {
    param([string]$Path)
    
    $suspiciousPatterns = @(
        'password\s*=\s*["\']',
        'apikey\s*=\s*["\']',
        'secret\s*=\s*["\']',
        'token\s*=\s*["\']',
        'connectionstring\s*=\s*["\']'
    )
    
    $content = Get-Content -Path $Path -Raw
    $issues = @()
    
    foreach ($pattern in $suspiciousPatterns) {
        if ($content -match $pattern) {
            $issues += "Potential secret found matching pattern: $pattern"
        }
    }
    
    if ($issues) {
        Write-Warning "Security issues found in $Path:"
        $issues | ForEach-Object { Write-Warning "  - $_" }
        return $false
    }
    
    return $true
}
```

### Endpoint Hardening
Just Enough Administration (JEA) and Windows Defender Application Control (WDAC) form a foundational pair for locking down PowerShell execution. JEA reduces administrative exposure by publishing constrained endpoints with role-capability files that strictly define which cmdlets, parameters, and providers a user can invoke, eliminating broad session elevation. WDAC enforces code integrity by allowing only trusted, signed binaries and scripts, and can automatically trigger Constrained Language Mode for anything outside the allowlist. Together they sharply narrow the usable surface area: JEA limits what can be asked of the system, WDAC limits what code the system will run. Combine them with least privilege groups, mandatory script signing, and periodic policy attestation (export and diff WDAC policy XML) to maintain trust.

Script Block Logging (Event ID 4104) and the Antimalware Scan Interface (AMSI) provide deep visibility and pre-execution inspection. Script Block Logging captures the full, deobfuscated PowerShell code that actually executes (post-expansion of encoded or concatenated payloads) enabling high-fidelity detection in a SIEM; enable it via Group Policy and forward events centrally. AMSI hands every script block to the installed antimalware engine (Defender or third-party) for real-time scanning, allowing detection of suspicious patterns even in memory. Ensure AMSI is not bypassed (monitor for known evasion strings), and correlate AMSI detections with 4104 events plus transcript logs for layered evidence. Periodically test with benign simulated payloads to verify logging and scanning paths remain intact.

#### JEA + WDAC vs Constrained Language Alone
Constrained Language Mode (CLM) lowers the expressive capability of PowerShell but does not itself apply least privilege to cmdlet scope or prevent execution of already present, potentially dangerous signed scripts. JEA applies role-based surface reduction: instead of relying on broad language restriction, it publishes tightly scoped endpoints exposing only the exact cmdlets, parameters, and providers needed. WDAC enforces code integrity so only trusted binaries and scripts (per signed/allowlisted policy) execute. Where CLM passively restricts language features, JEA and WDAC actively deny unauthorized actions and code paths.

Together, JEA and WDAC create a layered control: JEA limits what can be requested, WDAC limits what can run. CLM becomes a fallback safety net (triggered automatically for untrusted code under WDAC) rather than the primary defense. This pairing blocks entire classes of abuse (living-off-the-land enumeration, reflective loaders, downgrade attacks) that CLM by itself cannot fully mitigate. Design endpoints first (principle of least privilege), author WDAC policies that allow only signed corporate content and required Microsoft modules, then confirm CLM engages only for unexpected code, reducing noise.

Operationally, track: (1) JEA endpoint command invocation logs, (2) WDAC denied events, (3) CLM activation frequency, (4) Script Block Logging anomalies, and (5) AMSI detections. A healthy hardened environment shows low CLM activations (because most activity occurs in approved endpoints), scarce WDAC denies (policy tuned), and zero unexplained AMSI hits. Review WDAC policy XML diffs quarterly and revalidate JEA role capability files after module updates to keep the control plane ahead of emerging attack primitives.

## Code Signing & Execution Policy

### Overview
Code signing helps ensure script integrity and origin. Execution Policy governs how Windows PowerShell and PowerShell 7 treat unsigned or remote scripts. Execution Policy is **not** a security boundary but a first-line safeguard against accidental execution.

### Execution Policy Levels
- **Restricted**: No scripts run.
- **RemoteSigned**: Local scripts run; remote scripts must be signed.
- **AllSigned**: All scripts must be signed.
- **Bypass**: No restrictions (use sparingly in automation contexts).
- **Undefined**: Inheritance from higher scope.

Scopes: MachinePolicy, UserPolicy, Process, CurrentUser, LocalMachine.

```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

### Obtaining a Code Signing Certificate
Options:
1. Internal PKI (Active Directory Certificate Services) – Template: Code Signing.
2. Commercial CA – For broader trust distribution.
3. Self-signed (development only) – Lower trust; must import to Trusted Publishers.

```powershell
# Development self-signed example
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=CTG Dev Code Signing" -CertStoreLocation Cert:\CurrentUser\My
```

### Signing a Script
```powershell
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like '*CTG Dev Code Signing*' }
Set-AuthenticodeSignature -FilePath .\Set-MailboxQuota.ps1 -Certificate $cert | Format-List
```

### Verifying Signature
```powershell
Get-AuthenticodeSignature -FilePath .\Set-MailboxQuota.ps1 | Select-Object Status,SignerCertificate
```
Statuses: Valid, NotSigned, UnknownError, HashMismatch.

### CI/CD Integration
- Ensure build agent has access to signing cert (secure secret retrieval or certificate store import).
- Sign artifacts just before packaging and publishing.
- Fail pipeline if signature invalid or timestamp service unreachable.

```powershell
# Example: Sign all release scripts
Get-ChildItem .\Release\*.ps1 | ForEach-Object {
    $sig = Set-AuthenticodeSignature -FilePath $_.FullName -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'
    if ($sig.Status -ne 'Valid') { throw "Signing failed for $($_.Name)" }
}
```

### Best Practices
1. Prefer AllSigned for administrative consoles; RemoteSigned for development.
2. Protect private keys; restrict certificate export permissions.
3. Use timestamping to preserve validity after certificate expiration.
4. Review signatures during code review for critical scripts.
5. Avoid lowering execution policy globally; use Process scope when necessary.

## Constrained Language Mode

### Overview
Constrained Language Mode (CLM) restricts PowerShell language features (dynamic code generation, some .NET usage) to reduce attack surface when AppLocker or WDAC policies enforce restrictions. It limits operations that could lead to arbitrary code execution.

### Detection
```powershell
$mode = $ExecutionContext.SessionState.LanguageMode
Write-Status "Language Mode: $mode" -Level Info
```
Modes: FullLanguage, ConstrainedLanguage, RestrictedLanguage, NoLanguage.

### Key Limitations Under CLM
- `Add-Type` blocked.
- Direct invocation of many .NET methods restricted (especially reflection/emission APIs).
- COM object creation denied.
- Certain dynamic module loading scenarios prohibited.

### Adaptation Strategies
1. Avoid reflection-based utilities; use approved cmdlets.
2. Precompile required helper assemblies outside CLM environment.
3. Use pure PowerShell logic (no dynamic type generation).
4. Test critical scripts in a CLM sandbox early.

### Testing in CLM (Lab)
```powershell
# Simulate CLM via Device Guard / WDAC test environment or use Windows 10/11 with AppLocker policy
# Force process-scoped policy for evaluation (development only):
powershell.exe -NoProfile -ExecutionPolicy AllSigned -File .\TestScript.ps1
```

### Handling Failures
Catch and surface clear messages when blocked operations occur; provide remediation guidance (e.g., "Reflection usage not supported under Constrained Language Mode; please run on approved admin host.").

### Security Complement
CLM complements script signing and least privilege by reducing capabilities available to untrusted code if it executes.

### Best Practices Summary
1. Detect and log language mode at script start.
2. Offer degraded-mode behavior (skip advanced features) rather than hard failure.
3. Keep a compatibility matrix (feature vs language mode support).
4. Document any functionality unavailable under CLM in README.

## Version Control & Maintenance

### Versioning Strategy

#### Semantic Versioning (SemVer)
Format: **MAJOR.MINOR.PATCH** (e.g., 2.4.1)

- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (x.X.0): New features, backward-compatible additions
- **PATCH** (x.x.X): Bug fixes, backward-compatible fixes

#### Practical Examples

**Version 1.0.0 → 1.0.1** (Patch)
```powershell
# Fixed: Validation error message typo
# Fixed: Progress bar calculation when count is zero
# No parameter changes, no new features
```

**Version 1.0.1 → 1.1.0** (Minor)
```powershell
# Added: -SkipValidation parameter for edge cases
# Added: Export results to JSON format option
# All existing scripts continue to work
```

**Version 1.1.0 → 2.0.0** (Major)
```powershell
# BREAKING: Renamed -UserEmail to -UserPrincipalName
# BREAKING: Removed deprecated -LegacyMode parameter
# BREAKING: Changed return object structure
# Requires script updates to use new version
```

#### Version Tracking in Scripts
```powershell
<#
.NOTES
    Version: 2.3.1
    
    Version History:
    2.3.1 - 2025-11-19 - Fixed validation bug for external domains
    2.3.0 - 2025-11-15 - Added CSV export option
    2.2.0 - 2025-11-01 - Added Interactive mode
    2.1.0 - 2025-10-20 - Added WhatIf support
    2.0.0 - 2025-10-01 - Breaking: Renamed parameters for consistency
    1.0.0 - 2025-09-15 - Initial release
#>

# Declare version as variable for runtime access
[version]$ScriptVersion = "2.3.1"
```

### Maintenance Planning
- **Module Dependencies**: Track and update required modules
- **API Changes**: Monitor for service API updates
- **Permission Changes**: Watch for permission model updates
- **Deprecation Notices**: Provide advance warning before removing features
- **Backward Compatibility**: Support previous version patterns when possible

---

## Module Development

### Module Structure

#### Script Module (.psm1) Structure
```
MyPowerShellModule/
├── MyPowerShellModule.psd1       # Module manifest
├── MyPowerShellModule.psm1       # Main module file
├── Public/                        # Exported functions
│   ├── Get-Something.ps1
│   ├── Set-Something.ps1
│   └── Remove-Something.ps1
├── Private/                       # Internal helper functions
│   ├── Test-Validation.ps1
│   └── Initialize-Connection.ps1
├── Classes/                       # PowerShell classes (optional)
│   └── MyCustomClass.ps1
├── Data/                          # Module data files
│   └── config.json
├── Tests/                         # Pester tests
│   ├── Public/
│   └── Private/
├── docs/                          # Documentation
│   └── README.md
└── LICENSE.txt
```

### Creating a Module

#### Step 1: Module Manifest (.psd1)
```powershell
# Create new module manifest
New-ModuleManifest -Path .\MyModule.psd1 `
    -Author "Your Name" `
    -CompanyName "Your Company" `
    -Description "Description of what the module does" `
    -ModuleVersion "1.0.0" `
    -PowerShellVersion "5.1" `
    -RootModule "MyModule.psm1" `
    -FunctionsToExport @('Get-Something', 'Set-Something') `
    -CmdletsToExport @() `
    -VariablesToExport @() `
    -AliasesToExport @() `
    -RequiredModules @('Microsoft.Graph.Authentication') `
    -Tags @('Automation', 'Productivity', 'Exchange') `
    -ProjectUri "https://github.com/yourorg/yourmodule" `
    -LicenseUri "https://github.com/yourorg/yourmodule/blob/main/LICENSE" `
    -ReleaseNotes "Initial release"
```

#### Step 2: Module File (.psm1)
```powershell
# MyModule.psm1

# Import private functions
$privateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
foreach ($file in $privateFunctions) {
    . $file.FullName
}

# Import public functions
$publicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
foreach ($file in $publicFunctions) {
    . $file.FullName
}

# Export only public functions
Export-ModuleMember -Function $publicFunctions.BaseName

# Module initialization code
Write-Verbose "MyModule loaded successfully"
```

#### Step 3: Public Function Example
```powershell
# Public\Get-Something.ps1

function Get-Something {
    <#
    .SYNOPSIS
        Retrieves something from a service
    .DESCRIPTION
        Detailed description of what this function does
    .PARAMETER Name
        Name of the item to retrieve
    .EXAMPLE
        Get-Something -Name "Item1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    
    begin {
        Write-Verbose "Starting Get-Something"
        # Initialization code
    }
    
    process {
        try {
            # Main logic
            Write-Verbose "Processing: $Name"
            
            # Use private helper function
            $validated = Test-InternalValidation -Input $Name
            
            if ($validated) {
                # Return result
                [PSCustomObject]@{
                    Name = $Name
                    Result = "Success"
                    Timestamp = Get-Date
                }
            }
        }
        catch {
            Write-Error "Failed to process $Name: $_"
        }
    }
    
    end {
        Write-Verbose "Completed Get-Something"
    }
}
```

#### Step 4: Private Function Example
```powershell
# Private\Test-InternalValidation.ps1

function Test-InternalValidation {
    <#
    .SYNOPSIS
        Internal validation function (not exported)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Input
    )
    
    # Validation logic
    return ($Input.Length -gt 0)
}
```

### Testing Modules

#### Module Test Structure (Pester)
```powershell
# Tests\Public\Get-Something.Tests.ps1

BeforeAll {
    # Import module
    $modulePath = Join-Path $PSScriptRoot ".." ".." "MyModule.psd1"
    Import-Module $modulePath -Force
}

Describe "Get-Something" {
    Context "Parameter Validation" {
        It "Should require Name parameter" {
            { Get-Something } | Should -Throw
        }
        
        It "Should not accept null or empty Name" {
            { Get-Something -Name "" } | Should -Throw
        }
    }
    
    Context "Functionality" {
        It "Should return PSCustomObject with expected properties" {
            $result = Get-Something -Name "Test"
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "Name"
            $result.PSObject.Properties.Name | Should -Contain "Result"
            $result.PSObject.Properties.Name | Should -Contain "Timestamp"
        }
        
        It "Should accept pipeline input" {
            $result = "Test1", "Test2" | Get-Something
            $result.Count | Should -Be 2
        }
    }
}

AfterAll {
    Remove-Module MyModule -Force -ErrorAction SilentlyContinue
}
```

### Publishing Modules

#### Publishing to PowerShell Gallery
```powershell
# 1. Register for PowerShell Gallery API key at https://www.powershellgallery.com

# 2. Test module manifest
Test-ModuleManifest -Path .\MyModule.psd1

# 3. Run Pester tests
Invoke-Pester -Path .\Tests\ -OutputFormat NUnitXml -OutputFile TestResults.xml

# 4. Analyze with PSScriptAnalyzer
$analysisResults = Invoke-ScriptAnalyzer -Path .\ -Recurse -Severity Error,Warning
if ($analysisResults) {
    throw "PSScriptAnalyzer found issues"
}

# 5. Publish to PowerShell Gallery
$apiKey = Get-Secret -Name "PSGalleryAPIKey" -AsPlainText
Publish-Module -Path .\MyModule -NuGetApiKey $apiKey -Repository PSGallery

# 6. Verify publication
Find-Module -Name MyModule -Repository PSGallery
```

#### Publishing to Private Repository
```powershell
# Register private repository
Register-PSRepository -Name "CompanyInternal" `
    -SourceLocation "https://nuget.company.com/v3/index.json" `
    -PublishLocation "https://nuget.company.com/api/v2/package" `
    -InstallationPolicy Trusted

# Publish to private repository
Publish-Module -Path .\MyModule -Repository CompanyInternal -NuGetApiKey $apiKey
```

### Module Best Practices

#### Naming Conventions
- **Module Name**: Use singular nouns (e.g., `MyCompany.UserManagement`, not `MyCompany.UsersManagement`)
- **Function Names**: Verb-Noun format using approved verbs (e.g., `Get-User`, `Set-Mailbox`)
- **Approved Verbs**: Use `Get-Verb` to see approved verbs

```powershell
# Check if verb is approved
Get-Verb -Verb "Fetch"  # Returns nothing (not approved)
Get-Verb -Verb "Get"    # Returns verb info (approved)
```

#### Function Organization
```powershell
# Logical grouping in manifest
FunctionsToExport = @(
    # User Management
    'Get-User',
    'New-User',
    'Set-User',
    'Remove-User',
    
    # Group Management
    'Get-Group',
    'New-Group',
    'Add-GroupMember',
    'Remove-GroupMember'
)
```

#### Version Management
```powershell
# Update version in manifest
Update-ModuleManifest -Path .\MyModule.psd1 -ModuleVersion "1.1.0"

# Add release notes
Update-ModuleManifest -Path .\MyModule.psd1 `
    -ReleaseNotes "v1.1.0: Added Get-Group function, fixed bug in Set-User"
```

#### Documentation
```powershell
# Generate external help (MAML)
# 1. Install PlatyPS
Install-Module -Name PlatyPS -Force

# 2. Generate markdown help files
New-MarkdownHelp -Module MyModule -OutputFolder .\docs

# 3. Update help files as needed
Update-MarkdownHelp -Path .\docs

# 4. Create external help
New-ExternalHelp -Path .\docs -OutputPath .\en-US -Force

# Users can then use Update-Help
Update-Help -Module MyModule
```

### Module Distribution

#### Internal Distribution
```powershell
# Option 1: Network share
Copy-Item -Path .\MyModule -Destination "\\fileserver\PowerShell\Modules\" -Recurse

# Users add to $env:PSModulePath
$env:PSModulePath += ";\\fileserver\PowerShell\Modules"

# Option 2: NuGet feed (Azure Artifacts, ProGet, etc.)
# Publish to internal NuGet feed as shown in Publishing section
```

#### Version Pinning for Stability
```powershell
# In production scripts, specify exact version
Import-Module MyModule -RequiredVersion 1.2.3

# In manifest, specify minimum version
RequiredModules = @(
    @{ModuleName = 'MyModule'; ModuleVersion = '1.2.3'}
)
```

---

## Development Workflow

## Desired State Configuration (DSC)

> **2025 Update**: Classic PSDSC (v1/v2) remains fully supported in Windows.
> For new configuration management projects, evaluate Microsoft Desired State Configuration v3
> (standalone `dsc` CLI, YAML/JSON configs, true cross-platform, no LCM) - https://learn.microsoft.com/en-us/powershell/dsc/

> [WARNING] DSC v2 is in maintenance mode. For new configuration automation in 2025+, evaluate DSC v3 (PowerShell DSC for Azure), Azure Policy/Automanage, or cross-platform tools (Ansible, Terraform). The guidance below is retained for existing deployments and controlled legacy environments; plan migration for net-new projects.

### Purpose
DSC provides declarative, continuously enforced configuration management. It complements imperative scripts: use scripts for transient, procedural tasks and DSC for stable, convergent state (roles, features, registry baselines). Promoted here as a standalone capability rather than a core scripting pattern.

### Core Building Blocks
- **Configuration Function**: Generates MOF documents describing desired state.
- **Resources**: Units enforcing state (File, Service, Registry, Script, Custom, Composite).
- **LCM (Local Configuration Manager)**: Agent applying, monitoring, re-applying configurations.
- **MOF Documents**: Compiled configuration artifacts consumed by LCM.
- **Push / Pull Modes**: Manual deployment vs scheduled retrieval from a pull server.
- **Partial Configurations**: Segmented responsibility (SecurityBaseline, AppLayer, Monitoring).

### When DSC Adds Value
Use DSC when you need drift correction, predictable convergence, audit trails, and separation of authoring vs application. Avoid DSC for one-time migrations, complex iterative transformations, or dynamic branching logic.

### Configuration Example
```powershell
configuration WebServerConfig {
    param(
        [string]$NodeName,
        [string]$WebsiteRoot = 'C:\InetPub\WWWRoot'
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node $NodeName {
        WindowsFeature WebServer { Name='Web-Server'; Ensure='Present' }
        File WebsiteRoot { DestinationPath=$WebsiteRoot; Type='Directory'; Ensure='Present' }
    }
}
WebServerConfig -NodeName 'SERVER01'
Start-DscConfiguration -Path .\WebServerConfig -Wait -Verbose -Force
```

### Inline Generation Pattern
```powershell
function Invoke-ServerBaseline {
    [CmdletBinding()]param(
        [Parameter(Mandatory)][string[]]$ComputerName,
        [switch]$Wait
    )
    configuration ServerBaseline {
        param([string[]]$Nodes)
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        Node $Nodes {
            WindowsFeature RSATTools { Name='RSAT-AD-PowerShell'; Ensure='Present' }
            Registry DisableIPv6 {
                Key='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
                ValueName='DisabledComponents'; ValueData=0xFF; ValueType='Dword'; Ensure='Present'
            }
        }
    }
    ServerBaseline -Nodes $ComputerName
    Start-DscConfiguration -Path .\ServerBaseline -Force -Verbose -Wait:$Wait
}
```

### Pull Server & Scale Considerations
- Use pull for >100 nodes to reduce orchestration overhead.
- Version configuration names for staged rollout (e.g., WebBaseline_v3).
- Secure with HTTPS; ensure MOF encryption via certificate.

### Security & Secret Handling
- Never store plaintext credentials in MOF; use certificates for secure data blocks.
- Audit MOF before distribution; scan for inadvertent secrets.

### Testing & Idempotence
```powershell
Start-DscConfiguration -Path .\ServerBaseline -Verbose -Force -Wait | Out-Null
Start-DscConfiguration -Path .\ServerBaseline -Verbose -Force -Wait | Out-Null  # Second run should apply nothing
```

Validate idempotence early; a configuration that continually reapplies is inefficient or incorrect.

### Drift Detection Strategy
- Schedule periodic Get-DscConfigurationStatus exports for compliance dashboards.
- Alert on repeated corrective actions (indicates unmanaged process breaking state).

### Best Practices Summary
1. Keep configurations small, modular, composable.
2. Externalize variable data (JSON/CSV) instead of hardcoding.
3. Use composite resources for repeated multi-resource patterns.
4. Sign configuration scripts; store MOF securely.
5. Enforce encryption for sensitive properties.
6. Document convergence time and recovery steps.
7. Limit imperative logic inside configuration blocks; keep them declarative.

---

### Initial Development
1. **Requirements Gathering**: Understand use cases and constraints
2. **API Research**: Understand service capabilities and limitations
3. **Architecture Design**: Plan authentication and data flow
4. **Parameter Design**: Design flexible parameter sets
5. **Core Implementation**: Build core functionality
6. **Validation Layer**: Add comprehensive validation
7. **User Experience**: Add progress feedback and error handling
8. **Documentation**: Create help and README documentation
9. **Testing**: Comprehensive testing across scenarios
10. **Quality Review**: Final review and optimization

### Iterative Improvement
1. **User Feedback**: Collect and analyze usage feedback
2. **Error Analysis**: Review common error patterns
3. **Performance Optimization**: Address bottlenecks
4. **Feature Enhancement**: Add requested capabilities
5. **Documentation Updates**: Keep documentation current

## Common Patterns & Templates

### Validation Function Template
```powershell
function Test-EntityComprehensive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Entity,
        
        [string]$RequiredPattern,
        [switch]$SkipFormatValidation,
        [switch]$SkipExistenceValidation
    )
    
    $result = [PSCustomObject]@{
        OverallValid = $false
        Issues = @()
        EntityExists = $false
        FormatValid = $false
    }
    
    # Format validation
    if (-not $SkipFormatValidation) {
        # Implement format checks
    }
    
    # Existence validation  
    if (-not $SkipExistenceValidation) {
        # Implement existence checks
    }
    
    $result.OverallValid = (-not $result.Issues.Count)
    return $result
}
```

### Connection Management Template
```powershell
function Initialize-ServiceConnection {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Checking [Service] connection"
    
    if (-not (Get-Module -ListAvailable -Name [ServiceModule])) {
        throw "[Service] module required but not installed"
    }
    
    $connectionStatus = [Check existing connection]
    if (-not $connectionStatus) {
        Write-Status "[Service] session not detected. Connecting..." -Level Warning
        try {
            [Connect-Service] -ShowProgress:$false -WarningAction SilentlyContinue
            Write-Status "Successfully connected to [Service]" -Level OK
        }
        catch {
            throw "Failed to connect to [Service]: $($_.Exception.Message)"
        }
    } else {
        Write-Status "[Service] connection verified" -Level OK
    }
}
```

## Complete Example Script

This example demonstrates all best practices in a single script:

```powershell
<#
.SYNOPSIS
    Sets mailbox quotas for Exchange Online users

.DESCRIPTION
    Configures storage quotas for Exchange Online mailboxes with comprehensive
    validation, multiple input methods, and detailed progress reporting.
    
    Supports three input methods:
    - Array: Direct parameter input for scripting
    - CSV: Bulk operations from file
    - Interactive: Guided user input
    
    Validates all inputs before processing and provides detailed results export.

.PARAMETER UserEmails
    Array of user email addresses to update

.PARAMETER CsvPath
    Path to CSV file with EmailAddress column

.PARAMETER Interactive
    Enable interactive mode for guided input

.PARAMETER QuotaGB
    Storage quota size in gigabytes (default: 50)

.PARAMETER SkipValidation
    Skip email format and existence validation

.EXAMPLE
    .\Set-MailboxQuota.ps1 -UserEmails @("user1@domain.com","user2@domain.com") -QuotaGB 100
    
    Sets 100GB quota for specified users using array input

.EXAMPLE
    .\Set-MailboxQuota.ps1 -CsvPath "users.csv" -QuotaGB 50 -WhatIf
    
    Preview quota changes for users in CSV file

.EXAMPLE
    .\Set-MailboxQuota.ps1 -Interactive
    
    Launch interactive mode with guided prompts

.NOTES
    Author: Bill Kindle (with AI assistance)
    Version: 1.0
    Created: 2025-11-19
    Requires: ExchangeOnlineManagement module
    
    Required Permissions:
    - Exchange Administrator or Mailbox Administrator role
    
    Setup Instructions:
    1. Install module: Install-Module ExchangeOnlineManagement -Force
    2. Connect: Connect-ExchangeOnline
    3. Run script with desired input method
#>

#Requires -Module ExchangeOnlineManagement

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Array')]
    [ValidateNotNullOrEmpty()]
    [string[]]$UserEmails,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'CSV')]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$CsvPath,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
    [switch]$Interactive,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000)]
    [int]$QuotaGB = 50,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation
)

#region Helper Functions

function Test-EmailComprehensive {
    <#
    .SYNOPSIS
        Comprehensive email validation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EmailAddress,
        
        [switch]$SkipValidation
    )
    
    $result = [PSCustomObject]@{
        OverallValid = $false
        Issues = @()
        FormatValid = $false
        MailboxExists = $false
    }
    
    if ($SkipValidation) {
        $result.OverallValid = $true
        $result.FormatValid = $true
        $result.MailboxExists = $true
        return $result
    }
    
    # Format validation
    if ($EmailAddress -match '^[^@]+@[^@]+\.[^@]+$') {
        $result.FormatValid = $true
    } else {
        $result.Issues += "Invalid email format"
    }
    
    # Mailbox existence check
    if ($result.FormatValid) {
        try {
            $mailbox = Get-EXOMailbox -Identity $EmailAddress -ErrorAction Stop
            $result.MailboxExists = $true
        } catch {
            $result.Issues += "Mailbox not found"
        }
    }
    
    $result.OverallValid = (-not $result.Issues.Count)
    return $result
}

function Initialize-ExchangeOnlineConnection {
    <#
    .SYNOPSIS
        Establishes Exchange Online connection
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "Checking Exchange Online connection"
    
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module not installed. Install with: Install-Module ExchangeOnlineManagement -Force"
    }
    
    $connectionStatus = Get-ConnectionInformation -ErrorAction SilentlyContinue
    if (-not $connectionStatus) {
        Write-Status "Exchange Online connection not detected. Connecting..." -Level Warning
        try {
            Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
            Write-Status "Successfully connected to Exchange Online" -Level OK
        } catch {
            throw "Failed to connect to Exchange Online: $($_.Exception.Message)"
        }
    } else {
        Write-Status "Exchange Online connection verified" -Level OK
    }
}

function Get-InteractiveInput {
    <#
    .SYNOPSIS
        Prompts user for interactive input
    #>
    [CmdletBinding()]
    param()
    
    Write-Status "=== Interactive Mode ===" -Level Info
    
    $emails = @()
    do {
        $email = Read-Host "Enter email address (or 'done' to finish)"
        if ($email -ne 'done' -and -not [string]::IsNullOrWhiteSpace($email)) {
            $emails += $email
        }
    } while ($email -ne 'done')
    
    if ($emails.Count -eq 0) {
        throw "No email addresses provided"
    }
    
    return $emails
}

#endregion

#region Main Execution

try {
    Write-Status "=== Mailbox Quota Configuration Script ===" -Level Info
    Write-Status "Version: 1.0" -Level Info
    
    # Initialize connection
    Initialize-ExchangeOnlineConnection
    
    # Determine input source
    switch ($PSCmdlet.ParameterSetName) {
        'Array' {
            $emailsToProcess = $UserEmails
        }
        'CSV' {
            Write-Status "Reading CSV file: $CsvPath" -Level Info
            $csvData = Import-Csv -Path $CsvPath
            if (-not $csvData.EmailAddress) {
                throw "CSV must contain 'EmailAddress' column"
            }
            $emailsToProcess = $csvData.EmailAddress
        }
        'Interactive' {
            $emailsToProcess = Get-InteractiveInput
        }
    }
    
    Write-Status "Processing $($emailsToProcess.Count) email(s)" -Level Info
    Write-Status "Quota size: $QuotaGB GB" -Level Info
    
    # Validation phase
    Write-Status "=== Validation Phase ===" -Level Info
    $validEmails = @()
    $invalidEmails = @()
    
    foreach ($email in $emailsToProcess) {
        Write-Verbose "Validating: $email"
        $validation = Test-EmailComprehensive -EmailAddress $email -SkipValidation:$SkipValidation
        
        if ($validation.OverallValid) {
            $validEmails += $email
            Write-Status "  $email" -Level OK
        } else {
            $invalidEmails += $email
            Write-Status "  $email - $($validation.Issues -join ', ')" -Level Error
        }
    }
    
    Write-Status "Valid: $($validEmails.Count) | Invalid: $($invalidEmails.Count)" -Level Info
    
    if ($validEmails.Count -eq 0) {
        throw "No valid emails to process"
    }
    
    # Confirmation
    if (-not $PSCmdlet.ShouldProcess("$($validEmails.Count) mailboxes", "Set quota to $QuotaGB GB")) {
        Write-Status "Operation cancelled" -Level Warning
        return
    }
    
    # Processing phase
    Write-Status "=== Processing Phase ===" -Level Info
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $successCount = 0
    $failureCount = 0
    
    $i = 0
    foreach ($email in $validEmails) {
        $i++
        Write-Progress -Activity "Setting mailbox quotas" -Status "Processing $email ($i of $($validEmails.Count))" -PercentComplete (($i / $validEmails.Count) * 100)
        
        $result = [PSCustomObject]@{
            EmailAddress = $email
            Success = $false
            QuotaGB = $QuotaGB
            Message = ""
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            if ($PSCmdlet.ShouldProcess($email, "Set ProhibitSendReceiveQuota to $QuotaGB GB")) {
                Set-Mailbox -Identity $email -ProhibitSendReceiveQuota "$($QuotaGB)GB" -ErrorAction Stop
                $result.Success = $true
                $result.Message = "Quota set successfully"
                $successCount++
                Write-Status "  $email" -Level OK
            }
        } catch {
            $result.Success = $false
            $result.Message = $_.Exception.Message
            $failureCount++
            Write-Status "  $email - $($_.Exception.Message)" -Level Error
        }
        
        $results.Add($result)
    }
    
    Write-Progress -Activity "Setting mailbox quotas" -Completed
    
    # Results summary
    Write-Status "=== Results Summary ===" -Level Info
    Write-Status "Total Processed: $($validEmails.Count)" -Level Info
    Write-Status "Successful: $successCount" -Level OK
    Write-Status "Failed: $failureCount" -Level (if ($failureCount -gt 0) { 'Error' } else { 'Info' })
    
    # Export results
    $outputPath = "MailboxQuota_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $results | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Status "Detailed results exported to: $outputPath" -Level Info
    
} catch {
    Write-Error "Script failed: $($_.Exception.Message)"
    exit 1
} finally {
    Write-Status "Script execution completed" -Level Info
}

#endregion
```

### What This Example Demonstrates

1. **Complete Help Documentation**: Synopsis, description, parameters, examples, and notes
2. **Parameter Sets**: Array, CSV, and Interactive input methods
3. **Validation Framework**: Comprehensive email validation with skip option
4. **Connection Management**: Single connection pattern with verification
5. **Progress Feedback**: Color-coded messages and progress bars
6. **Error Handling**: Try-catch with detailed error messages
7. **Results Export**: Timestamped CSV output
8. **SupportsShouldProcess**: WhatIf and Confirm support
9. **Performance**: Generic List for results collection
10. **User Experience**: Clear visual feedback throughout execution

## Lessons Learned

### Technical Insights
1. **API Limitations**: Not all operations are available through all APIs - research capabilities early
2. **Hybrid Approaches**: Combining multiple services can provide complete solutions
3. **Connection Management**: Establish connections once, reuse throughout execution
4. **Validation Importance**: Comprehensive validation prevents downstream issues and improves user experience

### User Experience Insights
1. **Multiple Input Methods**: Users have different preferences and use cases - accommodate them
2. **Clear Feedback**: Users need to know what's happening, why, and what's next
3. **Override Options**: Provide escape hatches for edge cases and unusual scenarios
4. **Documentation Critical**: Good documentation makes or breaks script adoption

### Development Process Insights
1. **Iterative Development**: Start simple, add complexity gradually based on real needs
2. **Testing Early**: Test edge cases as you develop, not just happy path scenarios
3. **User Feedback**: Real usage reveals unexpected scenarios and improvement opportunities
4. **Documentation Concurrent**: Write documentation as you develop, not as an afterthought

This guide should serve as a template for future PowerShell script development, ensuring consistent quality and user experience across projects.

## Anti-Patterns - What NOT to Do

### Security Anti-Patterns

#### [X] NEVER: Hardcoded Credentials
```powershell
# WRONG - Plain text credentials
$password = "MyPassword123"
$apiKey = "sk-1234567890abcdef"
Connect-Service -ApiKey "hardcoded-key"

# RIGHT - Use secure credential management
$credential = Get-Secret -Name "ServiceCred"
Connect-Service -Credential $credential
```

#### [X] NEVER: Invoke-Expression with User Input
```powershell
# WRONG - Script injection vulnerability
Invoke-Expression "Get-Process -Name $userInput"

# RIGHT - Use parameters safely
Get-Process -Name $userInput
```

#### [X] NEVER: Disable Security Features
```powershell
# WRONG - Disabling execution policy in scripts
Set-ExecutionPolicy Bypass -Scope Process -Force

# RIGHT - Users should set execution policy appropriately
# Don't modify execution policy in scripts
```

### Connection Management Anti-Patterns

#### [X] NEVER: Connect Inside Loops
```powershell
# WRONG - Reconnecting for each operation
foreach ($user in $users) {
    Connect-ExchangeOnline -UserPrincipalName admin@domain.com
    Set-Mailbox -Identity $user -IssueWarningQuota 9GB
    Disconnect-ExchangeOnline -Confirm:$false
}

# RIGHT - Connect once at script start
Connect-ExchangeOnline -UserPrincipalName admin@domain.com
foreach ($user in $users) {
    Set-Mailbox -Identity $user -IssueWarningQuota 9GB
}
Disconnect-ExchangeOnline -Confirm:$false
```

#### [X] NEVER: Skip Connection Validation
```powershell
# WRONG - Assuming connection exists
Get-Mailbox -Identity $user  # Fails if not connected

# RIGHT - Validate connection first
if (-not (Get-ConnectionInformation)) {
    Connect-ExchangeOnline
}
Get-Mailbox -Identity $user
```

### Performance Anti-Patterns

#### [X] NEVER: Use += with Arrays in Loops
```powershell
# WRONG - Creates new array each iteration (O(n²))
$results = @()
foreach ($item in $largeDataset) {
    $results += $item  # Very slow!
}

# RIGHT - Use Generic List
$results = [System.Collections.Generic.List[object]]::new()
foreach ($item in $largeDataset) {
    $results.Add($item)
}
```

#### [X] NEVER: Get All Data Then Filter
```powershell
# WRONG - Retrieve everything then filter
$users = Get-ADUser -Filter * | Where-Object {$_.Department -eq "IT"}

# RIGHT - Filter at source
$users = Get-ADUser -Filter {Department -eq "IT"}
```

#### [X] NEVER: Unnecessary Pipeline Usage for Large Data
```powershell
# WRONG - Pipeline overhead for large datasets
1..100000 | ForEach-Object { $_ * 2 }

# RIGHT - Use foreach loop
$results = foreach ($i in 1..100000) { $i * 2 }
```

### Error Handling Anti-Patterns

#### [X] NEVER: Silent Failure Without Logging
```powershell
# WRONG - Errors disappear
try {
    Set-Mailbox -Identity $user -ProhibitSendQuota 10GB
} catch {
    # Nothing - error is lost
}

# RIGHT - Log and handle errors
try {
    Set-Mailbox -Identity $user -ProhibitSendQuota 10GB
    $result.Success = $true
} catch {
    $result.Success = $false
    $result.Error = $_.Exception.Message
    Write-Error "Failed to set quota for $user: $_"
}
```

#### [X] NEVER: Catch All Without Specificity
```powershell
# WRONG - Too broad, masks real issues
try {
    # Large block of code
} catch {
    Write-Status "Something failed" -Level Error
}

# RIGHT - Specific error handling
try {
    Connect-ExchangeOnline
} catch [Microsoft.Exchange.Management.RestApiClient.AuthenticationException] {
    Write-Error "Authentication failed. Check credentials."
} catch {
    Write-Error "Connection failed: $($_.Exception.Message)"
}
```

### Parameter Design Anti-Patterns

#### [X] NEVER: Validate Inside Function Instead of Parameter
```powershell
# WRONG - Manual validation in function body
function Set-UserEmail {
    param([string]$Email)
    
    if ([string]::IsNullOrEmpty($Email)) {
        throw "Email cannot be empty"
    }
    if ($Email -notmatch "@") {
        throw "Invalid email format"
    }
}

# RIGHT - Use parameter validation
function Set-UserEmail {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^@]+@[^@]+\.[^@]+$')]
        [string]$Email
    )
}
```

#### [X] NEVER: Positional Parameters for Complex Scripts
```powershell
# WRONG - Unclear what parameters mean
.\Script.ps1 "user@domain.com" "shared@domain.com" $true

# RIGHT - Named parameters
.\Script.ps1 -UserEmail "user@domain.com" -TargetMailbox "shared@domain.com" -SendAsAccess
```

### Documentation Anti-Patterns

#### [X] NEVER: Missing or Incomplete Help
```powershell
# WRONG - No help documentation
function Set-UserMailbox {
    param($User, $Quota)
    # Function code
}

# RIGHT - Complete help documentation
<#
.SYNOPSIS
    Sets mailbox quota for a user
.DESCRIPTION
    Configures the mailbox storage quota for specified user account.
    Requires Exchange Online administrator permissions.
.PARAMETER User
    User principal name (email address) of the mailbox
.PARAMETER Quota
    Quota size in GB (e.g., 50)
.EXAMPLE
    Set-UserMailbox -User "john@domain.com" -Quota 50
#>
function Set-UserMailbox {
    param(
        [Parameter(Mandatory = $true)]
        [string]$User,
        
        [Parameter(Mandatory = $true)]
        [int]$Quota
    )
    # Function code
}
```

#### [X] NEVER: Code Without Comments for Complex Logic
```powershell
# WRONG - No explanation of complex logic
$filtered = $users | Where-Object {
    $_.WhenCreated -gt (Get-Date).AddDays(-30) -and
    $_.Enabled -eq $true -and
    $_.Department -in $depts
}

# RIGHT - Explain the business logic
# Filter users created in last 30 days who are:
# - Enabled accounts
# - In approved departments (IT, Finance, HR)
$filtered = $users | Where-Object {
    $_.WhenCreated -gt (Get-Date).AddDays(-30) -and
    $_.Enabled -eq $true -and
    $_.Department -in $depts
}
```

### User Experience Anti-Patterns

#### [X] NEVER: No Progress Feedback for Long Operations
```powershell
# WRONG - User waits with no feedback
foreach ($user in $users) {
    Set-Mailbox -Identity $user -ProhibitSendQuota 10GB
}

# RIGHT - Show progress
$i = 0
foreach ($user in $users) {
    $i++
    Write-Progress -Activity "Updating mailboxes" -Status "Processing $user" -PercentComplete (($i / $users.Count) * 100)
    Set-Mailbox -Identity $user -ProhibitSendQuota 10GB
}
```

#### [X] NEVER: Unclear Error Messages
```powershell
# WRONG - Generic unhelpful message
catch {
    Write-Error "Failed"
}

# RIGHT - Specific actionable message
catch {
    Write-Error "Failed to set mailbox quota for $($user): $($_.Exception.Message). Verify user exists and you have Exchange admin permissions."
}
```

### Validation Anti-Patterns

#### [X] NEVER: Process First, Validate Later
```powershell
# WRONG - Start processing then discover invalid data
foreach ($email in $emails) {
    Set-Mailbox -Identity $email -ProhibitSendQuota 10GB  # Fails on invalid email
}

# RIGHT - Validate all inputs first
$validEmails = @()
foreach ($email in $emails) {
    $validation = Test-EmailComprehensive -EmailAddress $email
    if ($validation.OverallValid) {
        $validEmails += $email
    } else {
        Write-Warning "Skipping invalid email: $email"
    }
}

foreach ($email in $validEmails) {
    Set-Mailbox -Identity $email -ProhibitSendQuota 10GB
}
```

#### [X] NEVER: No Escape Hatch for Edge Cases
```powershell
# WRONG - Strict validation with no override
if ($email -notmatch "@company\.com$") {
    throw "Only company.com emails allowed"
}

# RIGHT - Provide skip validation option
if (-not $SkipDomainValidation) {
    if ($email -notmatch "@company\.com$") {
        throw "Only company.com emails allowed. Use -SkipDomainValidation to override."
    }
}
```

### File Operations Anti-Patterns

#### [X] NEVER: Overwrite Files Without Confirmation
```powershell
# WRONG - Silently overwrites existing file
$results | Export-Csv -Path "results.csv"

# RIGHT - Use timestamp or check existence
$outputPath = "results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation
Write-Status "Results exported to: $outputPath" -Level Info
```

#### [X] NEVER: Hardcode File Paths
```powershell
# WRONG - Hardcoded paths
$config = Get-Content "C:\Users\John\config.json"

# RIGHT - Use relative or environment paths
$config = Get-Content (Join-Path $PSScriptRoot "config.json")
# Or use user profile
$config = Get-Content (Join-Path $env:USERPROFILE "AppData\Local\MyApp\config.json")
```

---

## Quick Reference Card

### Essential Patterns At-A-Glance

#### Script Header Template
```powershell
#Requires -Version 5.1
#Requires -Module ExchangeOnlineManagement

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ParameterSetName='Array')]
    [string[]]$Items,
    
    [Parameter(Mandatory, ParameterSetName='CSV')]
    [ValidateScript({Test-Path $_})]
    [string]$CsvPath,
    
    [Parameter(Mandatory, ParameterSetName='Interactive')]
    [switch]$Interactive
)
```

#### Validation Function
```powershell
function Test-InputComprehensive {
    param([string]$Input, [switch]$SkipValidation)
    
    $result = [PSCustomObject]@{
        OverallValid = $false
        Issues = @()
    }
    
    # Validation logic here
    
    $result.OverallValid = (-not $result.Issues.Count)
    return $result
}
```

#### Connection Pattern
```powershell
function Initialize-ServiceConnection {
    if (-not (Get-ConnectionStatus)) {
        Write-Status "Connecting..." -Level Info
        Connect-Service
        Write-Status "Connected" -Level OK
    }
}
```

#### Processing Loop with Progress
```powershell
$i = 0
foreach ($item in $items) {
    $i++
    Write-Progress -Activity "Processing" -Status $item `
        -PercentComplete (($i/$items.Count)*100)
    
    try {
        # Process item
        Write-Status "  $item" -Level OK
    }
    catch {
        Write-Status "  $item - $_" -Level Error
    }
}
```

### Performance Quick Wins

| Instead of... | Use... | Why |
|--------------|--------|-----|
| `$array += $item` | `[List[object]]::new()` then `.Add()` | O(n) vs O(n²) |
| `Get-Content` | `[IO.File]::ReadAllText()` | Faster for large files |
| `Where-Object {$_.Prop}` | `Where-Object Prop` | Simpler, faster |
| `Get-ADUser -Filter *` | `Get-ADUser -Filter {prop -eq 'val'}` | Server-side filter |
| Pipeline for 10k+ items | `foreach` loop | Lower overhead |

### Security Checklist

- [ ] No hardcoded credentials/API keys
- [ ] Use Get-Credential or SecretManagement
- [ ] Validate all user inputs
- [ ] Use -WhatIf for dangerous operations
- [ ] Sanitize paths with Test-Path
- [ ] Never use Invoke-Expression with user input
- [ ] Request minimum required permissions
- [ ] Log authentication events

### Testing Checklist

- [ ] Pester tests for all public functions
- [ ] Code coverage > 80%
- [ ] PSScriptAnalyzer passes (no errors)
- [ ] Test with -WhatIf
- [ ] Test with invalid inputs
- [ ] Test error handling paths
- [ ] Test on target PowerShell version

### Documentation Checklist

- [ ] .SYNOPSIS - One line description
- [ ] .DESCRIPTION - Detailed explanation
- [ ] .PARAMETER for each parameter
- [ ] .EXAMPLE with 3+ examples
- [ ] .NOTES with version, author, requirements
- [ ] README.md with setup instructions
- [ ] Inline comments for complex logic

### Common Mistakes to Avoid

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| Connect inside loop | Slow, rate limits | Connect once at start |
| No progress feedback | Users don't know status | Use Write-Progress |
| Silent failures | Errors hidden | Log and re-throw |
| Hardcoded paths | Not portable | Use Join-Path, $env vars |
| No WhatIf support | Can't test safely | Add SupportsShouldProcess |
| Generic error messages | Hard to troubleshoot | Include context in errors |

### PowerShell Version Differences

| Feature | PS 5.1 | PS 7+ |
|---------|--------|-------|
| Platform | Windows only | Cross-platform |
| Ternary operator | No | Yes `$x ? $a : $b` |
| Null coalescing | No | Yes `$x ?? $default` |
| ForEach -Parallel | No | Yes |
| Pipeline chain | No | Yes `cmd1 && cmd2` |
| Speed | Baseline | 30-50% faster |

### Semantic Versioning Quick Guide

- **1.0.0 → 1.0.1** - Bug fix (patch)
- **1.0.1 → 1.1.0** - New feature (minor)
- **1.1.0 → 2.0.0** - Breaking change (major)

Breaking changes:
- Renamed parameters
- Changed return types
- Removed functionality
- Changed default behavior

---

## Glossary

### A

**Advanced Function** - A PowerShell function that uses `[CmdletBinding()]` attribute to enable cmdlet-like features (common parameters, ShouldProcess, etc.)

**Alias** - A shortcut name for a cmdlet or function (e.g., `dir` for `Get-ChildItem`)

**API** - Application Programming Interface; a way for programs to communicate with services

### B

**Backward Compatibility** - Ensuring new versions work with code written for old versions

**Binding** - The process of matching parameter values to parameter names

### C

**CmdletBinding** - Attribute that makes a function behave like a compiled cmdlet

**Code Coverage** - Percentage of code lines executed by tests

**Cross-Platform** - Code that works on Windows, Linux, and macOS

**Constrained Language Mode** - A restricted PowerShell language mode typically enforced via AppLocker or WDAC that limits dynamic language features (reflection, Add-Type, COM object creation) to reduce attack surface; scripts should detect `$ExecutionContext.SessionState.LanguageMode` and offer degraded functionality when in `ConstrainedLanguage`.

### D

**Dot Sourcing** - Running a script in the current scope using `. .\script.ps1`

**DSC** - Desired State Configuration; PowerShell framework for configuration management

### E

**Edition** - PowerShell comes in two editions: Desktop (5.1, Windows-only) and Core (7+, cross-platform)

**ErrorAction** - Common parameter controlling how errors are handled

### F

**ForEach-Object** - Cmdlet for processing pipeline items one at a time

**Function** - Reusable block of PowerShell code

### G

**Generic List** - .NET collection type: `[System.Collections.Generic.List[T]]`

### H

**HashTable** - Key-value pair data structure: `@{Key='Value'}`

### I

**Idempotent** - Operation that produces same result regardless of how many times it's run

**ISE** - Integrated Scripting Environment; legacy PowerShell editor (replaced by VS Code)

### M

**Manifest** - `.psd1` file containing module metadata

**Mock** - Test technique that replaces real commands with fake implementations

**Module** - Package of PowerShell functions, variables, and other resources

### N

**.NET** - Microsoft framework that PowerShell is built on

**NuGet** - Package management system used by PowerShell Gallery

### O

**Object** - Data structure with properties and methods

**OAuth** - Modern authentication protocol

### P

**Parameter Set** - Group of parameters that can be used together

**Pester** - PowerShell testing framework

**Pipeline** - Passing output of one command as input to another with `|`

**PSCustomObject** - Custom object type for returning structured data

**PSScriptAnalyzer** - Static code analysis tool for PowerShell

### R

**Remoting** - Running PowerShell commands on remote computers

**REST API** - Web service architecture style

### S

**Script Block** - Code wrapped in `{ }` that can be executed later

**SecretManagement** - PowerShell module for secure credential storage

**Semantic Versioning** - Version numbering scheme: MAJOR.MINOR.PATCH

**ShouldProcess** - Pattern for implementing -WhatIf and -Confirm support

**Splatting** - Passing parameters as a hashtable: `@Parameters`

### T

**Ternary Operator** - Compact if-else: `$condition ? $true : $false` (PS7+)

**Type Accelerator** - Shortcut for .NET types (e.g., `[string]` instead of `[System.String]`)

### V

**ValidateScript** - Parameter attribute that runs code to validate input

**Verbose** - Common parameter that shows detailed operational messages

**VSCode** - Visual Studio Code; recommended PowerShell editor

### W

**WhatIf** - Parameter that shows what would happen without making changes

**Windows PowerShell** - PowerShell 5.1, Windows-only version

### Other

**#Requires** - Statement declaring script requirements (version, modules, etc.)

**$PSBoundParameters** - Automatic variable containing parameters passed to function

**$PSCmdlet** - Automatic variable accessing cmdlet functionality in advanced functions

**$PSItem / $_** - Current pipeline object

---

## Change Log

This section versions the guide itself. Semantic versioning is applied to structural and substantive documentation changes.

### v2.1.0 (2025-11-19)
Minor update focusing on logging modernization, security hardening additions, and configuration guidance.
- Added: Logging & Status Output section with `Write-Status` function (structured information stream)
- Added: PowerShell 7+ clarification that `Write-Host` wraps `Write-Information`
- Added: Modern connection guidance (implicit context reuse, explicit connect fallback criteria)
- Added: DSC maintenance warning plus updated 2025 banner (v1/v2 support, `dsc` CLI, cross-platform note, link to documentation)
- Added: Endpoint Hardening subsection (JEA, WDAC, script block logging, AMSI)
- Added: OS Detection note clarifying continued support of `$Is*` variables alongside static `OperatingSystem` helpers
- Improved: Replaced all `Write-Host` examples with `Write-Status` for consistency and testability
- Improved: Analyzer settings comment updated to phase out `PSAvoidUsingWriteHost` exclusion after migration
- Clarified: Logging section now explicitly notes information stream 6> and safe colored `Write-Host` usage (wrapper over `Write-Information`).
- Expanded: Endpoint Hardening with JEA + WDAC vs Constrained Language comparison subsection.
- Clarified: Cross-platform guidance explicitly states `$IsWindows/$IsLinux/$IsMacOS` are not deprecated; static helpers are optional feature checks.
- Updated: DSC banner wording (added v1/v2, explicit Windows support, cross-platform descriptor, `dsc` CLI details)
- Removed: Redundant older DSC update line after adding banner to avoid duplication.

### v2.0.0 (2025-11-19)
Major update promoting configuration management and advanced testing/security topics.
- Added: Dedicated Configuration Management category and relocated/refactored DSC section.
- Added: Mutation Testing, Performance & Load Testing, Code Signing & Execution Policy, Constrained Language Mode sections.
- Added: PowerShell 7.4+ Changes & Deprecations subsection in Cross-Platform.
- Added: Glossary term for Constrained Language Mode.
- Improved: Unicode replacements with ASCII-safe `[OK]` and `[ERROR]` markers.
- Improved: Cross-platform deprecation guidance for OS detection.

### v1.1.0 (2025-11-10)
Incremental improvements prior to structural reorganization.
- Added: Module Development section with publishing guidance.
- Added: Quick Reference Card and expanded Glossary.
- Added: Code Coverage & Analysis section (JaCoCo format, CI examples).
- Improved: Performance Optimization consolidation.
- Improved: Version Control examples and semantic versioning walkthrough.

### v1.0.0 (2025-10-20)
Initial release of the Best Practices Guide.
- Core sections: Architecture, Validation, Authentication, UX, Documentation Standards.
- Included: Testing & Quality Assurance, Performance Optimization (initial draft), Security Considerations.
- Provided: Example script, anti-pattern list, baseline glossary.

### Versioning Policy
- **MAJOR**: New categories, structural reorganization, or conceptual frameworks added/changed.
- **MINOR**: New sections within existing categories or significant content expansion without restructure.
- **PATCH**: Typos, small clarifications, formatting fixes.

To contribute: Propose changes referencing current version; upon merge, update Change Log with concise bullet points describing impact.

---

## Appendix A: AI Development Instructions

### How to Use This Guide with AI Assistants

This section provides templates and instructions for effectively communicating these best practices to AI assistants when developing PowerShell scripts.

### Initial Project Prompt Template

```
I need to create a PowerShell script with the following requirements:

**Core Functionality**: [Describe what the script should do]

**Input Requirements**: 
- Support multiple input methods (array parameter, CSV file, interactive mode)
- Validate all inputs comprehensively before processing
- [Add specific input requirements for your use case]

**Authentication/Services**:
- [List required services: Microsoft Graph, Exchange Online, Azure REST APIs, etc.]
- Use single connection pattern - establish connections once at start
- [Add specific authentication requirements]

**Architecture Requirements**:
- Follow PowerShell best practices with CmdletBinding and SupportsShouldProcess
- Implement comprehensive parameter validation with parameter sets
- Include extensive help documentation with multiple examples
- Provide clear progress feedback and color-coded status messages
- Export results to CSV with detailed success/failure reporting

**Validation Framework**:
- Multi-layer validation: format, business logic, system existence
- Configurable business rules (domain restrictions, policy compliance, etc.)
- Skip validation switches for edge cases
- Comprehensive validation result objects

**Error Handling**:
- Graceful error handling with detailed user messages
- Continue processing after individual failures in batch operations
- Collect all results for final summary reporting

**User Experience**:
- Visual progress indicators for long operations
- Color-coded feedback (Green for success, Red for errors, Yellow for warnings)
- Clear success/failure summary at completion
- Verbose logging option for troubleshooting

Please follow the development approach and patterns established in our PowerShell Development Best Practices guide.
```

### Development Phase Instructions

#### Phase 1: Architecture & Parameters
```
Create the script structure following our established pattern:
1. Comprehensive help documentation with .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE, .NOTES
2. #Requires statements for all modules
3. Parameter sets for Array, CSV, and Interactive modes
4. Include validation attributes and help messages
5. Add standard switches: SkipDomainValidation, SkipMailboxValidation, WhatIf, Confirm
6. Use the parameter design patterns from our best practices guide
```

#### Phase 2: Validation Framework
```
Implement the comprehensive validation framework:
1. Create Test-[Entity]Comprehensive functions using our template
2. Multi-layer validation: format -> domain -> system existence
3. Return validation result objects with OverallValid and Issues properties
4. Support skip validation switches for edge cases
5. Provide detailed validation feedback to users
```

#### Phase 3: Connection Management
```
Implement the single connection pattern:
1. Create Initialize-[Service]Connection functions
2. Check for existing connections before attempting to connect
3. Establish all connections once at script startup
4. Provide clear visual feedback about connection status
5. Handle connection failures gracefully with helpful error messages
```

#### Phase 4: Core Functionality & Error Handling
```
Implement the main processing logic:
1. Use try-catch blocks with detailed error handling
2. Create result objects for each operation with Success, Message, Timestamp
3. Continue processing after individual failures
4. Provide progress indicators for batch operations
5. Implement SupportsShouldProcess for WhatIf testing
```

#### Phase 5: User Experience & Reporting
```
Enhance the user experience:
1. Add color-coded status messages ([OK] Green for success, [ERROR] Red for errors)
2. Show progress for batch operations
3. Provide summary statistics (success/failure counts)
4. Export detailed results to timestamped CSV files
5. Include verbose logging for troubleshooting
```

### Quality Assurance Checklist for AI

Use this checklist to ensure the AI delivers complete, high-quality scripts:

```
Please verify the script includes:

**Documentation & Help**:
- [ ] Complete .SYNOPSIS, .DESCRIPTION with clear purpose
- [ ] All parameters documented with .PARAMETER
- [ ] Multiple .EXAMPLE sections with real-world scenarios
- [ ] .NOTES section with author, version, requirements, setup instructions
- [ ] #Requires statements for all modules

**Parameter Design**:
- [ ] Parameter sets for different input methods (Array, CSV, Interactive)
- [ ] Proper validation attributes ([ValidateNotNullOrEmpty], [ValidateScript])
- [ ] Skip validation switches for edge cases
- [ ] SupportsShouldProcess for WhatIf functionality

**Validation Framework**:
- [ ] Comprehensive validation functions returning result objects
- [ ] Multi-layer validation (format, domain, system)
- [ ] Clear validation error messages
- [ ] Support for validation overrides

**Connection Management**:
- [ ] Single connection pattern with Initialize-*Connection functions
- [ ] Connection status checking before operations
- [ ] Clear feedback about connection establishment
- [ ] Graceful handling of connection failures

**Error Handling & UX**:
- [ ] Try-catch blocks around all external operations
- [ ] Color-coded status messages
- [ ] Progress indicators for batch operations
- [ ] Detailed success/failure summary
- [ ] CSV export of results

**Testing Support**:
- [ ] WhatIf parameter support implemented
- [ ] Verbose logging available
- [ ] Examples for all major use cases
```

### Iterative Development Instructions

```
For script improvements and debugging:

1. **Error Analysis**: When encountering errors, analyze the root cause and implement proper error handling rather than just catching and continuing

2. **User Feedback Integration**: 
   - Add skip validation parameters when users encounter edge cases
   - Improve error messages to be more specific about what failed
   - Enhance progress feedback for operations that take longer than expected

3. **Performance Optimization**:
   - Ensure connections are established once and reused
   - Add progress indicators for operations with multiple items
   - Optimize validation to avoid redundant checks

4. **Documentation Updates**:
   - Update examples when new parameters are added
   - Enhance troubleshooting sections based on actual issues encountered
   - Keep README documentation synchronized with script capabilities
```

### Common AI Development Patterns

#### Requesting Validation Improvements
```
The script is failing validation for [specific scenario]. Please:
1. Analyze the validation logic in Test-[Entity]Comprehensive function
2. Add a SkipValidation parameter if this is an edge case
3. Improve error messages to be more specific about what failed
4. Update the help documentation with troubleshooting guidance for this scenario
```

#### Requesting Connection Fixes
```
Users are being prompted to authenticate multiple times. Please:
1. Move connection logic to script startup using Initialize-*Connection pattern
2. Remove connection checks from individual operation functions
3. Add connection status verification at script beginning
4. Update README with information about single authentication
```

#### Requesting User Experience Improvements
```
Enhance the user experience by:
1. Adding color-coded progress messages ([OK] [ERROR] formatting)
2. Implementing progress indicators for batch operations
3. Providing clear summary statistics at completion
4. Adding verbose logging for troubleshooting
5. Ensuring all user feedback follows our established patterns
```

### Template for Complex Requirements

```
I need to create a PowerShell script that [core functionality] with these specific requirements:

**Follow Our Established Patterns**:
- Use the script structure template from our PowerShell Development Best Practices
- Implement the validation framework pattern with comprehensive result objects
- Use the single connection management pattern for all external services
- Follow our user experience standards with color-coded feedback

**Specific Technical Requirements**:
[List specific technical needs]

**Integration Requirements**:
[List required services and APIs]

**Custom Validation Rules**:
[List specific validation requirements]

**User Experience Requirements**:
[List specific UX needs]

**Note**: Use ASCII-safe characters only ([OK], [ERROR], [INFO] instead of Unicode symbols) for maximum compatibility.

Please develop this iteratively, starting with the basic structure and building up the functionality while maintaining our established quality standards.
```
