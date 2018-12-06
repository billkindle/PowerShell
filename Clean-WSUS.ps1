# Performs a cleanup of WSUS. 
# Outputs the results to a text file. 
# Adapted and tested by BigTeddy 
# https://gallery.technet.microsoft.com/scriptcenter/WSUS-Clean-Powershell-102f8fc6
# 3 July 2012 
 
$outFilePath = 'E:\Logs\wsusClean.txt' 
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null 
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer(); 
$cleanupScope = new-object Microsoft.UpdateServices.Administration.CleanupScope; 
$cleanupScope.DeclineSupersededUpdates = $true        
$cleanupScope.DeclineExpiredUpdates         = $true 
$cleanupScope.CleanupObsoleteUpdates     = $true 
$cleanupScope.CompressUpdates                  = $true 
#$cleanupScope.CleanupObsoleteComputers = $true 
$cleanupScope.CleanupUnneededContentFiles = $true 
$cleanupManager = $wsus.GetCleanupManager(); 
$cleanupManager.PerformCleanup($cleanupScope); 