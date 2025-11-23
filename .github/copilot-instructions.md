# GitHub Copilot Instructions for PowerShell Repository

## Core Development Principles

**ALL scripts in this repository MUST follow these standards:**

1. **PowerShell Development Best Practices**: Follow all guidelines in `PowerShell-Development-Best-Practices-v2.1.0.md`
2. **Companion Documentation**: Create a markdown file for every PowerShell script
3. **Code Quality**: Use `[CmdletBinding()]`, proper error handling, and semantic versioning
4. **Testing**: Include Pester tests for validation functions and core logic

## Documentation Standards

### Script Documentation Requirements

**ALWAYS create a companion markdown file** for every PowerShell script in this repository.

#### Naming Convention
- For script: `ScriptName.ps1`
- Create documentation: `ScriptName.md`
- Place in the same directory as the script

#### Markdown Documentation Structure

Each script documentation file must include:

1. **Title & Overview**
   - Script name as H1 header
   - Brief one-line description
   - Purpose and use cases

2. **Synopsis**
   - What the script does
   - Key capabilities

3. **Requirements**
   - PowerShell version compatibility
   - Required modules
   - Required permissions
   - Platform compatibility (Windows/Linux/macOS)

4. **Parameters**
   - Table format with columns: Parameter | Type | Required | Default | Description
   - Clear description of each parameter

5. **Examples**
   - At least 3 real-world usage examples
   - Include expected output or behavior
   - Show different parameter combinations

6. **Setup Instructions**
   - Step-by-step installation/configuration
   - Prerequisites
   - Initial setup commands

7. **Output**
   - Description of what the script returns
   - Output format (object properties, files generated, etc.)
   - Example output

8. **Error Handling**
   - Common errors and solutions
   - Troubleshooting tips

9. **Notes**
   - Important limitations or considerations
   - Performance notes for large datasets
   - Security considerations

10. **Version History**
    - Semantic versioning
    - Change log with dates

11. **Author & License**
    - Author information
    - License reference

#### Example Documentation Template

```markdown
# ScriptName

Brief one-line description of what the script does.

## Synopsis

Detailed explanation of the script's purpose, what problems it solves, and key capabilities.

## Requirements

- **PowerShell Version**: 5.1 or later (7+ recommended)
- **Modules**: 
  - `ModuleName` (version X.X+)
- **Permissions**: 
  - List required permissions
- **Platform**: Windows, Linux, macOS (specify compatibility)

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| ParameterName | String | Yes | N/A | Description of parameter |
| OptionalParam | Int | No | 50 | Description with default |

## Examples

### Example 1: Basic Usage
```powershell
.\ScriptName.ps1 -ParameterName "value"
```

Description of what this does and expected output.

### Example 2: Advanced Usage
```powershell
.\ScriptName.ps1 -ParameterName "value" -OptionalParam 100
```

Description of this scenario.

### Example 3: Pipeline Usage
```powershell
Get-Something | .\ScriptName.ps1
```

Description of pipeline scenario.

## Setup Instructions

1. Install required modules:
   ```powershell
   Install-Module ModuleName -Force
   ```

2. Configure permissions/authentication

3. Run the script

## Output

The script returns a PSCustomObject with the following properties:

- **PropertyName**: Description
- **AnotherProperty**: Description

Example output:
```
PropertyName : Value
AnotherProperty : Value
```

## Error Handling

### Common Errors

**Error: "Module not found"**
- Solution: Install the required module using `Install-Module`

**Error: "Access denied"**
- Solution: Ensure you have appropriate permissions

## Troubleshooting

- Issue description and resolution
- Performance tips for large datasets

## Notes

- Important limitations
- Security considerations
- Performance characteristics
- Cross-platform considerations

## Version History

- **1.0.0** (YYYY-MM-DD) - Initial release
- **1.1.0** (YYYY-MM-DD) - Added feature X

## Author

Author Name

## License

See [LICENSE](LICENSE) file in repository root.
```

## Development Guidelines

### When Creating New Scripts

**MANDATORY REQUIREMENTS:**

1. **Follow PowerShell-Development-Best-Practices-v2.1.0.md**:
   - Use `[CmdletBinding()]` with proper parameter sets
   - Implement comprehensive comment-based help
   - Add `#Requires` directives for modules and versions
   - Include proper error handling with try-catch blocks
   - Use `Write-Status` or `Write-Information` for output (not `Write-Host`)
   - Support `-WhatIf` and `-Confirm` when making changes
   - Use semantic versioning (MAJOR.MINOR.PATCH)

2. **Create companion documentation**: Generate the `.md` file first or immediately after the script

3. **Code structure**:
   - Organize into regions: Helper Functions, Main Execution
   - Use approved PowerShell verbs (`Get-Verb`)
   - Implement parameter validation attributes
   - Add verbose logging with `Write-Verbose`

4. **Include examples**: Real, tested examples that users can copy-paste

5. **Error handling**: Comprehensive try-catch with meaningful error messages

6. **Performance**: Use efficient patterns (Generic Lists, filter at source, avoid `+=` with arrays)

### When Modifying Existing Scripts

1. **Update the markdown file** with any parameter changes
2. **Add to version history** in both script and documentation
3. **Review examples** to ensure they still work
4. **Update requirements** if new modules or permissions are needed

## Code Quality Standards

### Required Elements for Every Script

- **Comment-based help**: Complete `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`
- **Version information**: Include version number and history in help block
- **Requirements directive**: `#Requires -Version 5.1` and module dependencies
- **CmdletBinding**: `[CmdletBinding(SupportsShouldProcess)]` for functions that make changes
- **Parameter validation**: Use `[ValidateNotNullOrEmpty()]`, `[ValidateScript()]`, etc.
- **Error handling**: Try-catch blocks with meaningful error messages
- **Verbose logging**: `Write-Verbose` for debugging information
- **Status output**: Use `Write-Status` function pattern from best practices
- **Semantic versioning**: MAJOR.MINOR.PATCH format
- **Approved verbs**: Check with `Get-Verb` - use standard PowerShell verbs
- **Pester tests**: Create `.Tests.ps1` files for validation and core functions

### Performance Patterns to Follow

- Use `[System.Collections.Generic.List[T]]` instead of `@()` with `+=`
- Filter at the source (server-side) not client-side
- Use `foreach` loops instead of pipeline for large datasets
- Cache expensive operations (API calls, remote queries)
- Implement progress bars for long-running operations
- Handle errors gracefully without stopping batch operations

### Security Requirements

- **NEVER** hardcode credentials, API keys, or secrets
- Use `Get-Secret`, `Get-Credential`, or secure vaults
- Validate all user inputs before processing
- Use parameter validation attributes
- Implement proper error messages without exposing sensitive data

## Additional Resources

- Repository best practices: `PowerShell-Development-Best-Practices-v2.1.0.md`
- PowerShell approved verbs: Run `Get-Verb` in PowerShell
- Comment-based help: https://learn.microsoft.com/powershell/scripting/developer/help/
