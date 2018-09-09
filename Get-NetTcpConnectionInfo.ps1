# Code sample obtained from Mike F. Robbins
# https://mikefrobbins.com/2018/07/19/use-powershell-to-determine-what-your-system-is-talking-to/

Get-NetTCPConnection -State Established | 
    Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State, 
        @{name='Process';expression={(Get-Process -Id $_.OwningProcess).Name}}, CreationTime | 
    Format-Table -AutoSize