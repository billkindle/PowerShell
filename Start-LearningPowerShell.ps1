   #Learn PowerShell every day by reading random help files.
   Get-Command -Module Microsoft*,Cim*,PS*,ISE | Get-Random | Get-Help -ShowWindow
   sleep 3
   Get-Random -Input (Get-Help about*) | Get-Help -ShowWindow
   