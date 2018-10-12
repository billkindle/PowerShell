<#
    Modified By: Bill Kindle
    Date:       10/12/18

    *Special thanks to the fine folks over on the #PowerShell slack channel! 
    You guys/gals rock! @timcurwick you are awesome.*

    Purpose:

    This script can be used to recover your forgotten RDCman passwords. 
    Please note, that this tool will only work in the user context for which
    the RDG file was created. You will be unsuccessful in trying to copy the
    file from another system and running this script to recover passwords. 

    Be sure to use a reliable password manager like KeePass if you are cheap. 

    This worked for a coworker of mine and I also tested it myself. It works.

#>

# Change the path to match where your remote desktop group file is located.
$RDGPath = Read-Host -Prompt "Please enter the full path to your RDG file including the filename.rdg"

$RDGFile = $RDGPath

# .NET assembly used here to load the RDCman exe
[void][System.Reflection.Assembly]::LoadFrom( 'C:\Program Files (x86)\Microsoft\Remote Desktop Connection Manager\RDCMan.exe' )

# this is just a variable. You can name $X to $whatever, it's just a variable name. 
$X = [xml]( Get-Content -Path $RDGFile -Raw )

# If you changed the var above, be sure to change it here as well. This is where the magic happens!
# This will output results directly to the console.
$X.SelectNodes( '//password' ).'#text' | ForEach-Object { [RDCMan.Encryption]::DecryptString( $_, [RdcMan.EncryptionSettings]@{} ) }